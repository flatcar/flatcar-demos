#!/bin/bash

source ./config.env

echo "Ensuring grafana and prometheus data dirs exist and have user ownership"
mkdir -p prometheus-data grafana-data aranet-exporter-state

echo "Enabling bluetooth."
sudo rfkill unblock bluetooth
sudo systemctl start bluetooth.service

rm -f .devices.cfg

function read_until() {
    local match="$1"
    local abort="${2:-}"

    while read line; do
        if [[ $line == *"${match}"* ]] ; then
            return 0
        fi
        if [[ -n "${abort}" && $line == *"${abort}"* ]] ; then
            return 1
        fi
        echo -e "\t\t\t  [ BLUETOOTH: '${line}' ]"
    done <&"${bluetoothctl[0]}"
}
# --

device_wait_state() {
    local mac="$1"
    local state="$2"

    while ! bluetoothctl devices "${state}"| grep -q "${mac}" ; do
        sleep 0.5
    done
    echo "${mac} is ${state}."
}
# --

# Take <action> on <device> if not in state <state>.
# Return 0 if no action was necessary, 1 if action was taken.
function device_state_action() {
    local mac="$1"
    local state="$2"
    local action="$3"

    # Scan for devices if MAC was not seen yet
    if ! bluetoothctl devices | grep -q "${mac}" ; then
        echo "${mac} not detected by bluetooth yet. Scanning..."
        echo -e 'scan on\n' >&"${bluetoothctl[1]}"
        read_until "${mac}"
    fi

    if bluetoothctl devices "${state}"| grep -q "${mac}" ; then
        echo "${mac} is ${state}."
        return 0
    fi

    echo "${mac} is not ${state}. Running ${action} ${mac}..."
    echo -e "${action} ${mac}\n" >&"${bluetoothctl[1]}"

    return 1
}
#--

function pair_device() {
    # <mac>[=name]
    local mac="${1%=*}"

    if device_state_action "${mac}" "Paired" "pair" ; then
        return
    fi

    read_until "Request passkey"
    read -p "Enter PIN displayed on the device:" pin
    echo -e "${pin}\n" >&"${bluetoothctl[1]}"

    if ! read_until "Pairing successful" "Failed to pair" ; then
        echo "Pairing failed; retrying..."
        pair_device "${mac}"
    fi
}
# --

function connect_device() {
    # <mac>[=name]
    local mac="${1%=*}"

    device_state_action "${mac}" "Connected" "connect"
    device_wait_state "${mac}" "Connected"
}
# --


# Global; used by bluetooth sub-functions
coproc bluetoothctl { bluetoothctl ; }
echo -e "power on\n" >&"${bluetoothctl[1]}"

for devinfo in ${DEVICES//,/ }; do
    pair_device "${devinfo}"
    connect_device "${devinfo}"
    echo -n "-device ${devinfo} " >> .devices.cfg
done

echo -e 'quit\n' >&"${bluetoothctl[1]}"

echo UID="$UID" > .uid.env

trap 'docker compose --env-file config.env --env-file .uid.env down' EXIT
docker compose --env-file config.env --env-file .uid.env up
