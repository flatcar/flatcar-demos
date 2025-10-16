#!../step

less -F kubernetes-worker1.yaml
./transpile.sh kubernetes-worker1.yaml
{,} declare VIRTIOFSD_SOCK=${XDG_RUNTIME_DIR}/virtiofsd-$$.sock
{,} trap "kill %1 2>/dev/null; pkill -F '${VIRTIOFSD_SOCK}.pid' 2>/dev/null; rm -f '${VIRTIOFSD_SOCK}' '${VIRTIOFSD_SOCK}.pid'" EXIT
{,} /usr/libexec/virtiofsd --socket-path="${VIRTIOFSD_SOCK}" --shared-dir .. --cache never --readonly --log-level off &
{,} declare MEMORY=4g
flatcar-vm/beta-amd64-current/flatcar_production_qemu_uefi.sh -i kubernetes-worker1.json -p 2223 -- -snapshot -nographic -device virtio-net-pci,netdev=n1,mac=52:54:00:12:34:57 -netdev socket,id=n1,mcast=230.0.0.1:1234 {,} -m "${MEMORY}" -object memory-backend-memfd,id=mem,size="${MEMORY}",share=on -numa node,memdev=mem -chardev socket,id=virtiofsd,path="${VIRTIOFSD_SOCK}" -device vhost-user-fs-pci,chardev=virtiofsd,tag=demo,queue-size=1024
