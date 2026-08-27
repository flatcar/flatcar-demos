# A Local, Ephemeral Kubernetes Cluster built from plain Flatcar

The demo cluster features a control plane node and an arbitrary number of worker nodes.
Main features of this demo:

1. Uses plain Flatcar, basic declarative Butane / Ignition configuration.
   - See [control.yaml.tmpl](control.yaml.tmpl) for the control plane configuration, and
   - [worker.yaml.tmpl](worker.yaml.tmpl) for the worker nodes.
2. The cluster is completely ephemeral.
   Tearing down the VMs will discard all state, new clusters will be pristine.
3. No change will be written to the QEmu disk image files on the host.
   This allows us to spawn the control plane and all workers from the same disk image.

### Prerequisites / Host Requirements

1. Docker
2. `qemu-system-x86_64` or `qemu-system-arm64`, depending on the architecture chosen for the cluster VMs (defaults to x86-64)
3. `bash`, `sed`, `curl`, and `kubectl`

### Concepts

Flatcar VMs are configured declaratively, via YAML files.
The configuration is applied during provisioning, very early at first boot.
```
.--------- Host system (e.g. your laptop) ---------.
|                                                  |
| .-----------------.                              | 
| | QEmu disk image | ---.       .-------------.   |
| `-----------------´     \      |  Configured |   |
|                          :===> |    VM       |   |
|  .----------------.     /      `-------------´   |
|  | VM YAML config | ---´                         |
|  `----------------´                              |
`--------------------------------------------------´
```

The demo will use the above concept to create a control plane and worker nodes from pre-defined YAML templates.

```
.--------- Host system (e.g. your laptop) ----------------------.
|                                                               |
| .-----------------.                      .---------.          |
| | QEmu disk image | ---.       .----------. worker |          |
| `-----------------´     \      |  control |  node  |          |
|                          :===> |   plane  |   vm   |---.      |
|  .----------------.     /      |    VM    |--------´r  |      |
|  | VM YAML config | ---´       `----------´------.de   |      |
|  `----------------´                ^   |  worker |M    |      |
|                                    |   |   node  |-----´      |
|                        .-----------´   |    VM   |            |
|                       /                `---------´            |
|   kubectl <----------´                                        |
`---------------------------------------------------------------´
```

### Stages

1. First, we download the most recent Flatcar Alpha release:
  - `./demo.sh fetch`
  - This will download the qemu image, UEFI code, and a wrapper script to start Flatcar.
2. Now, we can boot the control plane:
  - `./demo.sh control`
  - This will generate `control.yaml` from [control.yaml.tmpl](control.yaml.tmpl), transpile it to `control.json`, and boot the VM with that config.
3. Now we need to initialise the control plane, install a CNI and fetch the `kubeconfig`.
  - `./demo.sh init`
  - Now our cluster is operational; we can check with `./demo.sh kc get nodes`.
4. We can now add arbitrary worker nodes.
  - `./demo.sh worker 1`
  - `./demo.sh worker 2`
  - `./demo.sh worker 3`

The cluster is now ready to be used.

### A note on Networking

This demo uses QEmu's UDP multicast networking feature to build a second, "private" network for the Kubernetes cluster VMs.
All Kubernetes internal traffic will use this network.
The network is not visible from the host; QEmu will use a UDP multi-cast bus on the host to distribute network data across the VMs.
Additionally, the VMs use QEmu's default user network to communicate with the host; e.g. for `ssh` and `kubectl` access.

```
.--------- Host system (e.g. your laptop) ----------------------.
|                                                               |
|                    .---------.      _____                     |
| ssh <=====> [:2001]| control |     [     ]                    |
|                    |  plane  | <=> [  U  ]                    |
| kubectl <=> [:6443]|   VM    |     [  D  ]                    |
|                    `---------´     [  P  ]                    |
|                    .---------.     [     ]                    |
| ssh <=====> [:2002]| worker  | <=> [  M  ]                    |
|                    |   VM    |     [  C  ]                    |
|                    `---------´     [  A  ]                    |
|                    .---------.     [  S  ]                    |
| ssh <=====> [:2003]| worker  | <=> [  T  ]                    |
|                    |   VM    |     [_____]                    |
|                    `---------´                                |
`---------------------------------------------------------------´
```

### Bonus track: In-place updates

We can set the Kubernetes version in `demo.sh`, at the top.
Older versions can be updated in-place.

Trigger an in-place update:
```
./demo.sh kc apply -f kured-dockerhub.yaml
```
then watch the nodes updating.
Might take a few minutes until the upgrade process starts.
