# Cluster API Azure (CAPZ) with Flatcar


This demo is divided into three sections:
* Automated, scripted set-up of a ClusterAPI worker cluster on Azure, including live in-place updates
* Full manual walk-through of setting up [Cluster API Azure using Flatcar sysext template](#manual-cluster-api-azure-using-flatcar-sysext-template)
* Full manual walk-through of setting up Cluster API Azure using AKS (mixing Ubuntu and Flatcar nodes) (TBD)

## Automated set-up of a Cluster API demo cluster on Azure

The automation will lead you through all steps necessary for creating an Azure Cluster API cluster from scratch.
It will also take care of creating a local management cluster, and generally requires very few prerequisites.
The automation is best suitable if you want to start from scratch, and/or if you need a quick throw-away CAPZ cluster.

**tl;dr**

```bash
git clone https://github.com/flatcar/flatcar-demos.git
cd flatcar-demos/CAPZ-sysext
mkdir demo
cd demo

cp ../cluster-template-flatcar-sysext.yaml .
cp ../azure.env.template azure.env
vim azure.env       # fill in account information

bash -i
source ../capz-demo.env

get_prerequisites
setup_kind_cluster
generate_capz_yaml

patch -p0 ../fix-user-identity.patch

deploy_capz_cluster

kc_worker get nodes -o wide
```

After worker nodes are operational
```bash
kc_worker apply -f kured-dockerhub.yaml
```

Watch the in-place update
```bash
watch 'source ../capz-demo.env; kc_worker get nodes -o wide;'
```

### Prerequisites

An Azure account and an active subscription.
We will create an RBAC account for use by the Cluster API automation, so you'll need access to the Active Directory of your account.

### Prepare the demo

1. Clone the flatcar-demos repo and change into the "CAPZ-sysext" subdirectory of the repo.
   ```bash
   git clone https://github.com/flatcar/flatcar-demos.git
   cd flatcar-demos/CAPZ-sysext
   ```
2. Create a sub-directory `demo` to work in (will be ignored as per the repo's `.gitgnore`).
   ```bash
   mkdir demo
   cd demo
   ```
3. Copy the upper directory's `azure.env.template` to `azure.env`:
   ```bash
   cp ../azure.env.template azure.env
   ```
4. Edit `azure.env` and fill in the required variables.
   Comments in the file will guide you through creating an Active Directory RBAC account to use for the demo if you don't have one available.
   You can also optionally configure an SSH key to log in to the worker cluster's control plane node.

You should now have:
- the automation available locally from the flatcar-demos repository you've cloned
- a `demo` sub-directory with `azure.env` with data to access the Azure account you want to use for the demo

### Run the demo

The demo will first create a local KIND cluster and install the Cluster API Azure provider.
It will then generate a cluster configuration for the workload cluster on Azure, and apply it.
It will wait for the Azure cluster to come up, then give control back to you.

You can interact with the KIND management cluster by using `kc_mgmt <kubectl command>`, and with the workload cluster via `kc_worker <kubectl command>`.
`kc_mgmt` and `kc_worker` are just wrappers around kubectl with the respective `kubeconfig` set.

1. Start a new shell and source the automation
   ```bash
   bash -i
   source ../capz-demo.env
   ```
2. Check prerequisites. This will download `kind` and `helm` for local use.
   ```bash
   get_prerequisites
   ```
3. Set up the KIND (Kubernetes-IN-Docker") cluster for local use.
   ```bash
    setup_kind_cluster
   ```
4. Install the Azure provider and generate the Cluster API Azure cluster configuration.
   ```bash
   generate_capz_yaml
   ```
5. If you want to demo live updates and start systemd-sysupdate by default,
   apply the following patch to add this to the cluster YAML:
   ```bash
    patch -p0 ../enable-updates.patch
   ```
6. We need to patch the cluster YAML as the "az ad sp" command in the
   env template does not create a user identity. This can be skipped when the
   command has been updated to create the correct rbac.
   ```bash
    patch -p0 ../fix-user-identity.patch
   ```
7. Provision the ClusterAPI Azure workload cluster.
   This will apply the cluster configuration to the management cluster, which will start the provisioning process on Azure.
   It will then wait until the cluster is fully provisioned, and install cluster add-ons (Calico and the external cloud provider)
    to make the cluster operational.
   Provisioning the cluster can take some time.
   You can watch the resources being created in the `flatcar-capi-demo-azure` resource group used by the automation in the Azure portal.
   ```bash
   deploy_capz_cluster
   ```

You can now interact with the workload cluster using `kc_worker`, a simple wrapper around `kubectl`.

#### Live in-place Kubernetes updates

The `cluster-template-flatcar-sysext.yaml` shipped with this repo has in-place Kubernetes updates enabled via `systemd-sysupdate`.
An update should already have been staged on the workload cluster (happens almost immediately after provisioning).
The `systemd-sysupdate` configuration will also have created a flag file on the node to signal a need for reboot: `/run/reboot-required`.

To demo live in-place Kubernetes updates, all we need to do is to provision KureD to the workload cluster.
A suitable kured configuration is shipped with the repository.

Run
```bash
kc_worker apply -f ../kured-dockerhub.yaml
```
to start the process.

KureD will detect the flag file and evacuate and reboot the nodes, one after another.
You can watch the process:
```bash
watch 'source ../capz-demo.env; kc_worker get nodes;'
```


## Manual Cluster API Azure using Flatcar sysext template

In this demo, you will learn how to create a Kubernetes cluster using Azure resources and powered by Flatcar nodes using the systemd-sysext approach. This is inspired from: https://capz.sigs.k8s.io/getting-started

### Requirements

:warning: This is done on a fresh Azure account for demo purposes to avoid interfering with any existing components

* Azure account with an Azure Service Principal
* A management cluster (e.g any existing Kubernetes cluster)
* `clusterctl` and `yq` up-to-date and available in the `$PATH`

Contrary to the automated set-up, which creates a local KIND cluster for management, the below assumes you already run a management cluster.

### Initialize the management cluster

We first need to export some variables and create some secrets before initializing the management cluster:
```bash
export AZURE_SUBSCRIPTION_ID=a77585be-...
export EXP_KUBEADM_BOOTSTRAP_FORMAT_IGNITION=true
export AZURE_TENANT_ID="<Tenant>"
export AZURE_CLIENT_ID="<AppId>"
export AZURE_CLIENT_ID_USER_ASSIGNED_IDENTITY=$AZURE_CLIENT_ID # for compatibility with CAPZ v1.16 templates
export AZURE_CLIENT_SECRET="<Password>"
export AZURE_RESOURCE_GROUP="capz-demo"
export AZURE_LOCATION="centralus"
```

From now, you can just copy-paste:
```bash
# Settings needed for AzureClusterIdentity used by the AzureCluster
export AZURE_CLUSTER_IDENTITY_SECRET_NAME="cluster-identity-secret"
export CLUSTER_IDENTITY_NAME="cluster-identity"
export AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE="default"

# Create a secret to include the password of the Service Principal identity created in Azure
# This secret will be referenced by the AzureClusterIdentity used by the AzureCluster
kubectl create secret generic "${AZURE_CLUSTER_IDENTITY_SECRET_NAME}" --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" --namespace "${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}"

# Finally, initialize the management cluster
clusterctl init --infrastructure azure
```

### Create the workload cluster

Now, you can generate the workload cluster configuration:

_Notes_:
* at this time, the CAPZ Flatcar sysext PR is still opened (https://github.com/kubernetes-sigs/cluster-api-provider-azure/pull/4575) which means that `--infrastructure azure --flavor flatcar-sysext` must be replaced by `--from /path/to/flatcar-sysext/template.yaml`
* Kubernetes version must match sysext-bakery [releases](https://github.com/flatcar/sysext-bakery/releases/tag/latest)

```bash
clusterctl generate cluster ${AZURE_RESOURCE_GROUP} \
  --infrastructure azure \
  --kubernetes-version v1.31.1 \
  --control-plane-machine-count=3 \
  --worker-machine-count=3 \
  --flavor flatcar-sysext \
  > "${AZURE_RESOURCE_GROUP}.yaml"
yq -i "with(. | select(.kind == \"AzureClusterIdentity\"); .spec.type |= \"ServicePrincipal\" | .spec.clientSecret.name |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAME}\" | .spec.clientSecret.namespace |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}\")" "${AZURE_RESOURCE_GROUP}.yaml"
kubectl apply -f "${AZURE_RESOURCE_GROUP}.yaml"
```

After a few minutes, the cluster should be available using latest Flatcar version available on the Azure gallery.

```bash
clusterctl get kubeconfig "${AZURE_RESOURCE_GROUP}" > "${AZURE_RESOURCE_GROUP}.kubeconfig"
kubectl --kubeconfig "${AZURE_RESOURCE_GROUP}.kubeconfig" get nodes -o wide
```

Of course, the nodes will not be ready while CNI and CCM are not deployed, here's a simple example using Calico:
```
# CNI
export IPV4_CIDR_BLOCK=$(kubectl get cluster "${AZURE_RESOURCE_GROUP}" -o=jsonpath='{.spec.clusterNetwork.pods.cidrBlocks[0]}')
helm repo add projectcalico https://docs.tigera.io/calico/charts && \
helm install calico projectcalico/tigera-operator --version v3.26.1 -f https://raw.githubusercontent.com/kubernetes-sigs/cluster-api-provider-azure/main/templates/addons/calico/values.yaml --set-string "installation.calicoNetwork.ipPools[0].cidr=${IPV4_CIDR_BLOCK}" --namespace tigera-operator --create-namespace
# CCM
helm install --repo https://raw.githubusercontent.com/kubernetes-sigs/cloud-provider-azure/master/helm/repo cloud-provider-azure --generate-name --set infra.clusterName=${AZURE_RESOURCE_GROUP} --set "cloudControllerManager.clusterCIDR=${IPV4_CIDR_BLOCK}" --set-string "cloudControllerManager.caCertDir=/usr/share/ca-certificates"
```
