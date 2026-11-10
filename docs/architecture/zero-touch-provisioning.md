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

## The ZTP Setting

Every node image has one ZTP setting: `disabled`, or the method Sherpa provisions its nodes by.
`sherpa image show` prints it as `ZTP`, and an administrator changes it on the image's edit page
in the web UI.

| Setting | Method | Used by |
| ------- | ------ | ------- |
| `disabled` | Sherpa provisions nothing | any node |
| `cloud-init` | [Cloud-Init](#cloud-init) | Linux, BSD and Windows virtual machines |
| `nocloud` | [NoCloud](#nocloud) | Talos Linux |
| `ignition` | [Ignition](#ignition) | Flatcar Linux |
| `usb` | [USB Disk](#usb-disk) | Cumulus Linux, Juniper vEvolved |
| `disk` | [Config Disk](#config-disk) | Cisco IOSv, IOSvL2 and ISE, MikroTik CHR |
| `cdrom` | [CDROM](#cdrom) | Cisco IOS XE, ASAv, Nexus, IOS XR and FTDv, Juniper vRouter, vSwitch and vSRX, Palo Alto PAN-OS |
| `tftp` | [TFTP](#tftp) | Arista vEOS, Aruba AOS-CX, Juniper vEvolved and vSRX |
| `http` | [HTTP](#http) | SONiC |
| `volume` | [Container Volumes](#container-volumes) | Arista cEOS, Nokia SR Linux, Juniper cEvolved, FRR |

A model takes only the methods listed against it, and most take one. Juniper vSRX takes `cdrom`
or `tftp`, and Juniper vEvolved `tftp` or `usb`. Application containers and unikernels take
only `disabled`. Sherpa refuses any other setting when the image is saved, when a manifest is
validated, and before `sherpa up` or `sherpa redeploy` changes anything.

### Per Node

A node can set its own with [`ztp`](../manifest.md#ztp-string) in the manifest. Without it the
node uses its image's setting.

```toml
# manifest.toml

[[nodes]]
name = "dev01"
model = "frr_linux"
ztp = "disabled"

[[nodes]]
name = "dev02"
model = "juniper_vsrxv3"
ztp = "tftp"
```

### Disabled

A node with ZTP `disabled` boots as its image ships: Sherpa generates no configuration and adds
no `sherpa` login or [personal account](personal-accounts.md). The generated configuration is
also what gives a node its management IP address, so a node with ZTP `disabled` has none unless
its image configures one itself, and `sherpa ssh` cannot reach it. A virtual machine gets no
configuration media. A container gets only what it needs to start, as described under
[Container Volumes](#container-volumes).

## Custom Node Configuration

User defined configuration can be applied to devices by specifying
the location with the `ztp_config` parameter in the `manifest.toml`
file.

A custom `ztp_config` is supported for nodes whose ZTP setting is `tftp`, `nocloud`, `cdrom`,
`disk`, `usb` or `volume`. Sherpa refuses it, before the lab is created, on nodes that use
`cloud-init`, `ignition` or `http`, and on nodes whose ZTP is `disabled`. The exception is
[HashiCorp Vault](../nodes/hashicorp/hashicorp-vault.md#your-own-config), where `ztp_config` is
Vault's own configuration file.

### Example

```toml
# manifest.toml

[[nodes]]
name = "dev01"
model = "cisco_cat8000v"
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

Arista cEOS, Nokia SR Linux, Juniper cEvolved and FRR containers use the `volume` method. Sherpa
writes the node's configuration files on the Sherpa server and bind mounts them into the
container, which reads them on startup. The configuration carries the `sherpa` login.

![A path on the Sherpa server is bind mounted into the container](ztp-volume.svg)

With ZTP `disabled`, one of these containers starts with its image, environment and command
only. Sherpa mounts no configuration and adds no login, so the node has no management IP address
configured: reach it with `docker exec` on the Sherpa server. The node's `volumes` from the
manifest are mounted instead, so you can supply a configuration of your own.

Every other container has no ZTP method. It is configured when the container is created, from
the node's `environment_variables`, `commands` and `volumes` in the manifest.
