#!/bin/bash

port=2000
if [[ "$1" =~ '^[0-9]+$' ]] ; then
  port="$1"
fi

exec ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" core@localhost -p "$port" "${@}"
