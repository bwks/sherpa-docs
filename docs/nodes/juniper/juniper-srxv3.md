# Juniper vSRX v3

## Base Image

Base images can be downloaded from the [download](https://support.juniper.net/support/downloads/?p=vsrxeval) page.

!!! Note

    An account is required to download the image.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version 23.2R2.21 \
  --model juniper_srxv3 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 23.2R2.21       |
| CPU                  | 2               |
| RAM                  | 4GB             |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `cdrom`         |
| Management Interface | fxp0            |
| Data Interfaces      | ge-0/0/0-7      |
| Interface Driver     | virtio          |

!!! note

    vSRX reads its startup config from a CD-ROM, the only ZTP method it takes: a node or image set
    to `tftp` is refused.

## Example Manifest

```toml
name = "juniper-srx"

[[nodes]]
name = "dev01"
model = "juniper_srxv3"
```

## ZTP

ZTP config must be provided in a file named `juniper.conf` in the root directory of an `ISO` image.


## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Host Requirements

### PML

Page Modification Logging (PML) must be off on Intel Xeon E5 and E7 v4 hosts. PML tracks dirty
memory pages in hardware, and it interferes with the vSRX's nested KVM: the FreeBSD boot loader
hangs early in boot, usually at `netstack/init.4th`.

Check whether PML is on (`Y`) or off (`N`):

```bash
cat /sys/module/kvm_intel/parameters/pml
```

Turn it off with every VM on the host stopped:

```bash
echo "options kvm_intel pml=0" | sudo tee /etc/modprobe.d/kvm-vsrx.conf
sudo modprobe -r kvm_intel && sudo modprobe kvm_intel
cat /sys/module/kvm_intel/parameters/pml
```

The last command shows `N`. If `modprobe -r` fails because a VM is still running, reboot the
host instead; the setting in `/etc/modprobe.d` applies at boot.

With PML off, the host tracks dirty pages in software. Live migration is slower; other VM
workloads see little difference.

## Notes

- Approximate time for the system to be ready: `4 minutes`
