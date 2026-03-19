#!/bin/bash

if [[ -z "$SNAPSHOT_ID" ]] ; then
  echo "ERROR: SNAPSHOT_ID not set in $0."
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

if [[ "${worker_num}" -gt 253 ]] ; then
  echo "Argument Error: worker number must be between 1 and 253."
  exit
fi

butane="worker${worker_num}.yaml"
ignition="worker${worker_num}.json"
sed -e "s/{JOIN_COMMAND}/${join_cmd}/g" \
    ../worker.yaml.tmpl \
    > "$butane"

../../transpile.sh "$butane"

hcloud server create \
  --name "worker-${worker_num}" \
  --label k_type=demo-worker \
  --label "k_worker_num=${worker_num}" \
  --location fsn1 \
  --type cx33 \
  --image "${SNAPSHOT_ID}" \
  --user-data-from-file "${ignition}"

w_id="$(hcloud server list --selector  "k_worker_num=${worker_num}" --output json | jq -r '.[].id')"

echo "Worker $worker_num ready."

echo "$w_id" >>IDs
