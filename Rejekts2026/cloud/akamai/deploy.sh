#!/bin/bash

set -euo pipefail

IMAGE_ID=""

if [[ -z "$IMAGE_ID" ]] ; then
  echo "ERROR: IMAGE_ID not set in $0."
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

./create-linode.sh "${IMAGE_ID}" k8s-demo-controlplane control.json

cp_ip="$(linode-cli linodes list --json | jq -r '.[]|select(.label == "k8s-demo-controlplane") | .ipv4[0]')"
cp_id="$(linode-cli linodes list --json | jq -r '.[]|select(.label == "k8s-demo-controlplane") | .id')"
echo "$cp_id" >IDs

echo "Server created."
echo "  ID:  $cp_id"
echo "  IP4: $cp_ip"

../init-control.sh "$cp_ip"
join_cmd="$(ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@$cp_ip kubeadm token create --print-join-command)"

export IMAGE_ID
echo "Spawning 3 workers."
for i in 1 2 3; do
  ./worker.sh "${join_cmd}" "$i" &
done
wait

declare -a w_ids
for i in 1 2 3; do
  w_ids+=( "$(linode-cli linodes list --json | jq -r ".[]|select(.label == \"k8s-demo-worker-${i}\") | .id")" )
done

echo "Done."

echo "Run "
echo "   for ID in ${cp_id} ${w_ids[@]}; do linode-cli linodes delete \"\${ID}\"; done"
echo "to delete the cluster."
