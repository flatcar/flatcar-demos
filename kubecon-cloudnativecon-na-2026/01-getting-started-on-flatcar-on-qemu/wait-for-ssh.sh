#!/usr/bin/env bash
#
# Waits for the Flatcar VM's forwarded SSH port, then gives you a prompt so
# you type the ssh command live.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

SSH_KEY="ssh/demo_ed25519"

echo "Waiting for Flatcar to finish booting and sshd to come up on :2222..."
until (exec 3<>/dev/tcp/127.0.0.1/2222) 2>/dev/null; do
    sleep 1
done
exec 3>&- 3<&- 2>/dev/null || true

# Small buffer: the port can accept TCP connections a moment before sshd is
# fully ready to authenticate.
sleep 2

echo
echo "Ready. SSH in as either user with:"
echo "  ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 core@localhost"
echo "  ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 demo@localhost"
echo
echo "Ignition wired up the hostname, the demo user, and the hello-world container on boot."
echo
exec "${SHELL:-bash}"
