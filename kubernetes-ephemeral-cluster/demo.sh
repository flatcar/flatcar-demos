#!/bin/bash

kubernetes_version=v1.35.2
kubernetes_major="${kubernetes_version%\.*}"

set -euo pipefail
scriptdir="$(cd "$(dirname "$0")"; pwd)"

[[ -f "arch.env" ]] && source arch.env
[[ -f "join.env" ]] && source join.env

function _fetch() {
  local arch="$1"

  echo "### Downloading the latest Flatcar Alpha image for '$arch'",

  rm -f flatcar_production_qemu_uefi{.sh,_efi_code.qcow2,_efi_vars.qcow2,_image.img}
  curl --remote-name-all --parallel -L https://alpha.release.flatcar-linux.net/"$arch"-usr/current/flatcar_production_qemu_uefi{.sh,_efi_code.qcow2,_efi_vars.qcow2,_image.img}

  chmod 755 flatcar_production_qemu_uefi.sh

  echo -e "arch=\"$arch\"">arch.env
}
# --

function _check_image() {
  if [[ ! -f flatcar_production_qemu_uefi.sh ]] \
     || [[ ! -f flatcar_production_qemu_uefi_efi_code.qcow2 ]] \
     || [[ ! -f flatcar_production_qemu_uefi_efi_vars.qcow2 ]] \
     || [[ ! -f flatcar_production_qemu_uefi_image.img ]] ; then
      echo "ERROR: QEmu image is missing or incomplete; please run '$0 fetch' to download".
      exit 1
  fi
}
# --

function _arch_to_sysext_arch() {
  case "$1" in
    amd64) echo "x86-64";;
    *) echo "$1";;
  esac
}
# --

function _transpile() {
  local yaml="$1"
  local json="${yaml/.yaml/.json}"

  echo "### Transpiling '$yaml'"
  cat "$yaml" \
    | docker run --rm \
      -v "$(pwd)":/files \
      -i quay.io/coreos/butane:latest \
      --files-dir /files  \
      >"${json}"

  echo "${1} ==> ${1/.yaml/.json}"
}
# --

function _spawn_control() {
  _check_image

  rm -f join.env kubeconfig

  sed -e "s/{ARCH}/"$(_arch_to_sysext_arch "${arch}")"/g" \
      -e "s/{K8S_V}/${kubernetes_version}/g" \
      -e "s/{K8S_M}/${kubernetes_major}/g" \
      "${scriptdir}/control.yaml.tmpl" \
    > control.yaml
  _transpile control.yaml

  ./flatcar_production_qemu_uefi.sh -i control.json -f 6443:6443 -p 2001 \
    -nographic -snapshot  -device e1000,netdev=n1,mac=52:54:00:12:34:00 \
    -netdev socket,id=n1,mcast=230.0.0.1:1234   

  rm -f join.env kubeconfig
}
# --

function _ssh() {
  local node="$1"
  shift

  local port=2001
  if [[ "$node" == "worker" ]] ; then
    port="$(_worker_ssh_port "$1")"
    shift
  fi

  ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" core@localhost -p "$port" "${@}"
}
# --

function _init_control() {
  echo "### Initialising the control plane node"
  echo
  echo -n "Waiting for kubeconfig to become available..."
  while ! _ssh "control" test -f .kube/config; do
    echo -n "."
    sleep 1
  done
  echo
  echo -e "\n --> done."
  _ssh "control" cat .kube/config \
    | sed 's,server:.*,server: https://localhost:6443,' \
    >kubeconfig

  echo
  echo "Installing CNI."
  kubectl --kubeconfig kubeconfig apply \
        -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/calico.yaml

  echo
  echo -n "Waiting for the CNI to finish installation and for the control plane node to become ready..."
  while ! kubectl --kubeconfig kubeconfig get nodes | grep controlplane | grep -qw Ready; do
    echo -n "."
    sleep 1
  done
  echo -e "\n --> done."

  local join_cmd
  join_cmd="$(_ssh "control" kubeadm token create --print-join-command)"

  echo "join_cmd=\"${join_cmd}\"">join.env

  echo
  echo "### Initialisation complete."
  echo "    Kubeconfig available."
  echo "    Worker join command available."
  echo
}
# --

