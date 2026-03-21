#!/bin/bash

scriptdir="$(cd "$(dirname $0)"; pwd)"

echo
echo -n "Waiting for kubeconfig to become available..."
while ! "${scriptdir}/coressh.sh" test -f .kube/config; do
  echo -n "."
  sleep 1
done
echo
echo " --> done. Node / pod status:"
"${scriptdir}/coressh.sh" cat .kube/config \
    | sed 's,server:.*,server: https://localhost:6443,' \
    >kubeconfig
kubectl --kubeconfig kubeconfig get nodes -o wide
kubectl --kubeconfig kubeconfig get pods -n kube-system

echo
echo "Creating CNI."
kubectl --kubeconfig kubeconfig apply \
        -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/calico.yaml

echo
echo -n "Waiting for control plane node to become ready..."
while ! kubectl --kubeconfig kubeconfig get nodes | grep controlplane | grep -qw Ready; do
  echo -n "."
  sleep 1
done
echo
echo " --> done. Worker node command:"
join_cmd="$("${scriptdir}/coressh.sh" kubeadm token create --print-join-command)"
echo "../worker.sh '${join_cmd}' <num>"
