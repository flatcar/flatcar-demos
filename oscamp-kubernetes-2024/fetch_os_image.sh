#!/bin/bash
set -euo pipefail
# This will return the second-to-last alpha version
version=$(curl -s "https://www.flatcar.org/releases-json/releases.json" \
           | jq -r 'to_entries[] | select (.value.channel=="alpha") | .key | match("[0-9]+\\.[0-9]+\\.[0-9]+") | .string' \
           | sort -Vr | head -n2 | tail -n1)

board=amd64-usr
# board=arm64-usr

echo
echo    Downloading
echo

url="https://alpha.release.flatcar-linux.net/${board}/${version}/"
curl -fLO --progress-bar --retry-delay 1 --retry 60 --retry-connrefused \
        --retry-max-time 60 --connect-timeout 20 \
        "${url}/flatcar_production_qemu.sh"
curl -fLO --progress-bar --retry-delay 1 --retry 60 --retry-connrefused \
        --retry-max-time 60 --connect-timeout 20 \
        "${url}/flatcar_production_qemu_image.img.bz2"

echo
echo    Uncompressing
echo

bunzip2 flatcar_production_qemu_image.img.bz2
chmod 755 flatcar_production_qemu.sh

echo
echo    Creating pristine copy
echo

cp flatcar_production_qemu_image.img flatcar_production_qemu_image.img.pristine
