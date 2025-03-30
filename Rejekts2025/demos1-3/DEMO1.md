# BEFORE YOU START

Thilo, start provisioning the CAPI cluster!

## Demo 1 - What is a sysext and how does it work?

This demo just ships a Kubernetes sysext to a single node.
The demo is sysext focused and uses the Kubernetes sysext for demo purposes.
We won't deal with actual Kubernetes just yet.

```bash
vim sysext.yaml
transpile.sh sysext.yaml
```

```bash
cd flatcar-vm
./flatcar_production_qemu_uefi.sh -i ../sysext.json -nographic -snapshot
```

Then, in the instance
```bash
sudo -i
mount /opt/extensions/kubernetes/kubernetes-v1.31.0-x86-64.raw /mnt/

ls -la /mnt
ls -R /mnt

ls -R /mnt/usr/lib/systemd/system/
cat /mnt/usr/lib/extension-release.d/extension-release.kubernetes
cat /mnt/usr/lib/systemd/system/kubelet.service
umount /mnt
```

Make systemd aware of the sysext, list it.
```bash
systemd-sysext list
ln -s /opt/extensions/kubernetes/kubernetes-v1.31.0-x86-64.raw /etc/extensions/kubernetes.raw
systemd-sysext list
systemd-sysext
```
Activate ("merge") the sysext, show kubelet service trying to start.
```bash
ls /usr/bin/ku*
systemctl status kubelet --no-pager
systemd-sysext refresh
ls /usr/bin/ku*
systemctl status kubelet --no-pager
kubelet --version
```
