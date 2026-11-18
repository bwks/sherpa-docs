# SONiC Linux

The `sonic_linux` model runs SONiC as a virtual machine (`sonic-vs`) or as a container
(`docker-sonic-vs`). A node is the virtual machine unless it sets `kind = "container"`.

| Kind              | Image             | Manifest                                      |
| ----------------- | ----------------- | --------------------------------------------- |
| `virtual_machine` | `sonic-vs`        | `model = "sonic_linux"` (the default kind)    |
| `container`       | `docker-sonic-vs` | `model = "sonic_linux"`, `kind = "container"` |

## Virtual machine

### Base Image

Base images can be downloaded from [TBC]().

!!! Warning

    Virtual Machine images from [sonic.software](https://sonic.software/) do not have ZTP enabled
    during compilation. If you obtain your image from there, ZTP will not work.

### Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --model sonic_linux \
  --version 20251215 \
  --default
```

### Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 20251215        |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 4GB             |
| CDROM Driver         | virtio          |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `http`          |
| Management Interface | eth0            |
| Data Interfaces      | eth1-32         |
| Interface Driver     | virtio          |

### Example Manifest

```toml
name = "sonic-linux"

[[nodes]]
name = "dev01"
model = "sonic_linux"
```

### Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Console"

    ```
    sherpa console <node-name>
    ```

### Front-panel Ports

The VM has 32 front-panel ports, `Ethernet0` to `Ethernet124`. Data interface `ethN` is port
`Ethernet(4 × (N − 1))`: `eth1` is `Ethernet0`, `eth2` is `Ethernet4` and `eth32` is `Ethernet124`.

Sherpa's ZTP brings all 32 ports up administratively (`admin_status` up), linked or not, and
saves the result to `/etc/sonic/config_db.json`, so the ports stay up after a reboot.

### Notes

- Approximate time for the system to be ready: `2 minutes`

## Container

No registry publishes a current `docker-sonic-vs` image. Build it from upstream's published
archive, with `sudo` added, as [Build the SONiC Container Image](build-container-image.md)
describes. The image must be tagged `docker-sonic-vs:<version>`.

### Import Image

Import the `docker save` archive the build page makes, with `--kind container`:

```
sherpa server image import \
  --src /var/tmp/docker-sonic-vs-202511.tar \
  --model sonic_linux \
  --kind container \
  --version 202511 \
  --default
```

The archive must be readable by the Sherpa server, so keep it out of your home directory.
If the image is already in the server's Docker, `sherpa server image scan --kind container`
registers it instead.

Every other image command takes `--kind container` for this image; without it, the command
means the virtual machine image.

### Default Node Parameters

| Property             | Value             |
| -------------------- | ----------------- |
| Kind                 | Container         |
| Tested Version       | 202511            |
| Image                | `docker-sonic-vs` |
| CPU                  | 2                 |
| RAM                  | 1GB               |
| Privileged           | yes               |
| ZTP                  | `volume`          |
| Management Interface | eth0              |
| Data Interfaces      | eth1-32           |
| Readiness            | SSH, port `22`    |

### Example Manifest

```toml
name = "sonic-container"

[[nodes]]
name = "sw1"
model = "sonic_linux"
kind = "container"
version = "202511"

[[nodes]]
name = "sw2"
model = "sonic_linux"
kind = "container"
version = "202511"

[[links]]
src = "sw1::eth1"
dst = "sw2::eth1"
```

### Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Docker"

    ```
    docker exec -it <node-name>-<lab-id> bash
    ```

You log in as yourself, with your keys or your device password. `root` has no password and no
SSH login.

### Using the CLI

| Command | How |
| --- | --- |
| `show interfaces status`, `show ip interfaces`, `show ip route`, `show vlan brief` | as you, no `sudo` |
| `vtysh`, for example `vtysh -c "show ip route"` | as you, no `sudo` |
| `config …`, for example `sudo config interface ip add Ethernet0 10.0.0.0/31` | with `sudo` |
| `sudo config save -y` | saves the running configuration, so a restart keeps it |
| `show version`, `show lldp table` | do not work: they call `docker`, which the image does not have |

Every `show` command prints `sudo: docker: command not found` first. It is harmless.

### Front-panel Ports

The container has the same 32 ports as the VM: data interface `ethN` is port
`Ethernet(4 × (N − 1))`. The image maps the interfaces it finds when it starts, once, so Sherpa
starts SONiC only when all of the node's data interfaces are attached. All 32 ports are listed by
`show interfaces status`, with or without an interface behind them, and Sherpa's configuration
brings them all up administratively.

### Configuration

Sherpa's configuration sets the hostname and brings the ports up. It is loaded when the
container first starts and saved to `/etc/sonic/config_db.json`. After that:

- `sherpa down` and `sherpa resume` pause and resume the container: everything is kept, saved
  or not.
- A container that was stopped, and is started again by `sherpa resume`, loads the saved
  configuration. Changes you did not save with `sudo config save -y` are lost.
- `sherpa redeploy` creates a new container, which starts again from Sherpa's configuration.

A [custom ZTP configuration](../../manifest.md#ztp-object) replaces Sherpa's
`config_db.json`; it is merged into the configuration the image generates, so it needs only what
it changes. You still get your login.

### Notes

- Approximate time for the system to be ready: `1 minute`.
- Without `sudo` in the image, you can log in and use what needs no root, but not `config …`:
  the node's log (`docker logs <node-name>-<lab-id>`) says
  `sherpa-init: this image has no sudo, so <you> has no root access: build the image with sudo`.
  Build the image as the build page says.
- With [`ztp.method = "disabled"`](../../manifest.md#ztp-object) the node still waits for its
  data interfaces and starts its SSH server, but has no login and no Sherpa configuration. Reach
  it with `docker exec`.
- The container is privileged, like the other network OS containers.
- Every container built from one image has the same SSH host keys.
- `bgpd` is started, which the image does not do on its own. LLDP does not run.
