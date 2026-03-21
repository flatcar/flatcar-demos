#!/bin/bash

if [[ "$#" -ne 2 ]] ; then
  echo "Usage: $0 <join-command> <worker-number>"
  echo "           join-command:  Control plane join command, including token."
  echo                            "Generate on control plane node by issuing"
  echo "                          'kubeadm token create --print-join-command'"
  echo "           worker number: Numerical value between 1 and 253 denoting the number / ID of the"
  echo "                          worker node to spawn."
  echo
  exit
fi

join_cmd="$1"
worker_num="$2"
worker_ipnum="$((worker_num + 1))" # worker IPs start from .2

if [[ "${worker_num}" -gt 253 ]] ; then
  echo "Argument Error: worker number must be between 1 and 253."
  exit
fi

butane="worker${worker_num}.yaml"
ignition="worker${worker_num}.json"
sed -e "s/{JOIN_COMMAND}/${join_cmd}/g" \
    -e "s/{WORKER_NUM}/${worker_num}/g" \
    -e "s/{WORKER_IPNUM}/${worker_ipnum}/g" \
    ../worker.yaml.tmpl \
    > "$butane"

../../transpile.sh "$butane"

mac="$(printf "52:54:00:12:34:%2.2x" "$worker_ipnum")"
ssh="$(printf "2%3.3d" "$worker_ipnum")"

echo "Starting worker #${worker_num} w/ ssh port '${ssh}', MAC '${mac}'"
sleep 1
./flatcar_production_qemu_uefi.sh -i "${ignition}" \
                                  -p "$ssh" \
                                  -nographic -snapshot  \
                                	-device e1000,netdev=n1,mac="$mac" \
                                  -netdev socket,id=n1,mcast=230.0.0.1:1234
