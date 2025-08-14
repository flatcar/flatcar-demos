## QEMU boot using u-boot and opensbi

```bash
# Script ran on Ubuntu 24.04 AMD64

# Download Flatcar image, fw_jump.bin, uboot.elf from the release page

# the fw_jump.bin, uboot.elf can be gotten by installing opensbi - `sudo apt install opensbi`. Paths:
# /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.bin
# /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \

# qemu-system-riscv64 can be installed using `sudo apt install qemu-system`

IMAGE_PATH="flatcar_production_qemu_uefi_image.img"

qemu-system-riscv64 \
 -machine virt -nographic -m 2048 -smp 4 \
 -bios fw_jump.bin \
 -kernel uboot.elf \
 -device virtio-net-device,netdev=eth0 -netdev user,id=eth0 \
 -device virtio-rng-pci \
 -drive file=$IMAGE_PATH,if=virtio \
 -vnc :1 \
 -serial mon:stdio \
 -device VGA \
 -device qemu-xhci,id=xhci -device usb-kbd,bus=xhci.0

# After the QEMU VM starts:
# start a VNC connection to the :1 VNC port
# Execute the following u-boot commands
# load virtio 0:1 $kernel_addr_r /EFI/boot/grubriscv64.efi
# bootefi $kernel_addr_r
```

## QEMU boot using edk2 tianocore

```bash
IMAGE_PATH="flatcar_production_qemu_uefi_image.img"

# RISCV_VIRT_CODE and RISCV_VIRT_VARS downloadable from https://dev.gentoo.org/~chewi/distfiles/edk2-202411-1-riscv.xpak

qemu-system-riscv64 \
-machine virt,acpi=off -cpu rv64 \
-m 8192 -smp 16 \
-drive if=pflash,format=qcow2,unit=0,file=RISCV_VIRT_CODE.qcow2,readonly=on \
-drive if=pflash,format=qcow2,unit=1,file=RISCV_VIRT_VARS.qcow2 \
-device virtio-net-device,netdev=eth0 -netdev user,id=eth0 \
-device virtio-rng-pci \
-drive file=$IMAGE,format=raw,if=virtio \
-nographic -vnc :1 \
-serial mon:stdio \
-device virtio-gpu-pci \
-device qemu-xhci,id=xhci -device usb-kbd,bus=xhci.0

# Enter Boot Manager and boot from file
```

## Kubernetes

Kubernetes working and tested using k3s from https://github.com/CARV-ICS-FORTH/kubernetes-riscv64.

## Flatcar RISC-V build

### Docs:

  * https://github.com/ader1990/scripts/releases/tag/riscv-poc-07-jan-2025
  * https://github.com/flatcar/Flatcar/issues/1420
  * https://github.com/flatcar/scripts/pull/2485
  * https://github.com/ader1990/configs/blob/master/gentoo/Readme-RISCV.md
  * https://github.com/flatcar/flatcar-website/blob/chewi/new-cpu-architecture/content/docs/latest/reference/developer-guides/new-cpu-architecture.md#porting-flatcar-itself
  * https://github.com/flatcar/scripts/commits/chewi/arm64-sdk/
  * https://github.com/flatcar/scripts/pull/2093#issuecomment-2219974002

### Prepare build machine

```bash
# needed for running risc-v binaries in emulated mode
sudo apt install qemu-user-static
```

### Prepare flatcar/scripts code:

  * add riscv-usr board
  * add riscv gentoo profile
  * fix packages masks where needed
    * https://github.com/flatcar/scripts/blob/chewi/riscv/generate_unstable_mask
    * bash generate_unstable_mask > sdk_container/src/third_party/coreos-overlay/profiles/coreos/riscv/package.mask
  * fix packages build where needed

### Boostrap SDK

