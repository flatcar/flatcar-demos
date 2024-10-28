# Cluster API Azure (CAPZ) with Flatcar

This demo is divided into two sections:
* [Cluster API Azure using Flatcar sysext template](#cluster-api-azure-using-flatcar-sysext-template)
* Cluster API Azure using AKS (mixing Ubuntu and Flatcar nodes)

## Cluster API Azure using Flatcar sysext template

In this demo, you will learn how to create a Kubernetes cluster using Azure resources and powered by Flatcar nodes using the systemd-sysext approach. This is inspired from: https://capz.sigs.k8s.io/getting-started

### Requirements

:warning: This is done on a fresh Azure account for demo purposes to avoid interfering with any existing components

* Azure account with an Azure Service Principal
* A management cluster (e.g any existing Kubernetes cluster)
* `clusterctl` and `yq` up-to-date and available in the `$PATH`

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

Now, you can generate the workload cluster configuration:

_Notes_:
* at this time, the CAPZ Flatcar sysext PR is still opened (https://github.com/kubernetes-sigs/cluster-api-provider-azure/pull/4575) which means that `--infrastructure azure --flavor flatcar-sysext` must be replaced by `--from /path/to/flatcar-sysext/template.yaml`
* Kubernetes version must match sysext-bakery [releases](https://github.com/flatcar/sysext-bakery/releases/tag/latest)

```bash
clusterctl generate cluster capi-quickstart \
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
