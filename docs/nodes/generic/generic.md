# Generic

The `generic` model runs an image Sherpa has no model of its own for, as a virtual machine, a
container or a unikernel. It has no default kind: every `generic` node sets `kind`, and every
image command for `generic` sets `--kind`.

| Kind              | Manifest                                         |
| ----------------- | ------------------------------------------------ |
| `virtual_machine` | `model = "generic"`, `kind = "virtual_machine"`  |
| `container`       | `model = "generic"`, `kind = "container"`        |
| `unikernel`       | `model = "generic"`, `kind = "unikernel"`        |

A `generic` node without `kind` is refused:
``Manifest - node: 'g1' sets no `kind`, which 'generic' needs; set it to one of: virtual_machine, container, unikernel``.

## Virtual machine

### Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version model-version \
  --model generic \
  --kind virtual_machine
```

### Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| CPU                  | 1               |
| RAM                  | 1GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `cloud-init`    |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

The image must run `cloud-init` with the NoCloud data source, like a Linux cloud image. Sherpa
sets it up as a Linux VM: the management address and
[your login](../../architecture/personal-accounts.md), with your SSH keys, your
[device password](../../architecture/device-password.md) and passwordless `sudo`. For an image without `cloud-init`, turn off ZTP on the image's
edit page in the web UI (**Admin > Images**), so it boots without ZTP.

### Example Manifest

```toml
name = "generic-vm"

[[nodes]]
name = "dev01"
model = "generic"
kind = "virtual_machine"
version = "model-version"
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

## Container

### Import Image

Pull the image through Sherpa, giving the image reference with its tag:

```
sherpa server image pull --model generic --kind container --repo nginx:1.29.4-perl
```

Sherpa records the version (`1.29.4-perl`) and the repo it was pulled from (`nginx`). A node with
that version runs that repo, unless it sets `image` in the manifest. An image already pulled
with the `docker` CLI is not known to Sherpa until it is scanned. `generic` has no built-in repo,
so give the scan the model and the repo, without a tag; it records each local tag of the repo as
a version, with that repo:

```
docker pull nginx:1.29.4-perl
sherpa server image scan --kind container --model generic --repo nginx
```

Sherpa tells generic images apart by version, so two images with the same tag (such as
`nginx:latest` and `redis:latest`) share one entry, holding the repo pulled last. Set `image` on
each node to pick between them.

### Default Node Parameters

| Property             | Value       |
| -------------------- | ----------- |
| Kind                 | Container   |
| CPU                  | Not limited |
| RAM                  | Not limited |
| ZTP                  | `disabled`  |
| Management Interface | eth0        |
| Interface Driver     | macvlan     |

Containers run without CPU or memory limits unless the manifest sets them: `memory` is a hard
memory limit and `cpu.count` a CPU quota. See
[Container CPU and memory limits](../../manifest.md#container-cpu-and-memory-limits).

### Example Manifest

```toml
name = "generic-container"

[[nodes]]
name = "dev01"
model = "generic"
kind = "container"
image = "nginx"
version = "1.29.4-perl"
```

### Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Docker"

    ```
    docker exec -it <node-name>-<lab-id> sh
    ```

## Unikernel

### Import Image

```
sherpa server image import \
  --src <path-to-image> \
  --version <version> \
  --model generic \
  --kind unikernel
```

### Default Node Parameters

| Property             | Value        |
| -------------------- | ------------ |
| Kind                 | Unikernel    |
| CPU                  | 1            |
| RAM                  | 512 MiB      |
| Boot Mode            | DirectKernel |
| ZTP                  | `disabled`   |
| Management Interface | eth0         |
| Interface Driver     | virtio       |

### Example Manifest

```toml
name = "generic-unikernel"

[[nodes]]
name = "dev01"
model = "generic"
kind = "unikernel"
version = "v1.0.0"

[nodes.ready_check]
port = 80

[nodes.unikernel]
cmdline = "/usr/bin/nginx"
```

### Node Access

=== "Console"

    ```
    sherpa console <node-name>
    ```

### Notes

- Boot mode is `direct_kernel` by default — the kernel ELF binary is loaded directly by QEMU
- Use `unikernel.cmdline` to specify the application entry point or pass runtime arguments to the unikernel
- Use `ready_check.port` to have Sherpa wait for a TCP port to become available before marking the node as ready
- ZTP is disabled by default; configure it in the manifest if needed
