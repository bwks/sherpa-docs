# Juniper Junos OS Evolved

The `juniper_evolved` model runs Junos OS Evolved as a virtual machine (vJunosEvolved) or as a
container (cJunosEvolved). A node is the virtual machine unless it sets `kind = "container"`.

| Kind              | Image         | Manifest                                         |
| ----------------- | ------------- | ------------------------------------------------ |
| `virtual_machine` | vJunosEvolved | `model = "juniper_evolved"` (the default kind)   |
| `container`       | cJunosEvolved | `model = "juniper_evolved"`, `kind = "container"` |

## Virtual machine (vJunosEvolved)

### Base Image

Base images can be downloaded from the [download](https://support.juniper.net/support/downloads/?p=vjunos-evolved) page.

### Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version 25.2R1.8 \
  --model juniper_evolved \
  --default
```

### Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 25.2R1.8        |
| CPU                  | 4               |
| RAM                  | 8GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `tftp`          |
| Management Interface | re0:mgmt-0      |
| Data Interfaces      | et-0/0/0-11     |
| Interface Driver     | virtio          |

### Example Manifest

```toml
name = "juniper-evolved"

[[nodes]]
name = "dev01"
model = "juniper_evolved"
```

### ZTP

#### TFTP

The Juniper documentation states that a secondary attached disk is the method to provide an initial
config on first boot. However, I could not get this to work with the latest version: `25.2R1.8`.
Therefore, the TFTP method is selected for this device type as default.

### Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Console"

    ```
    sherpa console <node-name>
    ```

### Notes

- Approximate time for the system to be ready: `9 minutes`

## Container (cJunosEvolved)

cJunosEvolved runs Junos OS Evolved in a virtual machine inside the container, with a software
simulation of a PTX router's forwarding chipset.

### Base Image

The image can be downloaded from the
[vJunos Labs](https://www.juniper.net/us/en/dm/vjunos-labs.html) download page. The download is
a `docker save` archive, for example `cJunosEvolved-26.2R1.7-EVO.tar.gz`.

### Import Image

Load the archive into Docker, tag the image with the cJunosEvolved version, and register it with
Sherpa by scanning the local container images:

```
docker load -i cJunosEvolved-26.2R1.7-EVO.tar.gz
docker tag cjunosevolved:26.2R1.7-EVO localrepo/juniper_evolved:26.2R1.7
sherpa server image scan --kind container
```

!!! warning

    cJunosEvolved images must be tagged with the repo `localrepo/juniper_evolved`. The scan only
    registers images with that repo as `juniper_evolved` container images, and labs start
    cJunosEvolved from it. The first version registered becomes the default.

Every other image command takes `--kind container` for a cJunosEvolved image; without it, the
command means the vJunosEvolved image. For example:

```
sherpa server image set-default --model juniper_evolved --kind container --version 26.2R1.7
```

### Platforms

cJunosEvolved emulates one of two PTX routers. Choose one per node with
[`container.platform`](../../manifest.md#container-object):

| Platform | Router         | Chipset       | Data Interfaces |
| -------- | -------------- | ------------- | --------------- |
| `bt`     | PTX10001-36MR  | Express 4     | et-0/0/0-11     |
| `bx`     | PTX10002-36QDD | Express 5     | et-0/0/0-35     |

Without `container.platform`, a node is `bt`. A node has 12 data interfaces on either platform unless the
manifest sets `interfaces.data_count`; a `bx` node takes up to 36. `container.platform` applies
to a `juniper_evolved` container only.

### Default Node Parameters

| Property             | Value       |
| -------------------- | ----------- |
| Kind                 | Container   |
| Tested Version       | 26.2R1.7    |
| CPU                  | 4           |
| RAM                  | 6292MB      |
| ZTP                  | `volume`    |
| Management Interface | re0:mgmt-0  |
| Data Interfaces      | et-0/0/0-11 |
| Interface Driver     | veth        |

`cpu.count` and `memory` size the Junos OS Evolved virtual machine inside the container. 4 vCPUs
and 6292MB are its minimums. The container needs about 2GB more memory than the virtual machine,
so Sherpa gives it a Docker memory limit of `memory` plus 2048MB (8340MB by default), and
counts that against the server's memory. It has no CPU quota, so the virtual machine is not
throttled. `memory` can be at most 63487MB.

### Example Manifest

```toml
name = "juniper-evolved"

[[nodes]]
name = "pe01"
model = "juniper_evolved"
kind = "container"

[[nodes]]
name = "pe02"
model = "juniper_evolved"
kind = "container"

[nodes.container]
platform = "bx"

[[links]]
src = "pe01::et-0/0/0"
dst = "pe02::et-0/0/0"
```

### ZTP

#### Volume

Sherpa writes a `juniper.conf` startup config and mounts its directory at
`/home/evo/configdisk` in the container. The container hands the config to Junos on first boot.

### Requirements

- The Sherpa server must have KVM: the container starts a virtual machine. The container runs
  privileged.
- On first boot the container installs Junos to a virtual disk, so the first start of a node
  takes longer than later ones.

### Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

### Notes

- Junos shows every data interface up, linked or not: its simulated forwarding plane does not
  follow the link state of the container interfaces. Unlinked interfaces carry no traffic.
- A node shows all of its platform's data interfaces whatever `interfaces.data_count` is: 12 on
  `bt`, 36 on `bx`. Only the first `interfaces.data_count` of them are wired to the lab.
- Approximate time for the system to be ready: `4 minutes`. `sherpa up` reports a container as
  ready when it has started, so SSH answers a few minutes after `sherpa up` finishes.
- With [`ztp.method = "disabled"`](../../manifest.md#ztp-object) the node is the image as shipped: Sherpa mounts no config directory, so Junos boots from the image's own configuration. That configuration gives `re0:mgmt-0` the node's management IP address and turns on SSH, with only the image's own `admin` user: the node answers on its address, but it has no `sherpa` login, so `sherpa ssh` is refused. Log in as `admin` with the password Juniper's documentation for the image gives. The node's `volumes` from the manifest are mounted, so you can supply a configuration of your own.
