#!/bin/bash

set -euo pipefail

SNAPSHOT_ID=""

if [[ -z "$SNAPSHOT_ID" ]] ; then
  echo "ERROR: SNAPSHOT_ID not set in $0."
  echo "Please consult Readme.md on how to create a snapshot".
  exit
fi

ssh_key=""
for pubkey in id_ed25519.pub id_rsa.pub id_ecdsa.pub; do
  k=~/.ssh/"$pubkey"
  if [[ -f "$k" ]] ; then
    echo "Using public SSH key '$k'"
    ssh_key="$(cat "$k")"
    break
  fi
done

if [[ -z "$ssh_key" ]] ; then
  echo "ERROR: did not find a usable ssh public key in ~/.ssh"
  echo "Please generate a key pair using 'ssh-keygen'".
  exit
fi

sed -e "s;{SSH_KEY};${ssh_key};g" \
    ../control.yaml.tmpl \
    > control.yaml

../../transpile.sh control.yaml

hcloud server create \
  --name controlplane \
  --label k_type=demo-control-plane \
  --location fsn1 \
  --type cx33 \
  --image "${SNAPSHOT_ID}" \
  --user-data-from-file control.json

cp_ip="$(hcloud server list --selector k_type=demo-control-plane --output json | jq -r '.[].public_net.ipv4.ip')"
cp_id="$(hcloud server list --selector k_type=demo-control-plane --output json | jq -r '.[].id')"

echo "$cp_id" >IDs

echo "Server created."
echo "  ID:  $cp_id"
echo "  IP4: $cp_ip"

../init-control.sh "$cp_ip"
join_cmd="$(ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@$cp_ip kubeadm token create --print-join-command)"

export SNAPSHOT_ID
echo "Spawning 3 workers."
for i in 1 2 3; do
  ./worker.sh "${join_cmd}" "$i" &
done
wait

# backgrounded hcloud cli sometimes messes with the terminal
reset
echo "Done."

echo "Run "
echo "  hcloud server delete controlplane worker-1 worker-2 worker-3"
echo "to delete the cluster."

