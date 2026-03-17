#!/mnt/step

ls -l ~/.kube
kubectl get nodes
kubectl apply -f /mnt/demo_3/calico.yaml
kubectl get nodes
kubectl get pods -n kube-system
kubeadm token list
printf "[Service]\nEnvironment=KUBEADM_TOKEN=%s\n" "$(kubeadm token list -o json | jq -r .token)" > /mnt/demo_3/token.conf
watch kubectl get nodes
