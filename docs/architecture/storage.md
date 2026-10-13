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
│       ├── <node>.qcow2     # Cloned VM disks
│       ├── ssh_config       # Lab SSH config
│       └── ...
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

- **Cloned disk images** for each VM node in the lab
- **SSH configuration** files for node access
- **ZTP configuration** files generated for each node
- **Cloud-init** ISO images (for VMs using cloud-init ZTP)

When a lab is destroyed, its entire lab directory is cleaned up.

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
