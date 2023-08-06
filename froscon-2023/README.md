# Flatcar Container Linux Developer Workshop - FrOSCon 2023

In this workshop, we'll learn how to build, modify, extend, and test Flatcar Container Linux.

Flatcar is a purely image-based distribution - shipped as an image, and updated as an image.
It does not include a package manager and is not meant to be extended after provisioning.

Contrary to general purpose Linux distributions, Flatcar solely focuses on running containers.
- Flatcar is configured declaratively, *before deployment* (there's a separate workshop focusing on deployment and operations).
- No interactive configuration is necessary after provisioning.
It is usually used for automated deployments of larger clusters, e.g. Kubernetes.

The SDK is used to build images.
It is based on Gentoo, so builds are always from source (though binary packages can be cached).
The distribution repository contains build instructions for all packages (Gentoo ebuild files).
The SDK is containerised and self-contained; a wrapper script makes the distro repo w/ ebuilds available inside the container.

The workshop roughly follows the tutorial at https://www.flatcar.org/docs/latest/reference/developer-guides/sdk-modifying-flatcar/.

## Agenda

1. Start the SDK and build a pristine image
2. SDK basics and concepts (while your machine is busy building)
3. Make a modification to the image - add an application
4. Rebuild the image
5. Profit.

## Prerequisites

1. x86-64 Laptop (Linux) with internet access; docker, qemu, and git pre-installed
   1. 4 threads / 2 cores minimum
   2. 4GB RAM minimum (8GB or more are better)
   3. 29GB free HDD/SSD/NVME storage (SSD/NVME recommended)

### Preparation

For this demo, we will work with Alpha release 3665.0.0.
All Flatcar releases are listed here: https://www.flatcar.org/releases .

------

**We'll now give your computer some work to do - building a Flatcar OS image - while we cover the SDK basics.**

------

**Clone the Flatcar distro repository and check out the Alpha release tag.**
```shell
git clone https://github.com/flatcar/scripts.git flatcar-distro
cd flatcar-distro
git checkout alpha-3665.0.0
```

**Load the pre-built SDK container into your local Docker image repository.**
Your tutor should have provided you with a pre-built SDK container image with all packages included.
```shell
pigz -d -c flatcar-sdk-amd64-alpha-3665.0.0.tgz | docker load
```
(If pigz is not available plain `gunzip` should also work, though it won't pararellise decompression)


### Force the wrapper script to use the local container image

Edit `run_sdk_container` and remove "docker pull" so our pre-built SDK is used (delete lines 111 to 122).
Alternatively, apply
```diff
idiff --git a/run_sdk_container b/run_sdk_container
index b34b7958c1..42b774a703 100755
--- a/run_sdk_container
+++ b/run_sdk_container
@@ -108,19 +108,6 @@ if [ -z "$stat" ] ; then
 
     gpg_volumes=$(gnupg_ssh_gcloud_mount_opts)
 
-    if [ -z "$custom_image" ]; then
-	(
-            source ci-automation/ci_automation_common.sh
-            docker_image_from_registry_or_buildcache "flatcar-sdk-${arch}" "${docker_sdk_vernum}"
-	)
-    else
-        # We could split the container_image_name in parts to call docker_image_from_registry_or_buildcache
-        # bur for now just try to ensure that we use the latest image if using a container registry,
-        # for the tar-ball-imported images we rely on the ci-automation scripts to call
-        # docker_image_from_registry_or_buildcache explicitly.
-        $docker pull "${container_image_name}" || true
-    fi
-
     $docker create $tty -i \
        -v /dev:/dev \
        -v "$(pwd)/sdk_container:/mnt/host/source/" \
```


**Start the SDK container.**
```shell
./run_sdk_container -t
```
The SDK container should start right away, i.e. w/o downloading additional container images.

#### I didn't get a pre-built SDK container image.

If you don't have a pre-built SDK with packages included, you'll need to start a plain SDK container, then build all packages.
Using `run_sdk_container` will automatically fetch the SDK container image for alpha-3665.0.0.
```shell
./run_sdk_container -t
./build_packages
```
followed by
```shell
docker commit flatcar-sdk-all-3665.0.0_os-alpha-3665.0.0 ghcr.io/flatcar/flatcar-sdk-all:3665.0.0
```

This will take some time - between 1 and 2 hours, depending on your machine.
(that's why there's a pre-built SDK container provided in the live workshop)

## Kick of a build of a pristine Flatcar image

We will now kick off an image build.
This should take between 15 and 30 minutes depending on your machine.
During this build we'll cover some background and SDK basics.

For the build to succeed we need to put SELinux into "permissive" mode.
That's because the image build script will loopback-mount the partition image, install packages, and the selinux-relabel the contents.
If the command
```shell
sudo getenforce
```
returns `Enforcing` we'll need to switch to "permissive":
```shell
sudo setenforce permissive
```

**In the SDK container, run**
```shell
./build_image
```

This should take between 10 and 30 minutes depending on the performance (CPU + storage I/O) of your system.

## SDK basics

While we bake our first image, let's cover some development basics.

### Directory structure

**What's in the distro repo?**
* `./` - mostly low-level build scripts for use inside of the SDK container. Also, SDK container wrapper scripts.
* `sdk_container/` - helper scripts for the SDK container as well as all package ebuilds
* `ci-automation/` - glue logic scripts for building and testing Flatcar in a CI

**Where are the ebuilds?**
```
./sdk_container/
   +---------src/
              +--third_party/
                      +------coreos-overlay/
                      +------portage-stable/
```

**List the application groups**
```shell
ls sdk_container/src/third_party/portage-stable
```
```shell
ls sdk_container/src/third_party/coreos-overlay
```

**List ebuilds of a single package (bash)**
```shell
ls sdk_container/src/third_party/portage-stable/app-shells/bash
```

**Check out an ebuild in your favourite editor**
```shell
vim sdk_container/src/third_party/portage-stable/app-shells/bash/bash-5.2_p15-r6.ebuild
```

Don't worry, there's no need to write ebuilds yourself (and this workshop doesn't cover that).
We'll import ebuilds from Gentoo.

### Check the release version we've checked out

**Flatcar release version**
```
cat sdk_container/.repo/manifests/version.txt
```
This version file determines (among other things) which SDK container release is started by `run_sdk_container`.

### The SDK container and the wrapper script

Now inspect `run_sdk_container` with your favourite editor.
```shell
vim run_sdk_container
```

On first run (or if the `version.txt` file changed), `run_sdk_container` will create a named instance of the SDK container image.
*This named instance will be re-used in subsequent calls of `run_sdk_container`.*
In other words, if you have intermediate work in the SDK container that work can be re-used in subsequent runs.
```shell
docker ps --all
```
should show:
```
3452401062d3   d2d28987e2be   "/bin/bash -l"   3 hours ago   Up 31 minutes             flatcar-sdk-all-3665.0.0_os-alpha-3665.0.0
```

To start with a clean new instance, run `docker container prune flatcar-sdk-all-3665.0.0_os-alpha-3665.0.0`, then run `run_sdk_container` again.

It's also worth noting the bind-mounts the wrapper script creates in the container, in line 124 - 128 of `run_sdk_container`:
```bash
    -v /dev:/dev \
    -v "$(pwd)/sdk_container:/mnt/host/source/" \
    -v "$(pwd)/__build__/images:/mnt/host/source/src/build" \
    -v "$(pwd):/mnt/host/source/src/scripts" \
```
This mounts the local distro directory (called "scripts" for legacy reasons), the `__build__` subdirectory, and the ebuild sources into the SDK container.

The wrapper script can be run multiple times on multiple consoles; it will use the same container image (it will `docker exec` into a running container).

### Inside the SDK

`run_sdk_container` will drop you right inside the flatcar-distro repository bind-mount.
You can use the script multiple times on multiple consoles; you'll end up in the same container.

**Start the SDK container.**
```shell
./run_sdk_container -t
```
```
sdk@flatcar-sdk-all-3665_0_0_os-alpha-3665_0_0 ~/trunk/src/scripts $ 
```

**Where am I?**
```shell
pwd
```
```
/home/sdk/trunk/src/scripts
```

**What is here?**
```shell
ls
```
```
CHANGELOG.md     bash_completion          build_packages             clean_loopback_devices  core_sign_update        jenkins            sdk_lib                      update_chroot
CONTRIBUTING.md  boot_nspawn              build_sdk_container_image  code-of-conduct.md      cros_workon             lib                set_official                 update_distfiles
DCO              bootstrap_sdk            build_sysext               common.sh               find_overlay_dups       oem                set_shared_user_password.sh  update_ebuilds
LICENSE          bootstrap_sdk_container  build_toolchains           contrib                 get_latest_image.sh     prune_images       set_version                  update_metadata
MAINTAINERS.md   build_docker_aci         build_torcx_store          core_date               get_package_list        rebuild_packages   settings.env                 update_sdk_container_image
NOTICE           build_image              changelog                  core_dev_sign_update    image_inject_bootchain  retag-for-jenkins  setup_board
README.md        build_library            checkout                   core_pre_alpha          image_set_group         run_sdk_container  signing
__build__        build_oem_aci            ci-automation              core_roller_upload      image_to_vm.sh          sdk_container      tag_release
```

**The ebuilds**
```shell
ls sdk_container/src/third_party/portage-stable
```
```
ls sdk_container/src/third_party/coreos-overlay
```

### Building packages

While both the SDK container and the OS images use the same ebuild sources, they have different "root FS"es.

SDK and OS image "packages" are separated; OS packages use Gentoo's cross-tools so are technically cross-compiled (even when HOST == Target).
The SDK uses the cross-root `/build/<arch>-usr`; `/build/amd64-usr` for X86-64, and `/build/arm64-usr` for ARM64 OS images.

Check out the cross-roots in the SDK container:
```
ls /build/amd64-usr

ls /build/arm64-usr
```

This is the directory structure where the OS image packages will be built (emerged).
As a Gentoo side-product, the packages will also be installed into the tree, building a superset of what will later become the OS image.

There are separate "emerge" commands for SDK container and OS image.

**This impacts packages installed in the SDK container**
```shell
emerge
```

**This impacts packages installed in the "board" (OS image) build root (more on that soon)**
```shell
emerge-amd64-usr
```

#### Pre-built packages in the SDK container for this workshop

In a plain SDK container, these build roots are empty except for essentials to bootstrap the build, like kernel header, compiler, and C library.
But since you've been handed a pre-built SDK container (or have run `build_packages`), all the AMD64 board packages will be installed.
```
ls /build/amd64-usr/var/lib/portage/pkgs/
ls /build/amd64-usr/var/lib/portage/pkgs/app-shells/
```

Compare this to the ARM64 build root which only has the bootstrap essentials:
```
ls /build/arm64-usr/var/lib/portage/pkgs/
```
(running `./build_packages --board arm64-usr` would build these, but let's focus on one architecture in this workshop).

### Check out the board root

You can, in fact, `chroot` into the "board" root and look around:
```
sudo chroot /build/amd64-usr
```

### Building images

We've discussed the SDK container layout and briefly touched what `build_packages` does.
Now let's talk about what your machine is doing *right now* - building a Flatcar OS image.

Remember all the binary packages that `build_packages` built in `/build/amd64-usr/var/lib/portage/pkgs/`?
The image building step will create a new disk image and install all OS packages into it.

**NOTE**: All Flatcar OS binaries reside in `/usr`.
Upstream gentoo packages that install outside of `/usr` are modified by Flatcar maintainers when ingesting the package into Flatcar.
The `/usr` directory is backed by its own partition.
The file system root is populated dynamically at first boot (i.e. not in the image build process).
So for our OS disk image, the root partition will not matter at all.
Only the `USR` partition will.

Image building entails these steps:
1. Create a whole disk image (a 4.5 GB empty file), and partition it in Flatcar's partition scheme.
2. Create a temporary root subdirectory for the image build, e.g. `build/amd64-usr/latest/rootfs/`)
3. Mount the `USR` partition of the disk image into the temporary root (to `build/.../rootfs/usr/`)
4. `emerge-amd64-usr` all binary packages that make up the OS image to the temporary root (to `build/.../rootfs/`).
5. Delete portage / `emerge` artifacts from the temporary root.
6. Unmount the `USR` partition.
7. Protect the `USR` against tampering with `dm-verity` and mark it read-only.

### To summarise

1. The SDK container ships a self-contained build environment.
2. The distro ("scripts") repository contains all packages' build instructions; it's versioned and corresponds to Flatcar releases.
3. The distro repository is bind-mounted into the container, so the SDK can use ebuild files stored in the repo.
4. The packages build process "cross-compiles" these ebuilds into the architecture build root.
5. The image build process uses the pre-built packages and installs these into a whole-disk image.

**TL;DR**

* `./build_packages` : compile ebuilds from `sdk_container/src/third_party/(portage-stable, coreos-overlay`) to `/build/amd64-usr/`
* `./build_image` : install binary packages from `/build/amd64-usr/var/lib/portage/pkgs/` to a pristine new whole-disk image.


# Pause for questions

## Check out what we've just built

From here on all commands should be run inside the SDK container (if not otherwise noted).

**Let's check out the image**
```shell
sfdisk -d ../build/images/amd64-usr/latest/flatcar_production_image.bin
```

You can see 7 active partitions (9 partitions total, two are empty/reserved):
```
label: gpt
label-id: 00000000-0000-0000-0000-000000000001
device: flatcar_production_image.bin
unit: sectors
first-lba: 34
last-lba: 9289694
sector-size: 512

flatcar_production_image.bin1 : start=        4096, size=      262144, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=E0296128-F676-469E-8347-09E2D1B23397, name="EFI-SYSTEM", attrs="LegacyBIOSBootable"
flatcar_production_image.bin2 : start=      266240, size=        4096, type=21686148-6449-6E6F-744E-656564454649, uuid=EED6D8D5-9B2F-4F3D-8CC4-D04027D5552A, name="BIOS-BOOT"
flatcar_production_image.bin3 : start=      270336, size=     2097152, type=5DFBF5F4-2848-4BAC-AA5E-0D9A20B745A6, uuid=7130C94A-213A-4E5A-8E26-6CCE9662F132, name="USR-A", attrs="GUID:48,56"
flatcar_production_image.bin4 : start=     2367488, size=     2097152, type=5DFBF5F4-2848-4BAC-AA5E-0D9A20B745A6, uuid=E03DD35C-7C2D-4A47-B3FE-27F15780A57C, name="USR-B"
flatcar_production_image.bin6 : start=     4464640, size=      262144, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=F8D581B7-A985-4436-90BB-C5599DBDC430, name="OEM"
flatcar_production_image.bin7 : start=     4726784, size=      131072, type=C95DC21A-DF0E-4340-8D7B-26CBFA9A03E0, uuid=83534409-31B3-46A2-9E52-F9F4594940EC, name="OEM-CONFIG"
flatcar_production_image.bin9 : start=     4857856, size=     4427776, type=3884DD41-8582-4404-B9A8-E9B84F2DF50E, uuid=15D7C171-B5A7-4277-97CD-5578C8A2C882, name="ROOT"
```

Only `EFI-SYSTEM`, `BIOS-BOOT`, and `USR-A` currently have any content.

This is the pristine Alpha-3665.0.0 release.
You can boot it, but it's currently not set up for any environment.

-----

**BUGFIX ALERT!**

We need to patch the Alpha release's OEM image builder script to work around an issue:

Edit `build_library/vm_image_util.sh` and add in line 546: `       --ignore_version_mismatch`.

Alternatively, apply this patch:
```diff
diff --git a/build_library/vm_image_util.sh b/build_library/vm_image_util.sh
index a57f6cd6ed..c796dc2eda 100644
--- a/build_library/vm_image_util.sh
+++ b/build_library/vm_image_util.sh
@@ -543,6 +543,7 @@ install_oem_sysext() {
         --squashfs_base="${VM_SRC_SYSEXT_IMG}"
         --image_builddir="${built_sysext_dir}"
         --metapkgs="${metapkg}"
+        --ignore_version_mismatch
     )
     local overlay_path mangle_fs
     overlay_path=$(portageq get_repo_path / coreos)
```

-----


To produce a specialised image for QEMU, use:
```shell
./image_to_vm.sh --image_compression_formats none ../build/images/amd64-usr/latest/
```

This will generate the qemu image (filling the `OEM` and `OEM-CONFIG` partitions) as well as create a helper script to start the image from the command line.
Let's check it out:
```shell
../build/images/amd64-usr/latest/flatcar_production_qemu.sh -nographic
```

This is a live instance of the Flatcar disk image we've just built.
Note that the first boot will populate the root filesystem and run any Ignition config passed to the starter script.
This will initialise (change) the disk image.
Subsequent boots will ignore the Ignition config.

You can stop the VM by issuing
```shell
sudo shutdown now --poweroff
```

## Extend the image by a simple app

### Let's add a package!

We'll add a simple package and its dependencies.

### Clone the Gentoo upstream repo

We'll clone the Gentoo repo now to get access to thousands of applications, libraries, and tools.
This is a shallow clone of the Gentoo Github mirror for performance reasons.

It is recommended to do this outside of the `flatcar-distro` workspace.

**On the host system outside the SDK container, run**
```shell
git clone --depth 1 https://github.com/gentoo/gentoo
```

-----

**Audience call: any favourite tool you want to add?**

-----

I'd propose `sys-process/htop` and `app-misc/screen`, but only if you don't have any better idea!

First, let's copy the ebuilds.
This will change of course if we picked other favourite apps / tools.

**On the host system outside the SDK container, run**
```shell
cp -R gentoo/sys-process/htop flatcar-distro/sdk_container/src/third_party/portage-stable/sys-process/
cp -R gentoo/app-misc/screen flatcar-distro/sdk_container/src/third_party/portage-stable/app-misc/
```

Now check if we can emerge / if we need to add any dependencies:
```shell
emerge-amd64-usr screen htop
```

Add the tool(s) to the OS image meta-package:
```shell
vim sdk_container/src/third_party/coreos-overlay/coreos-base/coreos/coreos-0.0.1.ebuild
```

Mow re-emerge the OS image meta package and build a new disk image.
```shell
emerge-amd64-usr coreos-base/coreos
./build_image
./image_to_vm.sh --image_compression_formats none ../build/images/amd64-usr/latest/
```

Start the new image and check out htop running in screen!
```shell
../build/images/amd64-usr/latest/flatcar_production_qemu.sh -nographic
```

### Now what?

Check your ebuild changes to the OS image:
```shell
git status sdk_container/
```

If you wanted to upstream your changes you would now file a PR to https://github.com/flatcar/scripts.

-----

## Check time / Audience poll: Is there time for adding another package?

-----

## If there's even more time: sysexts FTW

Sysexts are a brand new way to extend immutable systems via transparent filesystem overlays.
It's a great way for users to ship their extensions to Flatcar without the requirement of upstream merges (or hosting their own image / update servers).

```shell
git clone https://github.com/flatcar/sysext-bakery.git
cd sysext-bakery
./create_kubernetes_sysext.sh v1.27.4 kubernetes-1.27.3
```

This will create a Kubernetes sysext.
This is simply a filesystem image with kubernetes bits installed to `/usr`.
Let's check it out:
```shell
mkdir mnt
sudo mount -o loop kubernetes-1.27.3.raw mnt
```

### Use the sysext

We'll make the sysext available inside the Flatcar VM and then apply ("merge") it into the system.

```shell
cp ../sysext-bakery/kubernetes-1.27.3.raw .
../build/images/amd64-usr/latest/flatcar_production_qemu.sh -virtfs local,path=$(pwd),mount_tag=host0,security_model=passthrough,id=host0 -nographic
```

In the VM, run:
```shell
sudo -i
mount -t 9p -o trans=virtio,version=9p2000.L host0 /mnt
 /mnt
```

```shell
cp /mnt/kubernetes-1.27.3.raw /etc/extensions/
```

```shell
systemd-sysext list
systemd-sysext status
```

Apply the sysext
```shell
systemd-sysext refresh
```

Now `kubelet` and related commands are available, and the sysext even ships systemd units to launch at boot.

Check out https://github.com/flatcar/sysext-bakery#recipes-in-this-repository for examples on downloading and activating sysexts at provisioning time, composing your very own OS! 
