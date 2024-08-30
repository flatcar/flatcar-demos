# ClusterAPI OpenStack Flatcar Sysext demo

Tools for demo-ing Flatcar deployments on ClusterAPI OpenStack using Kubernetes sysexts from the bakery.

The main demo is implemented in an env file which should be sourced (`capo-demo.env`).
The env file provides a number of helper functions to set up and run a Flatcar OpenStack deployment.
It will set up a Kind cluster locally (one node, control plane only) to manage ClusterAPI OpenStack
worker clusters, then spawn a worker cluster on OpenStack.

## tl;dr

Put `clouds.yaml` and `openstack.env` (see prerequisites) into your working directory.

```
bash -i
source capo-demo.env

get_prerequisites
setup_kind_cluster
generate_capo_yaml

# start sshuttle before continuing (the script will pause for you).
deploy_capo_cluster
```

Now you can use `kc_worker` to interact with the OpenStack worker cluster and `kc_mgmt` to interact with
the local Kind management cluster.

`deploy_capo_cluster` will pause and ask you to start an `sshuttle` connection to your OpenStack server.
This is required for isolated environments that are not accessible from the internet.

To clean up everything, run
```
cleanup
```

## Source `capo-demo.env`

Before going any further, start a shell, change into your demo working directory, and `source capo-demo.env`.

## Prerequisites

The script requires an existing OpenStack server to deploy workload clusters to, and a corresponding
`clouds.yaml` file with credentialy to access that server.
That file can be acquired via the OpenStack web interface by opening "API Access" and then selecting
"Download OpenStack RC file".

The automation requires a number of prerequisite commands to be installed on the system:
- `kubectl`
- `yq`
- `git`
- `wget`
- `sshuttle`
Consult your distro's package management on getting these tools.

The script needs to know about a number of OpenStack settings for running the demo.
These are defined in `openstack.env`.
Simply `cp openstack.env.template openstack.env` and fill in the information.

Lastly, run
```
get_prerequisites
```
to check system prerequisites and to download `kind`, `clusterctl`, and git clone `cloud-provider-openstack`.

## Set up and start a local Kind cluster

Run
```
setup_kind_cluster
```
to start a local Kind cluster.
The kubeconfig for this cluster will be stored in the current directory.
The setup also initialises the kind cluster to be a management cluster for OpenStack CAPI.

## Generate OpenStack worker cluster configuration

Run
```
generate_capo_yaml
```
to generate and kustomize a CAPI cluster configuration for our OpenStack configuration.

### Make local edits before provisioning the cluster

You can edit `flatcar-capi-demo-openstack.yaml` with your favourite editor to make changes to the cluster before it is provisioned in the next step.
This is useful for e.g. enabling the update feature, picking different kubernetes sysexts, etc.

## Provision the OpenStack worker cluster

Run
```
deploy_capo_cluster
```
to deploy the worker cluster.
The command will ask you to start an sshuttle connection to your OpenStack server.
This is required for isolated environments that are not accessible from the internet.

Run `sshuttle -r root@<openstack-server-ip> <openstack-network-and-netmask> -l 0.0.0.0` in a separate console,
then press return so the script continues.

## Run your Demo

This is what you came here for - you now have an OpenStack CAPI cluster deployed and you can demo stuff.

Use `kc_worker` to `kubectl` to your worker cluster.

How about investigating your node state (versions and the like)?
```
kc_worker get nodes -o wide
```

If you were planning to demo updates you might want to deploy kured:
```
kc_worker apply -f kured-dockerhub.yaml
```
This file is shipped with this repo and modifies the default kured YAML:
- check interval is set to 10 seconds instead of several minutes
- lock release is set to 0, so reboot locks are relased as soon as the node is back
- a custom reboot sentinel command is used as kured's regular detection seems to be broken on Flatcar

Also, this `cluster.yaml` systemd unit drop-in might be handy to reduce the
sysupdate timer after boot to 1min (from its 15min default), and then every 10 seconds:
Add this to `systemd: units:` **in both the control plane and worker node sections**:
```
              - name: systemd-sysupdate.timer
                dropins:
                  - name: bootcheck.conf
                    contents: |
                      [Timer]
                      OnBootSec=1min
                      OnUnitActiveSec=10s
                      RandomizedDelaySec=1s
```
and don't forget to set `systemd-sysupdate.timer` to `enabled:true`.

Check kured's status after the deployment with
```
kc_worker get pods --all-namespaces -o wide | grep kured | grep flatcar-capi-demo-openstack-control-plane
```
and then
```
kc_worker logs -n kube-system -f <kured-pod>
```
and on a separate terminal
```
while true; do kc_worker get nodes -o wide; echo; sleep 1; done
```

## Standalone (non-CAPI) Kubernetes sysext deployment and update

A standalone Butane config is available in `standalone.yaml` to demo Kubernetes sysext provisioning in a local VM.
