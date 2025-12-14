# Manual

## Preparation

### Enable Virtualization Extensions on Host

### Install Supporting packages

```
sudo apt install \
  cpu-checker \
  genisoimage \
  telnet \
  ssh \
  mtools \
  e2tools \
  gzip \
  unzip
```

### Check Virtualization Capabilities

```
kvm-ok
```

## Docker

The Docker Engine API is used for to interface with the container runtime.

### Install

Install Docker Engine by following the official [docs](https://docs.docker.com/engine/install/ubuntu/)

### Post Install

Add your `username` to the `Docker` group by following the official [docs](https://docs.docker.com/engine/install/linux-postinstall/)

## QEMU/KVM/Libvirt

The Libvirt API is used to interface with Libvirt which manages VMs via QEMU/KVM.

### Install

```
sudo apt install \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  libvirt-dev \
  bridge-utils \
  virtinst \
  libosinfo-bin \
  libguestfs-tools \
  ovmf
```

### Post Install

Add your username to the `libvirt` and `kvm` groups

```
sudo usermod -aG libvirt,kvm $USER
```

Set the default libvirt URI.

```
echo 'export LIBVIRT_DEFAULT_URI=qemu:///system' > ~/.zshrc
```

## Networking

### Bridge Interface

```yaml
network:
  version: 2
  ethernets:
    eth1-iface:
      match:
        macaddress: 6c:0b:84:aa:68:4e
      set-name: eth1
      dhcp4: false
      dhcp6: false
  bridges:
    br-sherpa0:
      interfaces: [eth1-iface]
      parameters:
        stp: false
        forward-delay: 0
```

## Sherpa

### Sherpa Server

Add `sherpa` user and group

```
sudo adduser --system \
  --group \
  --shell /usr/sbin/nologin \
  --no-create-home \
  sherpa
```

Add your username to the group

```
sudo usermod -aG sherpa $USER
```

Create `sherpa` directory

```
sudo mkdir -p /opt/sherpa && \
    sudo chown sherpa:sherpa /opt/sherpa && \
    sudo chgrp sherpa /opt/sherpa && \
    sudo chmod 2775 /opt/sherpa
```

### Create Blank Disks

#### TODO Update

```
bash scripts/create_blank_disks.sh
bash scripts/create_iosv_disk.sh
```

### Sherpa Client
