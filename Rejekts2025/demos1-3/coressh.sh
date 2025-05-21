exec ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" core@localhost -p 2222 "${@}"
