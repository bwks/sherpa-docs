# Manual

## Preparation

### Enable Virtualization Extensions on Host

### Install Supporting packages

```
sudo apt install \
  cpu-checker \
  ssh \
  mtools \
  e2tools \
  gzip \
  unzip \
  qemu-utils \
  dosfstools \
  e2fsprogs
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

### Transparent Hugepages

Let QEMU back VM memory with 2 MiB pages. Skip this if
`/sys/kernel/mm/transparent_hugepage/enabled` already shows `[always]`.

```
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo 'w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise' | \
  sudo tee /etc/tmpfiles.d/sherpa-thp.conf
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

#### Users/Groups

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

Create the lab directory, readable only by the `sherpa` user and group

```
sudo install -d -o sherpa -g sherpa -m 2750 /opt/sherpa/labs
```

Create the database directory, readable only by the `sherpa` user and group, as the database holds
password hashes

```
sudo install -d -o sherpa -g sherpa -m 750 /opt/sherpa/db
```

Create the secrets directory, which only the `sherpa` user can open. `sherpad` keeps its login
token secret and its [database key](../../architecture/database.md#database-key) there

```
sudo install -d -o sherpa -g sherpa -m 700 /opt/sherpa/.secret
```

Create the config, environment and log directories, open to the `sherpa` user and group only

```
sudo install -d -o sherpa -g sherpa -m 750 /opt/sherpa/config /opt/sherpa/env /opt/sherpa/logs
```

`sherpad init`, run as `sherpa`, writes `/opt/sherpa/config/sherpa.toml` with mode `600`. If you
write an environment file, `/opt/sherpa/env/sherpa.env`, make it readable by `sherpa` only, as it
can hold secrets

```
sudo install -o sherpa -g sherpa -m 600 /dev/null /opt/sherpa/env/sherpa.env
```

See [file permissions](automated.md#file-permissions) for every mode.

### AppArmor

Update AppArmor policy to allow `qemu` to access config files.

```
sudo install -d -o sherpa -g kvm -m 2750 /opt/sherpa/libvirt/images
sudo sh -c 'echo "  # For ignition files" >> /etc/apparmor.d/abstractions/libvirt-qemu'
sudo sh -c 'echo "  /opt/sherpa/libvirt/images/** r," >> /etc/apparmor.d/abstractions/libvirt-qemu'
sudo systemctl restart libvirtd.service
```

### Install the Binaries

Download `sherpad` and the `sherpa` CLI for the release you want from the
[releases page](https://github.com/bwks/sherpa/releases), and install them in `/opt/sherpa/bin`,
owned by `sherpa`, with links in `/usr/local/bin`. Set `VERSION` to the release's tag, such as
`v0.7.0`.

```
VERSION=<release tag>
TARGET=x86_64-unknown-linux-gnu
cd "$(mktemp -d)"
for binary in sherpad sherpa; do
  curl -fsSLO "https://github.com/bwks/sherpa/releases/download/${VERSION}/${binary}-${TARGET}.tar.gz"
  tar xzf "${binary}-${TARGET}.tar.gz"
  sudo install -D -o sherpa -g sherpa -m 755 "${binary}" "/opt/sherpa/bin/${binary}"
  sudo ln -sf "/opt/sherpa/bin/${binary}" "/usr/local/bin/${binary}"
done
sherpad --version
```

### Pull the Sherpa Router Image

Each lab's router, which serves DHCP, DNS and the nodes' boot files, runs from this image.

```
sudo docker image pull ghcr.io/bwks/sherpa-router:latest
```

### Install the Service

`sherpad` runs under systemd as `sherpa`, with the network capabilities it needs.

```
sudo tee /etc/systemd/system/sherpad.service > /dev/null << 'UNIT'
[Unit]
Description=Sherpa Daemon - VM, Container, and Unikernel Management Server
Documentation=https://github.com/bwks/sherpa
After=network-online.target docker.service libvirtd.service
Wants=network-online.target
Requires=docker.service libvirtd.service
StartLimitBurst=5
StartLimitIntervalSec=60

[Service]
Type=simple
User=sherpa
Group=sherpa
WorkingDirectory=/opt/sherpa
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_BPF CAP_PERFMON
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_BPF CAP_PERFMON
ExecStart=/opt/sherpa/bin/sherpad start --foreground
Restart=on-failure
RestartSec=5
EnvironmentFile=-/opt/sherpa/env/sherpa.env
RuntimeDirectory=sherpa
RuntimeDirectoryMode=0700
RuntimeDirectoryPreserve=yes
NoNewPrivileges=no
PrivateTmp=no
LimitNOFILE=65536
TasksMax=4096

[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
sudo systemctl enable sherpad.service
```

`PrivateTmp` stays off so `sherpad` can read image files you import from `/tmp`.

### Create Blank Disks

Some nodes boot from a copy of a [blank disk](automated.md#blank-disks) in
`/opt/sherpa/images/blank_disk/`. Once the Sherpa binaries are in `/opt/sherpa/bin`, run the
update script for the version you installed: it finds nothing to install, and creates the blank
disks that are missing, with their folder. It never changes a disk that is there, so it is safe
to run again.

```
curl -fsSLO https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_update.sh
sudo bash sherpa_update.sh --version <installed version>
```

### Initialize and Start

Initialize the server as `sherpa`, with the address clients reach it on. It writes
`/opt/sherpa/config/sherpa.toml`, creates the database, and asks for the `admin` password and
for your own user: its name, password and SSH public key. `sherpa` cannot read your home folder,
so paste the key itself when asked. See
[file permissions](automated.md#file-permissions).

```
sudo -u sherpa -H sherpad init --server-ipv4 <server address>
sudo systemctl start sherpad
```

Lab management subnets come from `172.31.0.0/16` and `fd00:b00b::/48`. If either is in use on
your network, add `--management-prefix-ipv4 <prefix>` or `--management-prefix-ipv6 <prefix>`.

Give your users the server certificate's fingerprint, which clients ask them to check on their
first connection:

```
sudo openssl x509 -in /opt/sherpa/.certs/server.crt -noout -fingerprint -sha256
```

### Sherpa Client

Install the `sherpa` CLI as described in [Client](client.md). The step above already installed
it on the server. Before the first lab, each user sets a
[device password](automated.md#before-the-first-lab) and registers an SSH key.
