# Talos Linux

Talos Linux is an immutable, API-managed Kubernetes OS. There is no SSH, shell, or
console login — all management goes through the Talos gRPC API on TCP port `50000`
using [talosctl](https://docs.talos.dev/latest/talos-guides/install/talosctl/).

## Base Image

Ready-made `nocloud` qcow2 images are published by the
[Talos Image Factory](https://factory.talos.dev).

Sherpa can download the image automatically. The vanilla (no system extensions)
schematic ID is resolved from the Image Factory API at download time — you do not
need to know or supply it:

```
sherpa server image pull \
  --model talos_linux \
  --version 1.10.5 \
  --default
```

!!! note

    Pass the version without a leading `v` (`1.10.5`, not `v1.10.5`).

For a custom schematic (extra system extensions), generate one at
[factory.talos.dev](https://factory.talos.dev) and pass its image URL directly:

```
sherpa server image pull \
  --model talos_linux \
  --version 1.10.5 \
  --url https://factory.talos.dev/image/<schematic-id>/v1.10.5/nocloud-amd64.qcow2 \
  --default
```

Alternatively, import a locally downloaded image:

```
sherpa server image import \
  --src nocloud-amd64.qcow2 \
  --model talos_linux \
  --version 1.10.5 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 1.10.5          |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 4GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | CDROM (nocloud) |
| Management Interface | eth0            |
| Data Interfaces      | eth1            |
| Interface Driver     | virtio          |

!!! warning

    Talos requires at least a `10GB` disk to install. Set `boot_disk_size = 10`
    (or larger) on each Talos node if the imported image's virtual disk is smaller.

## Machine Configs

Generate machine configs with talosctl — Sherpa does not generate them (cluster PKI
stays in your hands):

```
talosctl gen config my-cluster https://<controlplane-ip>:6443
```

Reference the generated YAML per node via the `ztp_config` manifest parameter. The
config is delivered to the node verbatim on a `nocloud` seed ISO.

A node **without** a `ztp_config` boots into maintenance mode and waits to be
configured over the network:

```
talosctl apply-config --insecure -n <node-ip> --file controlplane.yaml
```

## Example Manifest

```toml
name = "talos-cluster"

nodes = [
  { name = "cp01", model = "talos_linux", boot_disk_size = 10, ztp_config = "controlplane.yaml" },
  { name = "worker01", model = "talos_linux", boot_disk_size = 10, ztp_config = "worker.yaml" },
  { name = "spare01", model = "talos_linux", boot_disk_size = 10 },
]
```

`cp01` and `worker01` boot fully configured; `spare01` boots to maintenance mode.

## Node Access

There is no SSH or console access — `sherpa ssh` and `sherpa console` do not apply
to Talos nodes, and they are excluded from the generated lab ssh_config.

=== "talosctl"

    ```
    talosctl -n <node-ip> -e <node-ip> version
    ```

=== "Bootstrap Kubernetes"

    Once the control plane node is up:

    ```
    talosctl bootstrap -n <cp-ip> -e <cp-ip> --talosconfig=./talosconfig
    talosctl kubeconfig -n <cp-ip> -e <cp-ip> --talosconfig=./talosconfig
    kubectl get nodes
    ```

## Notes

- Node readiness is detected on TCP port `50000` (the Talos API). Maintenance mode
  also listens on this port, so **Ready means the Talos API is reachable, not that
  the node is configured**. Override with the `ready_port` manifest parameter if needed.
- Approximate time for the system to be ready: `1 minute`; a bootstrapped Kubernetes
  control plane takes a few minutes more.
