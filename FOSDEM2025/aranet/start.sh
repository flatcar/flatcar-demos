#!/bin/bash

source ./config.env

echo "Ensuring grafana and prometheus data dirs exist and have user ownership"
mkdir -p prometheus-data grafana-data

echo "Enabling bluetooth."
sudo rfkill unblock bluetooth
sudo systemctl start bluetooth.service
bluetoothctl power on

function read_until() {
    local match="$1"

    while read line; do
        if [[ $line == *"${match}"* ]] ; then
            break
        fi
    done <&"${bluetoothctl[0]}"
}
# --

function pair_device() {
    # <mac>[=name]
    local devinfo="$1"

    local mac="${devinfo%=*}"

    if bluetoothctl devices Paired | grep -q "${mac}" ; then
        echo "${mac} is paired."
        return
    fi

    echo "${mac} is not paired. Pairing..."

    # Scan for devices if MAC was not seen yet
    if ! bluetoothctl devices | grep -q "${mac}" ; then
        echo -e 'scan on\n' >&"${bluetoothctl[1]}"
        read_until "${mac}"
    fi

    echo -e "pair ${mac}\n" >&"${bluetoothctl[1]}"
    read_until "Request passkey"
    read -p "Enter PIN displayed on the device:" pin
    echo -e "${pin}\n" >&"${bluetoothctl[1]}"

    read_until "Pairing successful" <&"${bluetoothctl[0]}"
}
# --

# Global; used by bluetooth sub-functions
coproc bluetoothctl { bluetoothctl ; }
rm -f .devices.cfg

for devinfo in ${DEVICES//,/ }; do
    pair_device "${devinfo}"
    echo -n "-device ${devinfo} " >> .devices.cfg
done

echo -e 'quit\n' >&"${bluetoothctl[1]}"

echo UID="$UID" > .uid.env

trap 'docker compose --env-file config.env --env-file .uid.env down' EXIT
docker compose --env-file config.env --env-file .uid.env up
