# Flatcar Container Linux basic intro demo for KCD Berlin, 2022

YAML config contains
1. user "caddy" set-up
2. inline HTML and separate GIF for a static website
3. Systemd unit for running caddy to serve the file
4. Deactivate automated reboots

We ship a custom `flatcar_production_qemu.sh` because at the time of writing the script did not support forwarding custom ports.
The script forwards connections to host port 8080 to container port 80 so we can serve websites.

## Provisioning Demo

Download a Flatcar release (NOT the current / most recent one) from [here](https://www.flatcar.org/releases/).
Use an older version to demo updates.

Move the image to a new name to keep a pristine version; copy it to the original name to have a working copy.
```shell
mv flatcar_production_qemu_image.img flatcar_production_qemu_image.img.pristine
cp flatcar_production_qemu_image.img.pristine flatcar_production_qemu_image.img
```

1. Create ignition from YAML:
   ```shell
   cat talk.yaml | docker run --rm -v $(pwd):/files -i ghcr.io/flatcar-linux/ct:latest --files-dir /files  > ignition.json
   ```
2. Start flatcar
   ```shell
   ./flatcar_production_qemu.sh -i ignition.json -nographic
   ```
3. Point your browser to [http://localhost:8080](http://localhost:8080).
4. SSH into the instance
   ```shell
   ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" core@localhost -p 2222
   ```
5. Show `/srv/www/html` with the files created, `systemctl status kcd-demo-webserver`, and `docker ps`.


## Update demo
```shell
update_engine_client -status
ls -la /var/run/reboot-required

update_engine_client -check_for_updates

update_engine_client -status
ls -la /var/run/reboot-required

cat /etc/os-release

reboot

cat /etc/os-release
```
