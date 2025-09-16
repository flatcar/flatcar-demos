# BEFORE YOU START

Thilo, start provisioning the CAPI cluster!

## Demo 1 - What is a sysext and how does it work?

This demo just ships a Kubernetes sysext to a single node.
The demo is sysext focused and uses the Kubernetes sysext for demo purposes.
We won't deal with actual Kubernetes just yet.

* mount and explore the kubernetes sysext locally
* Midnight Commander in "tree mode" in the leftpanel and browsing the sysext
  in the right panel has proven to work for this.

We'll now deploy this to a local qemu instance.
Let's explore the deployment config.

```bash
vim sysext.yaml
transpile.sh sysext.yaml
```

Start the webserver that will serve the sysext
```bash
cd webserver
python -m http.server
```

```bash
cd flatcar-vm
./flatcar_production_qemu_uefi.sh -i ../sysext.json -nographic -snapshot
```

Then, in the instance
Make systemd aware of the sysext, list it.
```bash
systemd-sysext list
ln -s /opt/extensions/kubernetes/kubernetes-v1.33.0-x86-64.raw /etc/extensions/kubernetes.raw
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
