# Storage

Sherpa organises files across several directories under `/opt/sherpa/`.

## Directory Structure

```
/opt/sherpa/
├── config/
│   └── sherpa.toml          # Server configuration
├── images/                  # VM and unikernel disk images
├── containers/              # Container image archives
├── bins/                    # Unikernel binaries
├── labs/                    # Per-lab runtime files
│   └── <lab-id>/
│       ├── manifest.toml    # Saved manifest
│       ├── sherpa_ssh_config
│       ├── sherpa_known_hosts  # Recorded node host keys
│       ├── ztp/             # Generated node configs
│       └── ...
├── libvirt/
│   └── images/              # Storage pool: VM disks and ZTP media
├── ssh/                     # SSH keys
└── .certs/                  # TLS certificates
    ├── server.crt
    └── server.key
```

## Images

Base images are stored in the `images_dir` directory (default: `/opt/sherpa/images/`). These are the source disk images imported via `sherpa server image import`.

When a lab is created, Sherpa creates each VM's disk from the base image rather than modifying the original. This allows the same base image to be used across multiple labs simultaneously.

Supported disk formats: `qcow2`, `iso`, `raw`, `json`, `ign`, `img`.

### Boot Disk Overlays

By default, a virtual machine's boot disk is a QCOW2 overlay on top of the base image. The
overlay stores only the changes the VM makes, so creating a disk is fast and uses little space.
Set `boot_disk_clone_method = "copy"` in the [manifest](../manifest.md#boot_disk_clone_method-string)
to create a full independent copy instead.

- Writes are kept when a lab is stopped and resumed. Redeploy replaces the disk using the
  requested method and the image version the node was created with.
- The base image must be a standalone, unencrypted QCOW2 file. If it is not, lab creation
  fails before any resources are created, and `copy` can be used instead.
- A base image cannot be deleted while any lab disk depends on it, including disks of stopped VMs.
  Destroy those labs first.
- Auxiliary disks and configuration media are always copied.

## Containers

Container image archives are stored in the `containers_dir` directory (default: `/opt/sherpa/containers/`). Container images can also be pulled directly from OCI registries via `sherpa server image pull`.

## Unikernels

Unikernel images are stored in the `images_dir` directory alongside VM images, organised by model and version. See [Unikernel](unikernel.md#image-management).

## Libvirt Storage Pool

Sherpa creates a libvirt storage pool named `sherpa-pool` that manages VM disk volumes. The pool is a directory-backed pool with autostart enabled.

The storage pool is used for:

- Cloning base images to lab-specific disks
- Resizing boot disks (via `boot_disk_size` in the manifest)
- Deleting disk volumes during lab destroy

You can inspect the pool with:

```bash
virsh pool-list --all --detailed
virsh pool-info sherpa-pool
```

## Lab Files

Each lab gets a dedicated directory at `/opt/sherpa/labs/<lab-id>/`. This directory contains:

- The **saved manifest** used for redeploys
- **SSH configuration** files for node access
- **ZTP configuration** files generated for each node, including cloud-init `user-data`
- **TLS certificates** for the lab's nodes

VM disks and the ISO images built from ZTP configuration are copied into the storage pool,
`/opt/sherpa/libvirt/images/`.

When a lab is destroyed, its entire lab directory is cleaned up.

## Permissions

Lab files hold node configuration and the data from your manifest, so only Sherpa can read them:

| Directory | Owner | Mode | Readable by |
|---|---|---|---|
| `/opt/sherpa/labs/` | `sherpa:sherpa` | `2750` | The `sherpa` user and the `sherpa` group (administrators) |
| `/opt/sherpa/libvirt/images/` | `sherpa:kvm` | `2750` | The `sherpa` user, and QEMU, which runs in the `kvm` group |

Volumes in the storage pool are created with mode `0600`. While a VM runs, libvirt hands its
disks and ISO to the QEMU user. Flatcar's Ignition file is `0644`, because QEMU reads it
directly.

`sherpad` applies these directory modes each time it starts, and the install and update
scripts set them too. If `sherpad` cannot apply them, for example because another user owns a
directory, it logs a warning and starts anyway. Fix the owner with:

```bash
sudo install -d -o sherpa -g sherpa -m 2750 /opt/sherpa/labs
sudo install -d -o sherpa -g kvm -m 2750 /opt/sherpa/libvirt/images
```

## Client Storage

The Sherpa client stores its configuration and credentials at `~/.sherpa/`:

```
~/.sherpa/
├── config/
│   └── sherpa.toml          # Client configuration
├── ssh/                     # SSH keys
├── images/                  # Local image cache
├── containers/              # Local container cache
└── bins/                    # Local binary cache
```
