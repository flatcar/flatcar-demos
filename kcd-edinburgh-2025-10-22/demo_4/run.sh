#!../step

source ./capz-demo.env
setup_kind_cluster
generate_capz_yaml
deploy_capz_cluster
kc_worker get nodes
kc_worker apply -f kured-dockerhub.yaml
less -F kured-dockerhub.yaml
watch 'NOHELP=true source ./capz-demo.env; kc_worker get nodes;'
cleanup
