# BEFORE YOU START

Thilo, apply the kured yaml!

## Local Kubernetes Cluster


This demos automated fetching and staging of extension images on a real life
kubernetes kluster.

We'll create a local Kubernetes cluster manually.
The cluster will consist of mutliple qemu VMs running on the local host.
We'll use qemu's `-snapshot` option which runs qemu with ephemeral disk.
No changes to the image will be written, so we can start multiple qemu instances from the same image file.

We'll largely follow the Flatcar docs: https://www.flatcar.org/docs/latest/container-runtimes/getting-started-with-kubernetes/

Start the webserver that will serve the sysext
```bash
cd webserver
python -m http.server
```

First, we provision the control plane node, since that takes a few minutes.
Then we look at the configuration.
```bash
transpile.sh kubernetes-control.yaml

cd flatcar-vm

./flatcar_production_qemu_uefi.sh -i ../kubernetes-control.json -p 6443-:6443,hostfwd=tcp::2222 \
    -nographic -snapshot  -device e1000,netdev=n1,mac=52:54:00:12:34:56                      \
    -netdev socket,id=n1,mcast=230.0.0.1:1234   

vim ../kubernetes-control.yaml

coressh.sh cat .kube/config | sed 's,server:.*,server: https://localhost:6443,' >kubeconfig
```

After a few seconds the control plane node should be up but not ready.
For this we need to install a CNI:
```bash
kubectl --kubeconfig kubeconfig get nodes

kubectl --kubeconfig kubeconfig apply                                                   \
 -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml

kubectl --kubeconfig kubeconfig get nodes
kubectl --kubeconfig kubeconfig get pods -n kube-system
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

### Check for staged update and update Kubernetes

```bash
ls -la /etc/extensions
ls -la /opt/extensions/kubernetes
```

Check for reboot flag and reboot the workers
```bash
ls -la /run

journalctl -u systemd-sysupdate --no-pager

reboot

ls -la /etc/extensions
ls -la /opt/extensions/kubernetes
```
