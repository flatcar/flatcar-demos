#!/bin/bash
#
# Spawn a local python webserver e.g. for demos etc.
#

set -eo pipefail

ip="172.20.0.99"
port="8000"
listen="${ip}:${port}"
webroot="$(pwd)"
set_ip="true"

function usage() {
    echo
    echo "Usage: $0 [--listen <ip:port>] [--webroot <path>] --skip-ip-config"
    echo
    echo "       Starts a HTTP server for --webroot (defaults to the current directory '${webroot}')."
    echo "       By default, the server listens on '${default_listen}', and the IP"
    echo "       '${default_ip}' will be set on the 'lo' interface if 'lo' doesn't have it."
    echo "       Setting the IP requires 'sudo' access; use --skip-ip-config to skip this step."
    echo
}
# --

function check_arg() {
    if [[ -z $2 ]] ; then
        echo "ERROR: Option '$1' requires an argument." >&2
        exit
    fi

    echo "$2"
}
# --

while [ $# -gt 0 ] ; do
    case "$1" in
    --listen)
        listen="$(check_arg "$1" "$2")"
        ip="${listen/%:*/}"
        port="${listen//*:/}"
        if [[ ${ip} == ${port} || -z ${ip} || -z ${port} ]] ; then
            echo "Unable to parse '$listen'; please supply <ip:port>."
            exit 1
        fi
        shift; shift;;
    --webroot)
        webroot="$(check_arg "$1" "$2")"
        shift; shift;;
    --skip-ip-config)
        set_ip="false"
        shift;;
    -h|--help)
        usage; exit;;
    esac
done
# --

if $set_ip; then
    echo -n "Checking for IP '$ip' on 'lo': "
    if ip a l dev lo | grep inet | grep -q "$ip" ; then
        echo "IP is set."
    else
        echo "IP is not set. Setting... (needs SUDO access)"
        sudo ip a a "${ip}" dev lo
    fi
fi

echo "Starting webserver for '${webroot}' on '${listen}'."
echo "Press CTRL+C to abort."
python -m http.server -b "$ip" -d "${webroot}" "${port}"
