# Kubernetes Cluster Plumbing demos

The demos use sub-directories so as to not pollute the repo demo folder
* All local demos use `./demo-local`
* The ClusterAPI demo uses `./demo`

Our first step is to create these directories:
```bash
mkdir -p demo-local demo
```

Then, download a flatcar qemu image and supplemental files (start script and
EFI binaries) from https://stable.release.flatcar-linux.net/amd64-usr/ .
Make sure not not use the latest release to ensure a newer version being
available for the OS update demo.

Finally, copy all the local demos' YAML files to `demo-local`
```bash
cp *.yaml demo-local
```
And you're set!

## Single Node Sysext demo

This demo just ships a Kubernetes sysext to a single node.
The demo is sysext focused and uses the Kubernetes sysext for demo purposes.
We won't deal with actual Kubernetes just yet.

First, switch to the demo directory if you haven't yet
```bash
cd demo-local
```

Look at the sysext provisioning config and start the node.
```bash
vim sysext.yaml
./flatcar_production_qemu_uefi.sh -i sysext.json -nographic -snapshot
```

Then, in the instance
```bash
sudo -i
mount /opt/extensions/kubernetes/kubernetes-v1.31.3-x86-64.raw /mnt/

ls -la /mnt
ls -R /mnt

ls -R /mnt/usr/lib/systemd/system/
cat /mnt/usr/lib/extension-release.d/extension-release.kubernetes
umount /mnt
```

Make systemd aware of the sysext, list it.
```bash
systemd-sysext list
ln -s /opt/extensions/kubernetes/kubernetes-v1.31.3-x86-64.raw /etc/extensions/kubernetes.raw
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

## Sysupdate demo

This demo updates the kubernetes sysext using sysupdate.
We'll provision the sysext, symlink, and sysupdate config but won't start sysupdate automatically at boot, so we can demo the update process

First, switch to the demo directory if you haven't yet
```bash
cd demo-local
```

```bash
vim sysupdate.yaml
./flatcar_production_qemu_uefi.sh -i sysupdate.json -nographic -snapshot
```

Then, in the instance
```bash
sudo -i
kubelet --version
systemd-sysext
ls -la /etc/extensions/
ls -la /opt/extensions/kubernetes/
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
reboot
kubelet --version
```

## Local Kubernetes Cluster

We'll create a local Kubernetes cluster manually.
The cluster will consist of mutliple qemu VMs running on the local host.
We'll use qemu's `-snapshot` option which runs qemu with ephemeral disk.
No changes to the image will be written, so we can start multiple qemu instances from the same image file.

We'll largely follow the Flatcar docs: https://www.flatcar.org/docs/latest/container-runtimes/getting-started-with-kubernetes/

First, switch to the demo directory if you haven't yet
```bash
cd demo-local
```

We provision the control plane node.
```bash
vim kubernetes-control.yaml

./flatcar_production_qemu_uefi.sh -i kubernetes-control.json -p 6443-:6443,hostfwd=tcp::2222 \
    -nographic -snapshot  -device e1000,netdev=n1,mac=52:54:00:12:34:56                      \
    -netdev socket,id=n1,mcast=230.0.0.1:1234   

coressh.sh cat .kube/config | sed 's,server:.*,server: https://localhost:6443,' >kubeconfig
```

After a few seconds the control plane node should be up but not ready.
For this we need to install a CNI:
```bash
watch -n1 kubectl --kubeconfig kubeconfig get nodes -o wide

kubectl --kubeconfig kubeconfig apply                                                   \
 -f https://raw.githubusercontent.com/projectcalico/calico/v4.24.1/manifests/calico.yaml

watch -n1 kubectl --kubeconfig kubeconfig get nodes -o wide
```

Now generate the token for workers to join the cluster and update the worker config.
```bash
coressh.sh kubeadm token create --print-join-command

vim kubernetes-worker1.yaml
vim kubernetes-worker2.yaml

transpile.sh kubernetes-worker1.yaml
transpile.sh kubernetes-worker2.yaml
```

Start the worker nodes and wait for them to join.
```bash
./flatcar_production_qemu_uefi.sh -i kubernetes-worker1.json -p 2223 -nographic -snapshot  \
	-device e1000,netdev=n1,mac=52:54:00:12:34:57 -netdev socket,id=n1,mcast=230.0.0.1:1234   

./flatcar_production_qemu_uefi.sh -i kubernetes-worker2.json -p 2224 -nographic -snapshot  \
	-device e1000,netdev=n1,mac=52:54:00:12:34:58 -netdev socket,id=n1,mcast=230.0.0.1:1234   
```

### Update Kubernetes


Check for reboot flag and reboot the workers
```bash
ls -la /run

journalctl -u systemd-sysupdate --no-pager

reboot

ls -la /etc/extensions
ls -la /opt/extensions/kubernetes
```

### Update the OS

Unmask and enable update-engine which we masked in the node configuration
```
systemctl unmask update-engine
systemctl enable --now update-engine

update_engine_client -status
update_engine_client -check-for-update
update_engine_client -status
```

```bash
ls -la /run
reboot
```

## ClusterAPI demo on Azure

This largely follows the automation in [CAPZ-demo](../../CAPZ-demo) so go check
that out first.

TL;DR
```bash
bash -i
source ../../../CAPZ-sysext/capz-demo.env

get_prerequisites
setup_kind_cluster
generate_capz_yaml
```

Now add the sysupdate enable patch
```bash
patch -p0 <../../../CAPZ-sysext/enable-updates.patch
```

The az command in `azure.env.template` currently creates a tenant w/o using
user identity, so we need to remove userIdentity from the cluster YAML:
```bash
patch -p0 <../../../CAPZ-sysext/fix-user-identity.patch
```

Deploy the new cluster
```bash
deploy_capz_cluster

kc_worker get nodes -o wide
```

After worker nodes are operational
```bash
kc_worker apply -f ../../../CAPZ-sysext/kured-dockerhub.yaml
```

Watch the in-place update
```bash
watch 'source ../../../CAPZ-sysext/capz-demo.env; kc_worker get nodes -o wide;'
```
