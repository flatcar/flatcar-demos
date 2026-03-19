# Local Kubernetes Cluster

This demos automated fetching and staging of extension images on a real life kubernetes kluster.

We'll create a local Kubernetes cluster manually.
The cluster will consist of mutliple qemu VMs running on the local host.
We'll use qemu's `-snapshot` option which runs qemu with ephemeral disk.
No changes to the image will be written, so we can start multiple qemu instances from the same image file.

We'll do all work in the `flatcar-vm` subdirtectory.
Make sure a Flatcar image has been downloaded; run
```bash
flatcar-download-qemu.sh alpha
```
to download the latest alpha release.

You can specify which channel / release to download (for instance, to download a previous release for demoing in-place OS updates):
```bash
flatcar-download-qemu.sh <channel> [<release>]
```
e.g.
```bash
flatcar-download-qemu.sh alpha 4593.0.0
```
to download the January 2026 Alpha release.

# Provisioning

First, we provision the control plane node, since that takes a few minutes.
```bash
cd flatcar-vm
../control.sh
```

In a separate terminal, initialise the control plane node:
```bash
../init-control.sh
```
This will print a "join command" whenfinished.

Using the "join command", spawn a few worker nodes:
```bash
../worker.sh <join-command> 1
../worker.sh <join-command> 2
../worker.sh <join-command> 3
```

Check cluster status with
```
watch -n1 kubectl --kubeconfig kubeconfig get nodes -o wide
```

### Bonus track: In-place updates

Trigger an in-place update:
```
kubectl --kubeconfig kubeconfig apply -f ../../kured-dockerhub.yaml
```
then watch the nodes updating.
Might take a few minuted until the upgrade process starts.
