#!/bin/bash

set -euo pipefail

ip="${1:-}"
if [[ -z "$ip" ]]; then
  echo "Usage: $0 <ip>"
  exit
fi

ssh="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@${ip}"

echo
echo -n "Waiting for kubeconfig to become available..."
while ! ${ssh} test -f .kube/config; do
  echo -n "."
  sleep 1
done
echo
echo " --> done. Node / pod status:"
${ssh} cat .kube/config >kubeconfig
kubectl --kubeconfig kubeconfig get nodes -o wide
kubectl --kubeconfig kubeconfig get pods -n kube-system

echo
echo "Creating CNI."
kubectl --kubeconfig kubeconfig apply \
        -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/calico.yaml

echo
echo -n "Waiting for control plane node to become ready..."
while ! kubectl --kubeconfig kubeconfig get nodes | grep control-plane | grep -qw Ready; do
  echo -n "."
  sleep 1
done
echo
echo " --> done"
