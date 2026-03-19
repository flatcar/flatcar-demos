# Akamai

## Prerequisites: image uploaded and image ID available

If you haven't uploaded a Flatcar image to Akamai, this will need to be done first.
Make sure you're logged in with the Linode CLI, then run
```
./create-image.sh
```

then run
```
linode-cli images list --label "k8s-demo-flatcar-alpha"
```
until the image status is "available".


Lastly, get the image ID:
```
linode-cli images list --label "k8s-demo-flatcar-alpha" --json | jq -r '.[0].id'
```
and edit `deploy.sh` to include the image ID.

# Provision

Run
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