function _worker_ssh_port() {
  local num="$1"
  local ipnum="$((num + 1))"

  printf "2%3.3d" "$ipnum"
}
# --

function _spawn_worker() {
  local num="$1"

  local ipnum="$((num + 1))" # worker IPs start from .2, control plane is .1
  local butane="worker${num}.yaml"

  if [[ -z "${join_cmd:-}" ]] ; then
    echo "ERROR: worker join command not found or join.env missing."
    echo "Did you start the control plane and ran init?"
    exit 1
  fi

  sed -e "s/{JOIN_COMMAND}/${join_cmd}/g" \
      -e "s/{WORKER_NUM}/${num}/g" \
      -e "s/{WORKER_IPNUM}/${ipnum}/g" \
      -e "s/{ARCH}/"$(_arch_to_sysext_arch "${arch}")"/g" \
      -e "s/{K8S_V}/${kubernetes_version}/g" \
      -e "s/{K8S_M}/${kubernetes_major}/g" \
      "${scriptdir}"/worker.yaml.tmpl \
    > "$butane"

  _transpile "$butane"
  local ignition="${butane/.yaml/.json}"

  local mac="$(printf "52:54:00:12:34:%2.2x" "$ipnum")"
  local ssh="$(_worker_ssh_port "$num")"

  ./flatcar_production_qemu_uefi.sh -i "${ignition}" \
     -p "$ssh" \
     -nographic -snapshot  \
     -device e1000,netdev=n1,mac="$mac" \
     -netdev socket,id=n1,mcast=230.0.0.1:1234
}
# --

function _teardown() {
  echo "### Teardown."
  echo -n "    Stopping workers: "
  local w
  for w in worker*.yaml; do
    [[ -e "$w" ]] || break
    local n="$(echo "$w"|sed 's/worker\([0-9]\+\).yaml/\1/')"
    echo -n "$n "
    _ssh "worker" "$n" "sudo poweroff" || true
  done
  echo " Done."

  echo -n "    Stopping control plane: "
  _ssh "control" "sudo poweroff" || true
  echo "  Done."
}
# --

function _help() {
  echo "Usage:"
  echo "$0 [--arch <amd64|arm64>] <fetch|control|init|worker|kc|ssh>"
  echo "             $0 fetch        - fetch the latest Flatcar QEmu release (Alpha channel)."
  echo "             $0 control      - start a Kubernetes control plane node."
  echo "             $0 init         - initialise control plane - install a CNI, fetch kubeconfig and worker join command."
  echo "             $0 worker <num> - start worker node #num."
  echo "                               <num> must be a number between 1 and 253."
  echo "             $0 ssh <control|worker <num>>
                                     - SSH into the control plane, or into worker <num>."
  echo "                               The respective node must be up and running."
  echo "    --arch <amd64|arm64>     - Force VM architecture. Defaults to amd64."
}
# --

#
# Command line arguments
#
arch="amd64"
cmd=""
arg=""

while [[ $# -gt 0 ]] ; do
  case "$1" in
    --arch)
      shift
      case "$1" in
        amd64|arm64) true;;
        *) echo "ERROR: unknown architecture '${1:-}'"
           _help
           exit 1
           ;;
      esac
      arch="$1"
      ;;
    *)
      if [[ -n "$cmd" ]] ; then
        echo "ERROR: spurious positional argument '$1' after '$cmd'"
        _help
        exit 1;
      fi
      cmd="$1"
      case "$cmd" in
        fetch|control|init|teardown) true;;
        worker) arg="$2"; shift;;
        ssh) shift; arg="$@"; break;;
        kc) shift; arg="$@"; break;;
        *) echo "ERROR: unknown command '$cmd'"
           _help
           exit 1;;
      esac
      ;;
  esac
  shift
done

#
# Command dispatcher
#

case "$cmd" in
  fetch)   _fetch "$arch";;
  control) _spawn_control;;
  init) _init_control;;
  worker)  _spawn_worker "$arg";;
  kc) echo "Running kubectl --kubeconfig ./kubeconfig ${arg}"
      echo "----------------------------------------------------------------"
      kubectl --kubeconfig ./kubeconfig ${arg};;
  ssh) _ssh ${arg};;
  teardown) _teardown;;
  *) _help; exit;;
esac
