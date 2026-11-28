# Arista EOS

The `arista_eos` model runs Arista EOS as a virtual machine (vEOS-lab) or as a container
(cEOS-lab). A node is the virtual machine unless it sets `kind = "container"`.

| Kind              | Image    | Manifest                                   |
| ----------------- | -------- | ------------------------------------------ |
| `virtual_machine` | vEOS-lab | `model = "arista_eos"` (the default kind)  |
| `container`       | cEOS-lab | `model = "arista_eos"`, `kind = "container"` |

## Base Image

Base images can be downloaded from the [Arista support portal](https://www.arista.com/en/support/software-download).

!!! note

    An account is required, which can be created without any support contract.

## Virtual machine (vEOS-lab)

Look for the 64 bit `vEOS Lab` image. Both a Virtual Machine `QCOW2` image and a Boot Loader
`ISO` are required.

- VM image: the **64** bit image is recommended. Look for images named
  **vEOS64-lab-{version}.qcow2**.
- Boot loader: download the `Aboot-veos-serial-8.0.2.iso` image, which has the `serial` port
  drivers.

### Import Image

#### Aboot ISO

Every vEOS version boots from the one Aboot ISO, which Sherpa reads from
`/opt/sherpa/images/arista_eos/aboot_iso/aboot.iso`:

```
mkdir -p /opt/sherpa/images/arista_eos/aboot_iso/
cp /src/path/Aboot-veos-serial-8.0.2.iso /opt/sherpa/images/arista_eos/aboot_iso/aboot.iso
```

!!! warning

    The Aboot image must be named `aboot.iso`

#### VM Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version 4.34.4M \
  --model arista_eos \
  --default
```

### Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 4.34.4M         |
| CPU                  | 2               |
| RAM                  | 2GB             |
| CDROM                | aboot.iso       |
| CDROM Driver         | IDE             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | SATA            |
| ZTP                  | `tftp`          |
| Management Interface | Management1     |
| Data Interfaces      | eth1-52         |
| Interface Driver     | virtio          |

### Example Manifest

```toml
name = "arista-eos"

[[nodes]]
name = "dev01"
model = "arista_eos"
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

### Notes

- Approximate time for the system to be ready: `3 minutes`
- vEOS is tested with `Aboot-veos-serial-8.0.2.iso`

## Container (cEOS-lab)

Look for the 64 bit `cEOS Lab` image.

### Import Image

The download is a root filesystem archive, so it is imported into Docker with
`docker image import`, tagged with the cEOS version, and then registered with Sherpa by scanning
the local container images:

```
docker image import cEOS64-lab-4.35.1F.tar.xz localrepo/arista_eos:4.35.1F
sherpa server image scan --kind container
```

!!! warning

    cEOS images must be imported with the repo set to `localrepo/arista_eos`. The scan only
    registers images with that repo as `arista_eos` container images, and labs start cEOS from
    it. The first version registered becomes the default.

`sherpa server image import` does not work for cEOS: it loads `docker save` archives, not root
filesystem archives.

Every other image command takes `--kind container` for a cEOS image; without it, the command
means the vEOS image. For example:

```
sherpa server image set-default --model arista_eos --kind container --version 4.35.1F
```

### Default Node Parameters

| Property             | Value       |
| -------------------- | ----------- |
| Kind                 | Container   |
| CPU                  | Not limited in the sandbox |
| RAM                  | Not limited in the sandbox |
| ZTP                  | `volume`    |
| Management Interface | eth0        |
| Data Interfaces      | eth1-52     |
| Interface Driver     | virtio      |

### Example Manifest

```toml
name = "arista-eos"

[[nodes]]
name = "dev01"
model = "arista_eos"
kind = "container"
version = "4.35.1F"
```

### Node Access

=== "SSH"

    ```
    sherpa ssh dev01
    ```

=== "Console"

    ```
    sherpa console dev01
    ```

### Notes

- Approximate time for the system to be ready: `1 minutes`
- The node boots from its ZTP configuration, copied to `flash:startup-config` the first time the
  container starts. `write memory` saves to it as usual. The saved configuration is kept across `sherpa down` and
  `sherpa resume`. `sherpa redeploy` creates the node again, so it starts again from the ZTP
  configuration.
- With [`ztp.method = "disabled"`](../../manifest.md#ztp-object) the node is the image as shipped: it starts without Sherpa's startup configuration, so it has no management IP address and no `sherpa login`, and `sherpa ssh` cannot reach it. Reach it with `sherpa console <node-name>`. The node's `volumes` from the manifest are copied into the node when it is created, so you can supply a configuration of your own.

### Sandbox

The cEOS container runs in a [sandbox](../../architecture/sandboxes.md): a Flatcar VM of its own,
which Sherpa handles as a virtual machine for `down`, `resume` and `status`.

- The container is privileged in that VM, so its privileges reach the VM's kernel, not the
  server's.
- `sherpa console <node>` opens the EOS CLI on the VM's serial console: press Enter. `sherpa vnc`
  is refused.
- The VM gets the node's `memory` plus 1024 MiB and its `cpu.count` vCPUs.
- Volumes are copied when the node is created, so a change on the server needs a `sherpa redeploy`.
- The server needs the [`flatcar_sandbox`](../linux/flatcar-sandbox.md) image, which you import
  once. The sandbox has a management address of its own, named `<node>-sbx`.
- The sandbox runs the imported image of the node's model and version, from the repo that version
  was imported or pulled from, with no repo override: `sherpa up` and `sherpa redeploy` refuse a
  node whose `image` names another repo, before they create anything. To run another repo, pull
  it as a version of its own and set the node's `version` to it.
- A node is ready once SSH answers. Without the config Sherpa generates (`ztp` off, or a config of
  your own) it is ready once the container started, unless `ready_check.port` says otherwise.
