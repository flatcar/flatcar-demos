## Provisioning Demo


cat web.yaml | docker run --rm -v $(pwd):/files \
    -i quay.io/coreos/butane:latest --files-dir /files  > web.json

./flatcar_production_qemu.sh -i web.json \
        -p 8080-:80,hostfwd=tcp::2222 --nographic

http://localhost:8080

ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" \
        core@localhost -p 2222














## Update demo

sudo systemctl unmask update-engine
sudo systemctl start update-engine

update_engine_client -status

update_engine_client -check_for_update
watch update_engine_client -status

cat /etc/os-release
uname -a
sudo reboot
cat /etc/os-release
uname -a











# Sysext demo

cp flatcar_production_qemu_image.img.pristine flatcar_production_qemu_image.img

vim wasm.yaml (change ip address to local IP)

cat wasm.yaml | docker run --rm -i quay.io/coreos/butane:latest > wasm.json

./flatcar_production_qemu.sh -i wasm.json -nographic

sudo ln -s /opt/extensions/wasmtime/wasmtime-13.0.0-x86-64.raw \
         /etc/extensions/wasmtime.raw

wasmtime
ls -la /usr/bin/wasmtime

systemd-sysext list
systemd-sysext status
systemd-sysext refresh
systemd-sysext status

wasmtime
ls -la /usr/bin/wasmtime
