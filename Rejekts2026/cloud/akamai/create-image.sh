#!/bin/bash

function create_image() {
  local channel="$1"
  local region="$2"
  local image_name="$3"

  if [[ ! -f flatcar_production_akamai_image.bin.gz ]] ; then
    echo "Downloading latest '${channel}' release..."
    wget "https://${channel}.release.flatcar-linux.net/amd64-usr/current/flatcar_production_akamai_image.bin.gz"
  else
    echo "Using local flatcar_production_akamai_image.bin.gz"
  fi

  echo "Uploading Linode image in '${region}' with label '${image_name}'"
  linode-cli image-upload \
    --region "${region}" \
    --label "${image_name}" \
    --description "Flatcar Linux '${channel}'" \
    --cloud-init \
    flatcar_production_akamai_image.bin.gz

  rm linode-cli images list --label "k8s-demo-flatcar-alpha"
}

create_image alpha eu-central k8s-demo-flatcar-alpha
