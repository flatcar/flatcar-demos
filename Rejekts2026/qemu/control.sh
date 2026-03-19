
cp ../control.yaml .
../../transpile.sh control.yaml

./flatcar_production_qemu_uefi.sh -i control.json -f 6443:6443 -p 2000 \
    -nographic -snapshot  -device e1000,netdev=n1,mac=52:54:00:12:34:00 \
    -netdev socket,id=n1,mcast=230.0.0.1:1234   
