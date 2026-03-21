#!/bin/bash

set -euo pipefail

function wait_status() {
  local cmd="$1"
  local status="$2"
  local timeout="${3:-120}"

  local stat
  local tick=1
  while true; do

    # || true because sometimes linode-cli fails w/ 404 for no reason
    stat="$(linode-cli ${cmd} --json 2>/dev/null| jq -r '.[0].status' || true)"
    if [[ ${stat} == ${status} ]] ; then
      return 0
    fi

    echo -n "."

    if [[ $tick -ge $timeout ]] ; then
      echo "ERROR: Action '$cmd' timed out after '$timed' seconds while waiting for status '$status'."
      break
    fi

    sleep 1
    ((tick++))
  done

  return 1
}
# --

# Process command line args
#
image="$1"
name="$2"
ignition="$3"
userdata="$(cat "${ignition}" | gzip | base64 -w0)"

# Check for image label, upload if not found

echo -n "Preparing instance."
vm_id="$(linode-cli linodes create \
          --region eu-central \
          --booted false \
          --metadata.user_data "${userdata}" \
          --type g6-standard-4 \
          --label "${name}" \
          --no-defaults \
          --json | jq -r '.[0].id')"

wait_status "linodes view ${vm_id}" "offline"
echo

vm_ipv4="$(linode-cli linodes view "${vm_id}" --json | jq -r '.[0].ipv4[0]')"
vm_ipv6="$(linode-cli linodes view "${vm_id}" --json | jq -r '.[0].ipv6')"
echo "Linode prepared. IPv4: '${vm_ipv4}', IPv6: '${vm_ipv6}'"

echo -n "Preparing instance disk."
# NOTE: --root_pass is required by the CLI but ignored by Flatcar.
max_disk_size=$(linode-cli linodes type-view g6-standard-4 --json | jq -r '.[0].disk')
linode-cli linodes disk-create \
    --size "${max_disk_size}" \
    --label "${name}-OS" \
    --image "${image}" \
    --root_pass "MyPABCDEword123==" \
    --no-defaults \
    "${vm_id}" >/dev/null

disk_id=$(linode-cli linodes disks-list --json "${vm_id}" | jq -r '.[0].id')

wait_status "linodes disk-view ${vm_id} ${disk_id}" "ready"
echo

echo "Creating instance configuration profile"
linode-cli linodes config-create \
    --kernel linode/direct-disk \
    --helpers.updatedb_disabled true \
    --helpers.distro false \
    --helpers.modules_dep false \
    --helpers.network false \
    --helpers.devtmpfs_automount false \
    --label "${name}-cfg-profile" \
    --devices.sda.disk_id "${disk_id}" \
    --root_device /dev/sda \
    "${vm_id}" >/dev/null

echo -n "Linode starting. IPv4: '${vm_ipv4}', IPv6: '${vm_ipv6}'."

linode-cli linodes boot "${vm_id}" >/dev/null 
wait_status "linodes view ${vm_id}" "running" 300
echo

echo "Linode ready. IPv4: '${vm_ipv4}', IPv6: '${vm_ipv6}', ID: '${vm_id}'"