```bash
git clone ader1990/scripts
cd scripts
git checkout -b ader1990/riscv-poc-v2

# add riscv-usr board
# add riscv gentoo profile
# fix packages masks where needed
# grep -r KEYWORDS sdk_container/src/third_party/prefix-overlay/ | grep "amd64" | grep -v '~amd64' | grep -v '~riscv' | awk -F: '{print $1}' | xargs sed -i 's/KEYWORDS="a.*/KEYWORDS="amd64 arm64 riscv"/g'
# grep -r KEYWORDS sdk_container/src/third_party/coreos-overlay/ | grep "amd64" | grep -v '~amd64' | grep -v '~riscv' | awk -F: '{print $1}' | xargs sed -i 's/KEYWORDS="a.*/KEYWORDS="amd64 arm64 riscv"/g'
./setup_board --board="riscv-usr" --binhost="/build/riscv-usr" --force
./build_packages --board riscv-usr
# after failure of setup_board and build_packages
bash generate_unstable_mask riscv-usr > sdk_container/src/third_party/coreos-overlay/profiles/coreos/riscv/package.mask

./run_sdk_container -U -t
# inside the sdk container
sudo ./bootstrap_sdk
# INFO    bootstrap_sdk: SDK ready: /mnt/host/source/src/build/catalyst/builds/flatcar-sdk/flatcar-sdk-amd64-4187.0.0+nightly-20241217-2100-1-ged15c4c4e0.tar.bz2
# INFO    bootstrap_sdk: Elapsed time (bootstrap_sdk): 370m15s

sudo cp  /mnt/host/source/src/build/catalyst/builds/flatcar-sdk/flatcar-sdk-amd64-*tar.bz2 .
ls -liath flatcar-sdk-amd64-*tar.bz2
# 8186460 -rw-r--r-- 1 root root 1.6G Dec 20 07:27 flatcar-sdk-amd64-4187.0.0+nightly-20241217-2100-1-ged15c4c4e0.tar.bz2

exit 0

# outside the dev container
./build_sdk_container_image flatcar-sdk-amd64-*.tar.bz2

# run_sdk_container using the all flatcar sdk docker image resulted

./build_packages --board riscv-usr

# fix rust packages builds
sudo cp /usr/riscv64-cros-linux-gnu/usr/lib64/Scrt1.o /usr/lib/gcc/riscv64-cros-linux-gnu/14/
sudo cp /usr/riscv64-cros-linux-gnu/usr/lib64/crt* /usr/lib/gcc/riscv64-cros-linux-gnu/14/

# python 311 failed because it could not build _ctypes
emerge-riscv-usr sys-apps/systemd
# retry
emerge-riscv-usr sys-apps/systemd

# qemu emulation running
# u-boot does not know to boot from the second partition where the grub is
load virtio 0:1 $kernel_addr_r /EFI/boot/grubriscv64.efi
bootefi $kernel_addr_r


```

### QEMU with other Operating Systems (great to start with)

Links:

  * https://github.com/u-boot/u-boot/blob/master/doc/board/emulation/qemu-riscv.rst
  * https://patchwork.kernel.org/project/linux-riscv/cover/20240601150411.1929783-1-sunilvl@ventanamicro.com/
  * https://lore.kernel.org/lkml/20240415170113.662318-1-sunilvl@ventanamicro.com/

Ubuntu host:

```bash
sudo apt-get update
sudo apt-get install opensbi qemu-system-misc u-boot-qemu
```

Ubuntu VM:

  * https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.1-preinstalled-server-riscv64.img.xz
  * https://wiki.ubuntu.com/RISC-V/QEMU

```bash
wget https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.1-preinstalled-server-riscv64.img.xz

unxz ubuntu-24.04.1-preinstalled-server-riscv64.img.xz

qemu-system-riscv64 \
 -machine virt -nographic -m 2048 -smp 4 \
 -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.bin \
 -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
 -device virtio-net-device,netdev=eth0 -netdev user,id=eth0 \
 -device virtio-rng-pci \
 -drive file=ubuntu-24.04-preinstalled-server-riscv64.img,format=raw,if=virtio \
 -vnc :1 \
 -serial stdio -device VGA \
 -device qemu-xhci,id=xhci -device usb-kbd,bus=xhci.0

# user/pass
# ubuntu:ubuntu
```

Fedora VM:

  * https://fedoraproject.org/wiki/Architectures/RISC-V/QEMU
  * https://dl.fedoraproject.org/pub/alt/risc-v/testing/f41/cloud/Fedora.riscv64-41.qcow2

```bash
wget https://dl.fedoraproject.org/pub/alt/risc-v/testing/f41/cloud/Fedora.riscv64-41.qcow2

qemu-system-riscv64 \
 -machine virt -nographic -m 2048 -smp 4 \
 -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.bin \
 -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
 -device virtio-net-device,netdev=eth0 -netdev user,id=eth0 \
 -device virtio-rng-pci \
 -drive file=Fedora.riscv64-41.qcow2,format=qcow2,if=virtio \
 -vnc :2 \
 -serial stdio -device VGA \
 -device qemu-xhci,id=xhci -device usb-kbd,bus=xhci.0

# user/pass
# root:fedora
```
