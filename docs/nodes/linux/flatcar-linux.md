# Flatcar Linux

## Base Image

Base images can be downloaded from the [Flatcar Release](https://www.flatcar.org/docs/latest/installing/vms/libvirt/#stable-create) channels.

This guide uses the `stable` release.

## AppArmor

If Sherpa was installed manually, ensure that the
[AppArmor](../../install-update/install/manual.md#apparmor) policy was updated as part of the
host system install process.

## Import Image

```
sherpa image import \
  --src flatcar_production_qemu_image.img \
  --model flatcar_linux \
  --version 20251215 \
  --latest
```

## Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 20251215        |
| Kind                 | Virtual Machine |
| CPU                  | 1               |
| RAM                  | 2GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | Ignition        |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "flatcar-linux"

nodes = [
  { name = "dev01", model = "flatcar_linux" },
]
```

## Notes

- Approximate time for the system to boot, and for ZTP to finish: `1 minute`
- The default ZTP config disables automatic updates
