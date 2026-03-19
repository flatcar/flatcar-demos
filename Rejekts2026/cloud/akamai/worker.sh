#!/bin/bash

if [[ -z "$IMAGE_ID" ]] ; then
  echo "ERROR: IMAGE_ID not set in $0."
  echo "Please consult Readme.md on how to create a snapshot".
  exit
fi

if [[ "$#" -ne 2 ]] ; then
  echo "Usage: $0 <join-command> <worker-number>"
  echo "           join-command:  Control plane join command, including token."
  echo "                          Generate on control plane node by issuing"
  echo "                          'kubeadm token create --print-join-command'"
  echo "           worker number: Numerical value denoting the number / ID of the"
  echo "                          worker node to spawn."
  echo
  exit
fi

join_cmd="$1"
worker_num="$2"

butane="worker${worker_num}.yaml"
ignition="worker${worker_num}.json"
sed -e "s/{JOIN_COMMAND}/${join_cmd}/g" \
    ../worker.yaml.tmpl \
    > "$butane"

../../transpile.sh "$butane"

./create-linode.sh "${IMAGE_ID}" "k8s-demo-worker-${worker_num}" "${ignition}"

w_id="$(linode-cli linodes list --json | jq -r ".[]|select(.label == \"k8s-demo-worker-${worker_num}\") | .id")"
echo "Worker $worker_num ready."

echo "$w_id" >>IDs
