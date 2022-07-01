# Flatcar Container Linux basic intro demo for KCD Berlin, 2022

YAML config contains
1. user "caddy" set-up
2. inline HTML and separate GIF for a static website
3. Systemd unit for running caddy to serve the file
4. Deactivate automated reboots

## Provisioning Demo

Download a Flatcar release (NOT the current / most recent one; use an older version to demo updates) from [here](https://www.flatcar.org/releases/).
Don't forget to also download the accompanying `flatcar_production_qemu.sh`; we'll need it for the demo.

Move the image to a new name to keep a pristine version; copy it to the original name to have a working copy.
```shell
mv flatcar_production_qemu_image.img flatcar_production_qemu_image.img.pristine
cp flatcar_production_qemu_image.img.pristine flatcar_production_qemu_image.img
```

1. Create ignition from YAML:
   ```shell
   cat talk.yaml | docker run --rm -v $(pwd):/files -i ghcr.io/flatcar-linux/ct:latest --files-dir /files  > ignition.json
   ```
2. Start flatcar. Kudos to @pothos for the cool port forwarding hack.
   ```shell
   ./flatcar_production_qemu.sh -i ignition.json -p 8080-:80,hostfwd=tcp::2222 --nographic
   ```
3. Point your browser to [http://localhost:8080](http://localhost:8080).
4. SSH into the instance
   ```shell
   ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" core@localhost -p 2222
   ```
5. Show `/srv/www/html` with the files created, `systemctl status kcd-demo-webserver`, and `docker ps`.


## Update demo

Using the instance provisioned above we'll check for updates, stage, and activate (reboot).
It might be necesssary to re-provision (i.e. start from a pristine downloaded image) depending on the time spent on the instance above.
(Instance might have staged the update already).

1. Check update status, reboot flag (it's not there), and OS version.
   ```shell
   update_engine_client -status
   ls -la /var/run/reboot-required
   cat /etc/os-release
   ```
2. Check for update (which will trigger update download), re-check status (maybe use watch).
   ```shell
   update_engine_client -check_for_update
   update_engine_client -status
   watch update_engine_client -status
   ```
3. Check for "reboot required" flag file, activate update.
   ```shell
   ls -la /var/run/reboot-required
   cat /etc/os-release
   reboot
   cat /etc/os-release
   ```
