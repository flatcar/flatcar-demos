
## Nvidia demo

```yaml
# config.ign
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/flatcar/nvidia-metadata
      mode: 0644
      contents:
        inline: |
          NVIDIA_DRIVER_VERSION=535.183.01
    - path: /etc/extensions/nvidia_runtime.raw
      mode: 0644
      contents:
        source: https://github.com/flatcar/sysext-bakery/releases/download/latest/nvidia_runtime-v1.16.2-x86-64.raw
```

Custom IOMMU Flatcar qemu wrapper:

```bash
IOMMU_GPU=01:00.0
IOMMU_GPU_AUDIO=01:00.1

VIRSH_GPU_VIDEO=pci_0000_01_00_0
VIRSH_GPU_AUDIO=pci_0000_01_00_1

virsh nodedev-detach $VIRSH_GPU_VIDEO
virsh nodedev-detach $VIRSH_GPU_AUDIO

VBIOS=vbios.rom

case "${VM_BOARD}" in
    amd64-usr)
        # Default to KVM, fall back on full emulation
        qemu-system-x86_64 \
            -name "$VM_NAME" \
            -m ${VM_MEMORY} \
            -cpu host,hidden=on,kvm=off,-hypervisor,hv_relaxed,hv_spinlocks=0x1fff,hv_time,hv_vapic,hv_vendor_id=0123456789ab \
            -device vfio-pci,host=$IOMMU_GPU,multifunction=on,x-vga=on,romfile=$VBIOS \
            -device vfio-pci,host=$IOMMU_GPU_AUDIO \
            -netdev user,id=eth0,hostfwd=tcp::"${SSH_PORT}"-:22,hostname="${VM_NAME}" \
            -device virtio-net-pci,netdev=eth0 \
            -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0 \
            "$@"
        ;;
```

Script to unload Nvidia drivers:

```bash
unload_nvidia_drivers.sh
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
modprobe -r drm_kms_helper
modprobe -r nvidia
modprobe -r i2c_nvidia_gpu
modprobe -r drm
modprobe -r nvidia_uvm
modprobe -r nvidia
```

Start the Flatcar image:

```bash
./flatcar_production_qemu.sh -i config.ign -- -nographic -m 8192
```

In the Flatcar instance, run:

```bash
journalctl -u nvidia -f
nvidia-smi
 
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi
 
docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
 
docker exec -it ollama ollama pull deepseek-r1:7b
 
docker exec -it ollama ollama run deepseek-r1:7b What do you think about Flatcar linux in one line?
 
```

## Hyperlight demo

Start a vanilla Flatcar image:

```bash
./flatcar_production_qemu.sh -nographic
```

In the Flatcar instance, run:

```bash
# use https://hub.docker.com/r/alexpilotti/hyperlight_demo

docker run -ti --rm --device=/dev/kvm --name hyperlight-demo alexpilotti/hyperlight_demo \
    /bin/bash -c "time ./target/release/examples/hello-world"
```