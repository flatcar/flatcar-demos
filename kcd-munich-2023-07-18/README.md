# Flatcar Container Linux basic intro demo for KCD Munich, 2023

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
   cat talk.yaml | docker run --rm -v $(pwd):/files -i quay.io/coreos/butane:latest --files-dir /files  > ignition.json
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
While the default behavior of Flatcar is to reboot automatically, this has been turned off in the Ignition config (see `reboot_strategy` in the YAML file).
It might be necessary to re-provision fro scratch (i.e. start from a new copy of the pristine downloaded) depending on the time spent on the instance above since the instance might have staged the update already.

Alternatively we could use `update_engine_client -reset_status` and then make `update_engine` check again - this can also be used to discard staged (but outdated) updates in favour of a fresh download of the latest release.

1. Check update status, reboot flag (it's not there), and OS version.
   ```shell
   update_engine_client -status
   ```
2. Check for update (which will trigger update download), re-check status (maybe use watch).
   ```shell
   update_engine_client -check_for_update
   update_engine_client -status
   ```
3. After the update was downloaded and staged, check OS and kernel version, then activate update.
   ```shell
   cat /etc/os-release
   reboot
   uname -a
   cat /etc/os-release
   uname -a
   ```

# Sysext demo

This demo uses a wasmtime sysext built via https://github.com/flatcar/sysext-bakery.
The example below uses wasmtime-8 but it should work with any version.

For this demo, we'll provide the wasmtime sysext via a "virt/" subdirectory on the host which we'll import in the VM using the 9p filesystem.

The Flatcar VM needs to be started with an additional option for the import to become available:
```shell
./flatcar_production_qemu.sh -virtfs local,path=$(pwd)/virt,mount_tag=host0,security_model=passthrough,id=host0
```

In the VM, we mount the 9pfs and copy wasmtime into the extensions directory.
```shell
mount -t 9p -o trans=virtio,version=9p2000.L host0 /mnt
cp /mnt/wasmtime-8.raw /etc/extensions/
```

We check if the `wasmtime` binary is available (it shouldn't):
```shell
wasmtime
ls -la /usr/bin/wasmtime
```

Now we list available extensions, check extensions status, and activate the wasmtime extension:
```shell
systemd-sysext list
systemd-sysext status
systemd-sysext refresh
systemd-sysext status
```

We check again and `wasmtime` is now available:
```shell
wasmtime
ls -la /usr/bin/wasmtime
```
