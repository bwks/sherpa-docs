# Zero Touch Provisioning

Configuring nodes via Zero Touch Provisioning (ZTP) is a core design goal of Sherpa. Every supported device has a method to apply a configuration to a node on first boot.

## Default Node Configuration

The following configuration parameters are applied to nodes via ZTP:

- Hostname
- Management IPv4/6 addresses
- Default route
- DNS domain
- DNS name servers
- DNS search domains
- Sherpa user with password and SSH key authentication.

## Custom Node Configuration

User defined configuration can be applied to devices by specifying
the location with the `ztp_config` parameter in the `manifest.toml`
file.

A custom `ztp_config` is supported for nodes that use the TFTP, NoCloud, CDROM, Config Disk and
USB Disk methods. Nodes that use cloud-init, Ignition or HTTP reject it.

### Example

```toml
# manifest.toml

[[nodes]]
name = "dev01"
model = "sonic_linux"
ztp_config = "/some/path/dev01.conf"
```

## ZTP Methods

### Cloud-Init

Cloud-init is the default ZTP method. Configuration is delivered via an ISO image mounted as a CDROM device with the volume label `cidata`.

![sherpad writes user-data, meta-data and network-config to a cidata ISO attached to the VM as a CD-ROM](ztp-cloud-init.svg)

The ISO contains three files:

- `user-data` — system configuration, user provisioning, and startup scripts
- `meta-data` — instance metadata such as hostname
- `network-config` — network interface configuration

Sherpa writes these files as JSON, which cloud-init reads as YAML. Every
value keeps its type, so a MAC address such as `52:54:00:21:47:08` or a value such as `yes`
is never read as a number or a boolean. `user-data` still starts with the `#cloud-config` line.

On boot, the cloud-init service detects the `cidata` volume and applies the configuration automatically.

### NoCloud

Like cloud-init, NoCloud configuration is delivered on a `cidata` CD-ROM. The difference is
`user-data`: instead of a cloud-init config, it holds the node's native configuration, either
your `ztp_config` or one Sherpa generates. Sherpa adds `meta-data` and a `network-config` with
the static management address.

![sherpad writes user-data, meta-data and network-config to a cidata ISO attached to the VM as a CD-ROM](ztp-nocloud.svg)

### Ignition

Ignition is a declarative provisioning system. Configuration is delivered as a JSON file passed to the VM via QEMU command-line parameters.

![sherpad passes an Ignition config to the VM through QEMU's fw_cfg device and attaches a container disk](ztp-ignition.svg)

A secondary EXT4 data disk is also created for container storage.

### USB Disk

Configuration is written to a FAT32 disk image that is attached to the VM as a removable USB device. On boot, the device detects the USB disk and reads the configuration files.

![sherpad writes config files to a disk image attached to the VM as a USB device](ztp-usb.svg)

### Config Disk

Configuration is written to a secondary disk image attached to the VM. Depending on the device, the disk may be formatted as FAT32 or EXT4.

![sherpad writes config files to a disk image attached to the VM as a secondary disk](ztp-disk.svg)

- **FAT32** — files are written to the disk using `mcopy`.
- **EXT4** — files are written to the disk using `e2cp`.

On boot, the device detects the secondary disk and applies the configuration.

### CDROM

Configuration files are packaged into an ISO image and mounted as a read-only CDROM device. The device scans the CDROM for a specific filename during boot.

![sherpad packages the config file into an ISO attached to the VM as a CD-ROM](ztp-cdrom.svg)

### TFTP

Configuration is served over the network via TFTP from the lab router. A dnsmasq instance provides both DHCP and TFTP services for the lab. DHCP options 66 and 67 direct the device to the TFTP server and configuration filename.

![The VM gets its address and config file name from DHCP on the lab router, then downloads the file over TFTP](ztp-tftp.svg)

### HTTP

Configuration is served over the network via HTTP on port 8080 of the lab router. A dnsmasq instance provides DHCP services that direct the device to the config URL using DHCP options 67 and 239.

![The VM gets its address and config URL from DHCP on the lab router, then downloads the files over HTTP](ztp-http.svg)

### Container Volumes

Container nodes do not use a ZTP method. They are configured when the container is created,
from the node's `environment_variables`, `commands` and `volumes` in the manifest. Each volume
bind mounts a path on the Sherpa server into the container, and the container application reads
its configuration from the mounted path on startup.

![A path on the Sherpa server is bind mounted into the container](ztp-volume.svg)

### iPXE

iPXE network boot is planned and not yet implemented.
