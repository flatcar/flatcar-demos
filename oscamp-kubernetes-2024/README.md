## Preparation

You need:
bzip2 curl python qemu ssh vim docker

Get the second-latest Alpha version for the demos.
Don't use the latest release so update demo will work.
There's a helper script for that; run

./fetch_os_image.sh

to fetch the OS image into the local directory.
The script will also create a pristine copy which can be used to re-set the
base image to the default state (e.g. for re-provisioning).

Lastly, download the latest wasmtime sysext from
https://github.com/flatcar/sysext-bakery/releases/tag/latest
(`wasmtime-18.0.1-x86-64.raw` at the time of writing) into the "webserver"
sub-directory:
```
( cd webserver; curl -LO \
  https://github.com/flatcar/sysext-bakery/releases/download/latest/wasmtime-18.0.1-x86-64.raw \
)
```

There are 3 demos:
- Provision a simple web server + content.
- Update the node
- Provision a custom sysext. We use wasmtime.


## Provisioning Demo (provision a simple web server)


Show web server butane config. Inline HTML and logo image file are interesting.
Also, the config disasbles updates to not interfere with the demo.
```
vim web.yaml
```

Transpile to ignition. This will also inline the logo into the JSON.
```
cat web.yaml | docker run --rm -v $(pwd):/files \
    -i quay.io/coreos/butane:latest --files-dir /files  > web.json
```

Open a web browser and point it to http://localhost:8080 - nothing there.

Start the VM, which will provision the web server
```
./flatcar_production_qemu.sh -i web.json -p 8080-:80,hostfwd=tcp::2222 -nographic
```
This will put you right on the VM's serial console.

Reload http://localhost:8080 - after a few seconds the web page will appear.

Run this on the VM serial console to show the files we provisioned, and that the
"caddy" webserver is running.
```
ls -la /srv/www/html
docker ps
```

## Update demo

This can be done with the same deployment used for the web server demo as we're
not provisoining anything new.

Via the serial console, first enable update engine
```
sudo systemctl unmask update-engine
sudo systemctl start update-engine
```

Check for update status. Most likely it will report 'idle', and that it never
checked for updates.
```
update_engine_client -status
```

Make it check for updates. It should find an update.
```
update_engine_client -check_for_update
update_engine_client -status
```

Run status a number of times to show download progress.
```
update_engine_client -status
```
Continue after status switched to "reboot required".

Reload the web page at http://localhost:8080 to show the web app is still
running.

Show OS version and kernel version prior to reboot.
```
cat /etc/os-release
uname -a
```

Now reboot
```
sudo reboot
```
The VM will restart and again put the terminal on the VM serial console.

Show the new OS and kernel versions.
```
cat /etc/os-release
uname -a
```


Show the web app alive and happy at http://localhost:8080.


# Sysext demo

This is a from-scratch demo with its own provisioning so we need to reset the
OS image.
Power off the machine if it's still running
```
sudo shutdown now --poweroff
```

Now overwrite the OS image with the pristine backup
```
cp flatcar_production_qemu_image.img.pristine flatcar_production_qemu_image.img
```


The demo will need a temporary web server running on the host (we use python's
built-in http:server). Flatcar from inside the VM will need a well-known IP
address to connect to (`wasm.yaml` uses 172.16.0.99), so we add it to the
loopback interface:
```
sudo ip a a 172.16.0.99/32 dev lo
```

First, show the configuration. It's much simpler this time.
```
vim wasm.yaml
```

Transpile to JSON
```
cat wasm.yaml | docker run --rm -i quay.io/coreos/butane:latest > wasm.json
```

In a separate terminal, start the web server to serve the wasmtime sysext
```
cd webserver
ls -la
./start.sh
```
You will be able to see HTTP requests served by the server in this terminal.

Start Flatcar.
```
./flatcar_production_qemu.sh -i wasm.json -nographic
```
It's worth looking at the web server terminal while Flatcar is booting so we
see Ignition requesting and downloading the wasmtime sysext.

Once the Flatcar command line is available, verify the sysext was downloaded.
```
ls -la /opt/extensions/wasmtime/
```

Show that sysext does not yet know of wasmtime.
```
sudo systemd-sysext list
```
No wasmtime.

Expose wasmtime to systemd-sysext by creating a symlink to `/etc/extensions`
```
sudo ln -s /opt/extensions/wasmtime/wasmtime-18.0.1-x86-64.raw \
         /etc/extensions/wasmtime.raw
sudo systemd-sysext list
```
Systemd knows about wasmtime now but it's not merged.

No wasmtime:
```
wasmtime --version
ls -la /usr/bin/wasmtime
```

Merge it and check status
```
sudo systemd-sysext refresh
```

Now it's there
```
sudo systemd-sysext status
wasmtime --version
ls -la /usr/bin/wasmtime
```
