set -x
./flatcar_production_qemu_uefi.sh -i ../kubernetes-worker1.json -p 2223 -nographic -snapshot  \
	-device e1000,netdev=n1,mac=52:54:00:12:34:57 -netdev socket,id=n1,mcast=230.0.0.1:1234   
