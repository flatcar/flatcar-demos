#!../step

less -F kubernetes-control.yaml
./transpile.sh kubernetes-control.yaml
{,} declare VIRTIOFSD_SOCK=${XDG_RUNTIME_DIR}/virtiofsd-$$.sock
{,} trap "kill %1 2>/dev/null; pkill -F '${VIRTIOFSD_SOCK}.pid' 2>/dev/null; rm -f '${VIRTIOFSD_SOCK}' '${VIRTIOFSD_SOCK}.pid'" EXIT
python -m http.server -d webserver &>/dev/null &
{,} /usr/libexec/virtiofsd --socket-path="${VIRTIOFSD_SOCK}" --shared-dir .. --cache never --translate-uid map:500:$(id -u):1 --translate-gid map:500:$(id -g):1 --log-level off &
{,} declare MEMORY=4g
flatcar-vm/beta-amd64-current/flatcar_production_qemu_uefi.sh -i kubernetes-control.json -f 6443:6443 -- -snapshot -nographic -device virtio-net-pci,netdev=n1,mac=52:54:00:12:34:56 -netdev socket,id=n1,mcast=230.0.0.1:1234 {,} -m "${MEMORY}" -object memory-backend-memfd,id=mem,size="${MEMORY}",share=on -numa node,memdev=mem -chardev socket,id=virtiofsd,path="${VIRTIOFSD_SOCK}" -device vhost-user-fs-pci,chardev=virtiofsd,tag=demo,queue-size=1024
