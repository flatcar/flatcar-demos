#!/bin/bash

function sha_or_del() {
    local channel="$1"
    
    cat flatcar_production_qemu_uefi_image.img.bz2.DIGESTS.asc \
        | grep -A1 'SHA512 HASH' \
        | grep -E '(flatcar_production_qemu_uefi_image.img.bz2)|(flatcar_production_qemu_uefi.sh)' \
            >digest.sha512

    sha512sum --quiet --check digest.sha512 || {
        echo "ERROR downloading '$channel': SHA512 mismatch. Deleting."
        rm "flatcar_production_qemu_uefi.sh" \
             "flatcar_production_qemu_uefi_efi_code.fd" \
             "flatcar_production_qemu_uefi_efi_code.qcow2" \
             "flatcar_production_qemu_uefi_efi_vars.fd" \
             "flatcar_production_qemu_uefi_efi_vars.qcow2" \
             "flatcar_production_qemu_uefi_image.img.bz2.DIGESTS.asc" \
             "flatcar_production_qemu_uefi_image.img.bz2"  \
            digest.sha515
    }
}
# --

function fetch_release_image() {
    local channel="$1"
    local arch="$2"
    local rel="$3"

    local dest="${channel}-${arch}-${rel}"

    mkdir -p "$dest"
    cd "$dest"

    rm -f *

    local i
    for i in "flatcar_production_qemu_uefi.sh" \
             "flatcar_production_qemu_uefi_efi_code.fd" \
             "flatcar_production_qemu_uefi_efi_code.qcow2" \
             "flatcar_production_qemu_uefi_efi_vars.fd" \
             "flatcar_production_qemu_uefi_efi_vars.qcow2" \
             "flatcar_production_qemu_uefi_image.img.bz2.DIGESTS.asc" \
             "flatcar_production_qemu_uefi_image.img.bz2" ; do
        wget -q \
            "https://${channel}.release.flatcar-linux.net/${arch}-usr/${rel}/$i"
    done

    chmod 755 "flatcar_production_qemu_uefi.sh"

    sha_or_del "$channel"

    [ -f flatcar_production_qemu_uefi_image.img.bz2 ] && \
        bunzip2 flatcar_production_qemu_uefi_image.img.bz2
}
# --

function wait_and_ls() {
    local a="$1"
    local v="$2"
    shift; shift
    local channels="${@}"

    while [ -n "$(jobs -r)" ]; do
        local s=""
        for c in $channels; do
            if [ -f "$c-$a-$v/flatcar_production_qemu_uefi_image.img" ] ; then
                if [ -f "$c-$a-$v/flatcar_production_qemu_uefi_image.img.bz2" ] ; then
                    s="$s    $c:BUNZIP"
                else
                    s="$s    $c:DONE  "
                fi
            else
                s="$s    $c:$(ls -lh $c-$a-$v/*.bz2 2>/dev/null | awk '{print $5}')"
            fi
        done
        echo -n -e "\r$s           "
        sleep 1
    done
}
# --

function get_images() {
    local arch="${ARCH:-amd64}"
    local version="${VERSION:-current}"
    if [[ $# -eq 0 ]]; then
        set -- alpha beta stable
    fi

    echo -n "Fetching ${arch} qemu images (parallel) for: "
    while [ $# -gt 0 ]; do
        fetch_release_image "$1" "$arch" "$version" &
        channels="$channels $1"
        shift
    done
    echo "$channels"

    wait_and_ls "$arch" "$version" "$channels"

    echo ""
    echo "Done"
}
# --

if [ "$(basename $0)" = "flatcar-download-qemu.sh" ] ; then
	get_images $@
fi
