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
- Your login: your Sherpa username, your registered SSH keys and your
  [device password](device-password.md), written in the form the device takes. Where a device
  stores a hash, the configuration carries a salted hash, not the password. Fixed vendor accounts
  such as `admin` take the device password too. Aruba AOS-CX gets your keys only, with `admin`
  locked. See [Your Login on Nodes](personal-accounts.md#passwords-on-nodes).

There is no `sherpa` account and no shared password in a configuration Sherpa generates. The
configurations served over TFTP or HTTP carry only hashes of the device password, and Aruba
AOS-CX's carries none.

## Who Can Read a Node's Configuration

A node's configuration holds its logins, and a custom `ztp.config` holds whatever you put in it.

**On the Sherpa server**, Sherpa writes every configuration it renders for a node as the
`sherpa` account, readable by that account only, in folders only it can open, whatever the
server's umask. People in the `sherpa` group cannot read them; use `sudo` to look at one. A VM's
boot files are removed once its boot media are in the storage pool, container configurations
when the node is destroyed, and TFTP and HTTP configurations when the lab is destroyed.

TFTP configurations are the one exception: the lab router's TFTP service serves only files
every account can read, so they are readable by accounts outside the `sherpa` group too, but not
by the group. Those accounts cannot reach the lab's folder on the server, so on the server the
effect is the same.

**On the lab's management network**, the [TFTP](#tftp) and [HTTP](#http) configurations are
served without credentials. Any node in the lab, or anything else that reaches the lab router,
can fetch any node's TFTP or HTTP configuration while the lab exists, not only its own. Each
service serves only its own files: HTTP on port 8080 serves the files of the nodes that boot by
HTTP and nothing else, not the TFTP configurations and not the lab router's DHCP leases (see
[HTTP](#http)). Keep this in mind before you
give a TFTP or HTTP node a custom `ztp.config` with a secret in it. Configurations delivered on
a CD-ROM, disk or USB disk, by cloud-init, NoCloud or Ignition, or as container volumes are not
served on the network.

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
| `tftp` | [TFTP](#tftp) | Arista vEOS, Aruba AOS-CX, Juniper vEvolved |
| `http` | [HTTP](#http) | SONiC |
| `volume` | [Container Volumes](#container-volumes) | Arista cEOS, Nokia SR Linux, Juniper cEvolved, Cisco IOL, FRR |

A model takes only the methods listed against it, and all but one take one: Juniper vEvolved
takes `tftp` or `usb`. Application containers and unikernels take
only `disabled`. Sherpa refuses any other setting when the image is saved, when a manifest is
validated, and before `sherpa up` or `sherpa redeploy` changes anything.

### Per Node

A node can set its own with [`ztp.method`](../manifest.md#ztp-object) in the manifest. Without it the
node uses its image's setting.

```toml
# manifest.toml

[[nodes]]
name = "dev01"
model = "frr_linux"

[nodes.ztp]
method = "disabled"

[[nodes]]
name = "dev02"
model = "juniper_srxv3"

[nodes.ztp]
method = "tftp"
```

To change a node's method in a running lab, change `ztp.method` and run
`sherpa redeploy -n <node>`. When the node moves onto or off `tftp` or `http`, the lab router's
DHCP options for it change too, and Sherpa recreates the lab router, which runs the lab's DHCP,
DNS, TFTP and HTTP services, for that. Lab nodes keep their addresses, but those services and
the lab's outside access pause for a few seconds while it is recreated. In a lab made before
0.7.0, the first redeploy of a VM recreates it too, to stop it serving the TFTP configurations
over HTTP. A redeploy that keeps the node's method does not restart it. The files of the node's
old method are removed.

### Disabled

A node with ZTP `disabled` boots as its image ships: Sherpa generates no configuration and adds
no [login](personal-accounts.md). The generated configuration is
also what gives a node its management IP address, so a node with ZTP `disabled` has none unless
its image configures one itself, and `sherpa ssh` cannot reach it. A virtual machine gets no
configuration media. A container gets only what it needs to start, as described under
[Container Volumes](#container-volumes).

## Custom Node Configuration

User defined configuration can be applied to devices by specifying
the location with the `ztp.config` parameter in the `manifest.toml`
file.

A custom `ztp.config` is supported for nodes whose ZTP setting is `tftp`, `nocloud`, `cdrom`,
`disk`, `usb` or `volume`. Sherpa refuses it, before the lab is created, on nodes that use
`cloud-init`, `ignition` or `http`, and on nodes whose ZTP is `disabled`. The exception is
[HashiCorp Vault](../nodes/hashicorp/hashicorp-vault.md#your-own-config), where `ztp.config` is
Vault's own configuration file.

### Example

```toml
# manifest.toml

[[nodes]]
name = "dev01"
model = "cisco_cat8000"

[nodes.ztp]
config = "/some/path/dev01.conf"
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
your `ztp.config` or one Sherpa generates. Sherpa adds `meta-data` and a `network-config` with
the static management address.

![sherpad writes user-data, meta-data and network-config to a cidata ISO attached to the VM as a CD-ROM](ztp-nocloud.svg)

### Ignition

Ignition is a declarative provisioning system. Configuration is delivered as a JSON file in the storage pool, which libvirt passes to the VM through QEMU's firmware configuration device (fw_cfg).

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

Only the files of the nodes that boot by HTTP are served, from the root of the server: today
SONiC's, `<node>.conf` (the ZTP file that DHCP names), `<node>_config_db.json` and
`<node>_ztp_user.sh` (your account). The TFTP configurations are served over TFTP only, and the
lab router's DHCP leases are not served. Up to 0.6.5 the files were under `/configs/`, and
`/tftp/` and `/dnsmasq/dnsmasq.leases` were served too.

![The VM gets its address and config URL from DHCP on the lab router, then downloads the files over HTTP](ztp-http.svg)

### Container Volumes

Arista cEOS, Nokia SR Linux, Juniper cEvolved, Cisco IOL and FRR containers use the `volume`
method. Sherpa
writes the node's configuration files on the Sherpa server and bind mounts them into the
container, which reads them on startup. The configuration carries your login.

![A path on the Sherpa server is bind mounted into the container](ztp-volume.svg)

With ZTP `disabled`, one of these containers starts with its image, environment and command
only. Sherpa mounts no configuration and adds no login, so `sherpa ssh` cannot log in to it. What
the node does with its management address depends on its image: cEOS and SR Linux leave it
unconfigured, FRR answers on it with no SSH server, cJunosEvolved configures it with SSH for
the image's own `admin` user, and IOL boots with no configuration and runs its own autoinstall. Each model's page says how to reach it. The node's `container.volumes`
from the manifest are mounted instead, so you can supply a configuration of your own.

Every other container has no ZTP method. It is configured when the container is created, from
the node's `environment_variables`, `container.commands` and `container.volumes` in the
manifest.
