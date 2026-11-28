# Flatcar Sandbox

`flatcar_sandbox` is the base image of [sandboxes](../../architecture/sandboxes.md): the
Flatcar Container Linux VMs that the
[`arista_eos` container](../arista/arista-eos.md#sandbox),
[`nokia_srlinux`](../nokia/nokia-srlinux.md#sandbox) and the
[`sonic_linux` container](../sonic/sonic-linux.md#sandbox) run in. It is no node of its own: a
manifest node with `model = "flatcar_sandbox"` is refused. For a Flatcar VM, use
[Flatcar Linux](flatcar-linux.md).

Without a `flatcar_sandbox` image, `sherpa up` and `sherpa redeploy` refuse a lab with one of
those nodes, before they create anything, and say how to import it.

## Base Image

Sandboxes boot Flatcar's OpenStack image, `flatcar_production_openstack_image.img.bz2`, from the
`stable` channel of the [Flatcar releases](https://www.flatcar.org/releases). Download it to the
Sherpa server and unpack it with `bunzip2`, which the install script installs:

```
curl -fsSLO https://stable.release.flatcar-linux.net/amd64-usr/4757.2.4/flatcar_production_openstack_image.img.bz2
bunzip2 flatcar_production_openstack_image.img.bz2
```

## Optional: Boot Quietly

Flatcar's bootloader gives the kernel the serial console, which is the network OS's console,
and the kernel prints its boot messages there. Each character is slow in a VM, most of all in a
nested one, so printing them makes every sandbox boot longer, the first boot and each
`sherpa resume`. Once the VM's root file system is up, the kernel prints only errors there
either way.

To boot with the kernel argument `quiet`, edit the unpacked image before you import it: add it
to the bootloader settings in the image's OEM partition, keeping what they hold. Run these as
root on the Sherpa server, with `qemu-nbd` from `qemu-utils`, which the install script installs:

```
modprobe nbd max_part=16
qemu-nbd --connect=/dev/nbd0 flatcar_production_openstack_image.img
udevadm settle
mkdir -p /mnt/flatcar-oem
mount /dev/nbd0p6 /mnt/flatcar-oem
echo 'set linux_append="$linux_append quiet"' >> /mnt/flatcar-oem/grub.cfg
cat /mnt/flatcar-oem/grub.cfg
umount /mnt/flatcar-oem
qemu-nbd --disconnect /dev/nbd0
```

Partition 6 is the OEM partition (`lsblk -o NAME,PARTLABEL /dev/nbd0` shows `OEM`), and use
another `/dev/nbdN` if `nbd0` is in use. `grub.cfg` then ends with:

```
set linux_append="flatcar.autologin"
set linux_append="$linux_append quiet"
```

Then import the edited file as below. Measured on a dev server, itself a VM, each sandbox booted
about 8 seconds faster with the edit, on its first boot and on each `sherpa resume`, and a lab of
a cEOS and an SR Linux node came up and resumed about 10 seconds sooner.

## Import Image

Import the unpacked file, a path on the Sherpa server, with the Flatcar release as its version:

```
sherpa server image import \
  --src /some/path/flatcar_production_openstack_image.img \
  --model flatcar_sandbox \
  --version 4757.2.4 \
  --default
```

Sandboxes boot the default version. A lab's sandboxes keep the version they were made with until
they are redeployed. Sherpa never changes the image: each sandbox boots an overlay of it.

## Default Parameters

| Property       | Value                                    |
| -------------- | ---------------------------------------- |
| Tested Version | 4757.2.4                                 |
| Kind           | Virtual Machine                          |
| File           | `flatcar_production_openstack_image.img` |
| Boot           | SeaBIOS, Flatcar's own bootloader        |
| ZTP            | Ignition, from a config drive Sherpa makes |
