## ClusterAPI demo on Azure

We're now going to fully automate the update process without any workload
disruption:
- detect staged updates
- evacuate the nodes
- reboot
- uncordon after re-join

And it's all done with a single `kubectl apply`.

This largely follows the automation in [CAPZ-demo](../../CAPZ-demo) so go check
that out first.

### Preparation

The below should be run before the presentation starts; it will create a
cluster on Azure which we'll update using kured.

```bash
mkdir demo
cd demo

bash -i
source ../capz-demo.env

get_prerequisites
setup_kind_cluster
generate_capz_yaml
```

Now add the sysupdate enable patch
```bash
patch -p0 <../enable-updates.patch
```

The az command in `azure.env.template` currently creates a tenant w/o using
user identity, so we need to remove userIdentity from the cluster YAML:
```bash
patch -p0 <../fix-user-identity.patch
```

Deploy the new cluster
```bash
deploy_capz_cluster

kc_worker get nodes
```

### Update cluster via kured

Verify worker nodes are operational, check Kubernetes versions:
```bash
deploy_capz_cluster

kc_worker get nodes
```

When worker nodes are operational, initiate update
```bash
kc_worker apply -f kured-dockerhub.yaml
```

Watch the in-place update
```bash
watch 'NOHELP=true source ../capz-demo.env; kc_worker get nodes;'
```

While watching, talk through kured options
```bash
vim kured-dockerhub.yaml
```
