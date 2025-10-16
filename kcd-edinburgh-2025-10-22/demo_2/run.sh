#!../step

less -F sysupdate.yaml
./transpile.sh sysupdate.yaml
ls -la webserver
${LESSCOLORIZER} -l ini webserver/kubernetes-*.conf
less -F webserver/SHA256SUMS
{,} declare VIRTIOFSD_SOCK=${XDG_RUNTIME_DIR}/virtiofsd-$$.sock
{,} trap "kill %1 2>/dev/null; pkill -F '${VIRTIOFSD_SOCK}.pid' 2>/dev/null; rm -f '${VIRTIOFSD_SOCK}' '${VIRTIOFSD_SOCK}.pid'" EXIT
python -m http.server -d webserver >/dev/null &
{,} /usr/libexec/virtiofsd --socket-path="${VIRTIOFSD_SOCK}" --shared-dir .. --cache never --readonly --log-level off &
{,} declare MEMORY=2g
flatcar-vm/beta-amd64-current/flatcar_production_qemu_uefi.sh -i sysupdate.json -- -snapshot -nographic {,} -m "${MEMORY}" -object memory-backend-memfd,id=mem,size="${MEMORY}",share=on -numa node,memdev=mem -chardev socket,id=virtiofsd,path="${VIRTIOFSD_SOCK}" -device vhost-user-fs-pci,chardev=virtiofsd,tag=demo,queue-size=1024
