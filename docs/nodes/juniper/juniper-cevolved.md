# Juniper cEvolved

cJunosEvolved is a container based image. It runs Junos OS Evolved in a virtual machine inside
the container, with a software simulation of a PTX router's forwarding chipset.

## Base Image

The image can be downloaded from the
[vJunos Labs](https://www.juniper.net/us/en/dm/vjunos-labs.html) download page. The download is
a `docker save` archive, for example `cJunosEvolved-26.2R1.7-EVO.tar.gz`.

### Import image

Load the archive into Docker, tag the image with the cJunosEvolved version, and register it with
Sherpa by scanning the local container images:

```
docker load -i cJunosEvolved-26.2R1.7-EVO.tar.gz
docker tag cjunosevolved:26.2R1.7-EVO localrepo/juniper_cevolved:26.2R1.7
sherpa server image scan --container
```

!!! warning

    cJunosEvolved images must be tagged with the repo `localrepo/juniper_cevolved`. The scan
    only registers images with that repo as the `juniper_cevolved` node model, and labs start
    cJunosEvolved from it. The first version registered becomes the default.

## Platforms

cJunosEvolved emulates one of two PTX routers. Choose one per node with
[`platform`](../../manifest.md#platform-string):

| Platform | Router         | Chipset       | Data Interfaces |
| -------- | -------------- | ------------- | --------------- |
| `bt`     | PTX10001-36MR  | Express 4     | et-0/0/0-11     |
| `bx`     | PTX10002-36QDD | Express 5     | et-0/0/0-35     |

Without `platform`, a node is `bt`. A node has 12 data interfaces on either platform unless the
manifest sets `data_interface_count`; a `bx` node takes up to 36.

## Default Node Parameters

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

`cpu_count` and `memory` size the Junos OS Evolved virtual machine inside the container. 4 vCPUs
and 6292MB are its minimums. The container needs about 2GB more memory than the virtual machine,
so allow 8GB of host memory per node.

## Example Manifest

```toml
name = "juniper-cevolved"

[[nodes]]
name = "pe01"
model = "juniper_cevolved"

[[nodes]]
name = "pe02"
model = "juniper_cevolved"
platform = "bx"

[[links]]
src = "pe01::et-0/0/0"
dst = "pe02::et-0/0/0"
```

## ZTP

### Volume

Sherpa writes a `juniper.conf` startup config and mounts its directory at
`/home/evo/configdisk` in the container. The container hands the config to Junos on first boot.

## Requirements

- The Sherpa server must have KVM: the container starts a virtual machine. The container runs
  privileged.
- On first boot the container installs Junos to a virtual disk, so the first start of a node
  takes longer than later ones.

## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

## Notes

- Junos shows every data interface up, linked or not: its simulated forwarding plane does not
  follow the link state of the container interfaces. Unlinked interfaces carry no traffic.
- A node shows all of its platform's data interfaces whatever `data_interface_count` is: 12 on
  `bt`, 36 on `bx`. Only the first `data_interface_count` of them are wired to the lab.
- Approximate time for the system to be ready: `4 minutes`. `sherpa up` reports a container as
  ready when it has started, so SSH answers a few minutes after `sherpa up` finishes.
- With [`ztp = "disabled"`](../../manifest.md#ztp-string) the node is the image as shipped: Sherpa mounts no config directory, so Junos boots from the image's own configuration. That configuration gives `re0:mgmt-0` the node's management IP address and turns on SSH, with only the image's own `admin` user: the node answers on its address, but it has no `sherpa` login, so `sherpa ssh` is refused. Log in as `admin` with the password Juniper's documentation for the image gives. The node's `volumes` from the manifest are mounted, so you can supply a configuration of your own.
