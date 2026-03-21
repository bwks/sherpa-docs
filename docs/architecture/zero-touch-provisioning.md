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

### Example

```toml
# manifest.toml
nodes = [
  { name = "dev01", model = "sonic_linux", ztp_config = "/some/path/dev01.conf" }
]
```

## ZTP Methods

### Cloud-Init

Cloud-init is the default ZTP method for Linux and Windows virtual machines. Configuration is delivered via an ISO image mounted as a CDROM device with the volume label `cidata`.

The ISO contains three files:

- `user-data` — system configuration, user provisioning, and startup scripts
- `meta-data` — instance metadata such as hostname
- `network-config` — network interface configuration

On boot, the cloud-init service detects the `cidata` volume and applies the configuration automatically. Windows nodes use cloudbase-init instead of cloud-init.

### Ignition

Ignition is a declarative provisioning system used by Flatcar Linux. Configuration is delivered as a JSON file passed to the VM via QEMU command-line parameters.

A secondary EXT4 data disk is also created for container storage.

### USB Disk

Configuration is written to a FAT32 disk image that is attached to the VM as a removable USB device. On boot, the device detects the USB disk and reads the configuration files.

### Config Disk

Configuration is written to a secondary disk image attached to the VM. Depending on the device, the disk may be formatted as FAT32 or EXT4.

- **FAT32** — files are written to the disk using `mcopy`.
- **EXT4** — files are written to the disk using `e2cp`.

On boot, the device detects the secondary disk and applies the configuration.

### CDROM

Configuration files are packaged into an ISO image and mounted as a read-only CDROM device. Each vendor expects a specific filename on the CDROM which the device scans for during boot.

### TFTP

Configuration is served over the network via TFTP. A dnsmasq instance provides both DHCP and TFTP services for the lab. DHCP options 66 and 67 direct the device to the TFTP server and configuration filename.

### HTTP

Configuration is served over the network via HTTP. A dnsmasq instance provides DHCP services that direct the device to an HTTP endpoint using DHCP options 67 and 239.

### Volume

For container-based nodes, configuration files are mounted directly into the container filesystem as Docker volume mounts. The container application reads the configuration from the mounted path on startup.
