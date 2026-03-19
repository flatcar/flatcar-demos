# Hetzner

## Prerequisites: image uploaded and image ID available

If you haven't uploaded a Flatcar image to Hetzner, this will need to be done first.

Configure which image to use.
```bash
export CHANNEL=alpha
export VERSION=current
export ARCH=amd64
export HC_ARCH=x86
```

Configure your hetzner token
```bash
 export HCLOUD_TOKEN=
```

Get hcloud-upload-image from here: https://github.com/apricote/hcloud-upload-image/releases/latest
Create image
```bash
hcloud-upload-image upload \
  --architecture=${HC_ARCH} \
  --compression=bz2 \
  --image-url=https://${CHANNEL}.release.flatcar-linux.net/${ARCH}-usr/${VERSION}/flatcar_production_hetzner_image.bin.bz2 \
  --labels os=flatcar,flatcar-channel=${CHANNEL} \
  --description flatcar-${CHANNEL}-${HC_ARCH}
```

Lastly, query the snapshot ID:
```
hcloud image list --type=snapshot --selector=os=flatcar
```
and edit `deploy.sh` to include it.


# Provision

Provisioning will use the hcloud token, too.
Make susre it's exported:

```
export HCLOUD_TOKEN=
```

Then run
```
./deploy.sh
```

to provision a cluster with 3 worker nodes.

Kubeconfig will be dumped into the local directory.
Run
```
watch -n1 kubectl --kubeconfig kubeconfig get nodes -o wide
```
to check on the nodes.


### Bonus track: In-place updates

Trigger an in-place update:
```
kubectl --kubeconfig kubeconfig apply -f ../../kured-dockerhub.yaml
```
then watch the nodes updating.
Might take a few minuted until the upgrade process starts.
