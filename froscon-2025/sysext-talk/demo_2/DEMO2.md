# Sysupdate demo

This demo updates the kubernetes extension image using sysupdate.

We'll provision the sysext, symlink, and sysupdate config but won't start
sysupdate automatically at boot, so we can demo the update process

```bash
vim sysupdate.yaml
transpile.sh sysupdate.yaml
```

Start the webserver that will serve the sysext
```bash
cd webserver
python -m http.server
```

```bash
cd flatcar-vm
./flatcar_production_qemu_uefi.sh -i ../sysupdate.json -nographic -snapshot
```

Then, in the instance
```bash
sudo -i
kubelet --version
systemd-sysext
ls -la /etc/extensions/
ls -la /opt/extensions/kubernetes/
```

Show contents and SHA256SUMS in the webserver directory:
```bash
cd webserver
ls -la
cat SHA256SUMS
```

Now start sysupdate manually.
This is usually being done by the timer unit, but we diabled that.
```bash
journalctl -u systemd-sysupdate --no-pager
systemctl start systemd-sysupdate
journalctl -u systemd-sysupdate --no-pager

ls -la /opt/extensions/kubernetes/
ls -la /etc/extensions/
```

The update was staged but hasn't been activated yet.
```bash
kubelet --version
systemctl reload systemd-sysext
kubelet --version
```
