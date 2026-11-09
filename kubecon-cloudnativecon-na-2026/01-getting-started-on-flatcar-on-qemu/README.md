# 01 - Flatcar on QEMU

Boot Flatcar Container Linux under QEMU and let Ignition set the machine up
before you ever log in. One config (`config.bu`) sets the hostname, creates a
second user, stages a `welcome.sh` script and runs the `hello-world`
container on boot. Then we SSH in and show that the OS itself is read-only.

## Prerequisites

- `qemu-system-x86_64`, `curl`, `ssh-keygen`
- `docker` (runs the Butane transpiler)
- Network access to `stable.release.flatcar-linux.net`, `quay.io` and Docker
  Hub (`docker.io`, for the `hello-world` image the VM pulls on boot)

## Run it

```
./run.sh
```

The first run downloads the Flatcar image and wrapper script (a few hundred
MB) and caches them. Later runs boot straight away. Boot output streams to
this terminal. Press `Ctrl-A X` to quit QEMU.

## SSH in

Open a second terminal. Wait for the login prompt, then SSH in as either
the default `core` user or the `demo` user Ignition created:

```
ssh -i ssh/demo_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 core@localhost
ssh -i ssh/demo_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 demo@localhost
```

## What to show, once SSH'd in

Ignition did the work:

```
cat /etc/os-release               # this is Flatcar
hostname                          # flatcar-demo, set declaratively
groups demo                       # the second user, in docker and sudo
journalctl -u hello-world.service # the container ran once on boot
/opt/bin/welcome.sh               # the script Ignition staged
```

The OS is immutable:

```
mount | grep ' /usr '             # read-only
sudo touch /usr/test              # fails: read-only file system
echo ok | sudo tee /etc/test      # /etc is writable: config and data are yours
```

## Record boot and SSH together

```
./demo-tmux.sh
```

Two panes: the left boots the VM, the right waits for SSH and then gives you
a live prompt. `Ctrl-b` then an arrow key moves between panes. `Ctrl-b d`
detaches. Kill a stuck session with `tmux kill-session -t flatcar-demo`.

## Notes

- `config.bu` is the Butane source shown on stage. It holds a
  `__SSH_PUBLIC_KEY__` placeholder; `run.sh` generates a throwaway keypair
  under `ssh/` (gitignored) and substitutes the public key for both users
  before booting.
- The VM runs with `-snapshot`, so every run is a genuine first boot and
  Ignition re-provisions from scratch.
- `hello-world.service` is a oneshot that runs once, so `docker ps` will not
  list it. Use `journalctl` as above.
- GPG verification of the download is off by default. Set `VERIFY_GPG=1` to
  turn it on.
