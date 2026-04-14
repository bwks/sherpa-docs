# Libvirt

## Check Libvirt is Running

```bash
sudo systemctl status libvirtd
```

## Start Libvirt

```bash
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
```

## Connection Errors

If you get connection errors, verify the libvirt socket is accessible.

```bash
virsh -c qemu:///system list
```

If this fails with a permission error, ensure your user is in the `libvirt` group.

```bash
sudo usermod -aG libvirt $USER
```

Log out and back in for the group change to take effect.

## Domain Commands

### List Domains (VMs)

```bash
virsh list --all
```

### Show Domain XML

```bash
virsh dumpxml <domain_name>
```

### Force Stop a Domain

```bash
virsh destroy <domain_name>
```

### Remove a Domain

```bash
virsh undefine <domain_name>
```

## Networking

### List Networks

```bash
virsh net-list --all
```

### Show Network XML

```bash
virsh net-dumpxml <network_name>
```

## Storage

### List Storage Pools

```bash
virsh pool-list --all --detailed
```

### Show Pool Info

```bash
virsh pool-info <pool_name>
```

### Show Pool XML

```bash
virsh pool-dumpxml <pool_name>
```

## Nested Virtualization

If VMs are slow or fail to start, check that nested virtualization is enabled.

```bash
cat /sys/module/kvm_intel/parameters/nested
```

If it returns `N`, enable it:

```bash
sudo modprobe -r kvm_intel
sudo modprobe kvm_intel nested=1
```

To make it persistent, create `/etc/modprobe.d/kvm.conf`:

```
options kvm_intel nested=1
```

For AMD processors, replace `kvm_intel` with `kvm_amd`.
