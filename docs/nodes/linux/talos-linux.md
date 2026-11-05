# Talos Linux

Talos Linux is an immutable, API-managed operating system for Kubernetes. It has no SSH,
shell or console login: it is managed through the Talos API on TCP port `50000` with
[talosctl](https://docs.siderolabs.com/talos/v1.14/getting-started/talosctl), and Kubernetes
with `kubectl`.

Sherpa can run Talos nodes in two ways:

- **Sherpa-built clusters.** Declare a cluster in the manifest. Sherpa generates the cluster
  secrets and machine configs, bootstraps Kubernetes, and gives you a `kubeconfig` and
  `talosconfig`.
- **Your own configs.** Give each node a machine config you generated with `talosctl`, or
  none, so the node waits in maintenance mode.

## Base Image

Sherpa uses the NoCloud image from the [Talos Image Factory](https://factory.talos.dev). Pull
the vanilla image (no system extensions):

```
sherpa server image pull \
  --model talos_linux \
  --version 1.14.4 \
  --default
```

!!! note

    Sherpa-built clusters require Talos **1.14.x**. Talos changes its configuration format
    between minor versions, so Sherpa refuses other versions for cluster nodes. Nodes with
    your own configs can use any version.

For a custom schematic with extra system extensions, generate one at
[factory.talos.dev](https://factory.talos.dev) and pass its NoCloud image URL:

```
sherpa server image pull \
  --model talos_linux \
  --version 1.14.4 \
  --url https://factory.talos.dev/image/<schematic-id>/v1.14.4/nocloud-amd64.qcow2 \
  --default
```

Or import a downloaded image:

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --model talos_linux \
  --version 1.14.4 \
  --default
```

## Default Node Parameters

| Property             | Value                      |
| -------------------- | -------------------------- |
| Tested Version       | 1.14.4                     |
| Kind                 | Virtual Machine            |
| CPU                  | 2                          |
| RAM                  | 4GB                        |
| Boot Disk            | 20GB                       |
| CDROM Driver         | SATA                       |
| DISK                 | virtioa.qcow2              |
| DISK Driver          | virtio                     |
| ZTP Method           | NoCloud CD-ROM             |
| Management Interface | eth0 (static address)      |
| Data Interfaces      | eth1                       |
| Interface Driver     | virtio                     |
| Readiness            | Talos API, TCP port 50000 (cluster workers: Ready Kubernetes node) |

The image is about 4 GB; Talos needs at least 10 GB, so nodes get a 20 GB boot disk unless
`boot_disk_size` is set.

## Sherpa-Built Clusters

Declare clusters with [`talos_clusters`](../../manifest.md#talos_clusters-listtalos_cluster_object). Each cluster lists its
`controllers` (the control plane) and `workers` by node name:

```toml
name = "k8s-lab"

[[talos_clusters]]
name = "k8s"
controllers = ["cp01"]
workers = ["worker01", "worker02"]

[[nodes]]
name = "cp01"
model = "talos_linux"

[[nodes]]
name = "worker01"
model = "talos_linux"

[[nodes]]
name = "worker02"
model = "talos_linux"
```

`sherpa up` then:

1. generates the cluster's certificate authorities, keys and tokens, and a machine config for
   each node, delivered on the node's NoCloud CD-ROM;
2. waits for each controller's Talos API;
3. bootstraps etcd on the first controller and waits for every node to be a Ready
   Kubernetes node. Workers are only checked here: a worker's Talos API starts once it can
   reach the cluster, which with three controllers is through the shared address that comes
   up after the bootstrap;
4. writes `kubeconfig-<cluster>` and `talosconfig-<cluster>` to your working directory,
   readable only by you.

```
export KUBECONFIG=$PWD/kubeconfig-k8s TALOSCONFIG=$PWD/talosconfig-k8s
kubectl get nodes
talosctl -n <node-ip> version
```

`sherpa download` writes the same files again.

### Control plane endpoint

A cluster has one or three controllers. Two are refused: etcd needs a majority of its members
to stay up, so two controllers survive no failure and are less available than one.

- One controller: the Kubernetes API is on that node's management address.
- Three controllers: Sherpa reserves a shared address (a Talos
  [VIP](https://docs.siderolabs.com/talos/v1.14/networking/advanced/vip)) from the lab's
  management network: `.11` for the first such cluster, `.12` for the second. The
  controllers elect which of them holds it. A lab can have up to two such clusters. See
  [IP addressing](../../architecture/networking/ip-addressing.md#addresses-in-a-range).

If a cluster has no workers, workloads are allowed on its controllers.

### Cilium

Set `cni = "cilium"` on a cluster to run [Cilium](https://cilium.io) instead of Flannel:

```toml
[[talos_clusters]]
name = "k8s"
controllers = ["cp01", "cp02", "cp03"]
workers = ["worker01", "worker02"]
cni = "cilium"
```

Talos installs Cilium while the cluster bootstraps, so the nodes are Ready when `sherpa up`
finishes. The cluster gets:

- **Cilium 1.20.4** as the CNI, replacing kube-proxy.
- **Load balancer addresses** on the lab's management network, announced by Cilium. Sherpa
  reserves four for each Cilium cluster: `.13`–`.16` for the first, `.17`–`.20` for the
  second. A lab can have up to two Cilium clusters. See
  [IP addressing](../../architecture/networking/ip-addressing.md#addresses-in-a-range).
- **A Gateway** named `sherpa`, in the `default` namespace, at the first address. It accepts
  HTTP on port 80 for [HTTPRoutes](https://gateway-api.sigs.k8s.io/api-types/httproute/) from
  any namespace. The Gateway API CRDs (v1.6.3, standard channel) are installed.
- **Hubble UI**, Cilium's view of traffic between pods, at the second address.
- The other two addresses for your own `LoadBalancer` services.

`sherpa up` and `sherpa download` print the Gateway and Hubble UI addresses:

```
✅ Cluster k8s credentials: kubeconfig-k8s and talosconfig-k8s
   export KUBECONFIG=kubeconfig-k8s TALOSCONFIG=talosconfig-k8s
   Gateway: http://172.31.1.13
   Hubble UI: http://172.31.1.14
```

Route a service through the Gateway:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
  namespace: my-namespace
spec:
  parentRefs:
    - name: sherpa
      namespace: default
  rules:
    - backendRefs:
        - name: my-app
          port: 80
```

The Cilium settings are fixed. Cilium's images are pulled from `quay.io` when the cluster
starts, so nodes need internet access, as they do for the Kubernetes images.

See the [Kubernetes example](../../examples/kubernetes.md) for a cluster to try it on.

### Cluster defaults

| Setting            | Value                                 |
| ------------------ | ------------------------------------- |
| Kubernetes version | 1.37.1 (the Talos 1.14 default)       |
| CNI                | Flannel, or [Cilium](#cilium)         |
| Pod network        | `10.244.0.0/16`                       |
| Service network    | `10.96.0.0/12`                        |
| Pod Security       | `baseline` enforced                   |

The lab's management network must not overlap the pod or service networks.

### Stopping nodes

Talos ignores the ACPI power button. `sherpa down` shuts cluster nodes down through the Talos
API instead, as `talosctl shutdown` does: each node is cordoned and drained, then powers off.
Workers stop before controllers. A node still running after 60 seconds is powered off.

Talos nodes that are not in a Sherpa-built cluster are powered off directly, because Sherpa has
no credentials for their Talos API. Shut them down with `talosctl shutdown` first if they must
stop cleanly.

### Redeploy

- A **worker** can be redeployed: it is rebuilt from the cluster's saved secrets and rejoins.
- A **controller** cannot: its etcd member would have to be removed first. Destroy and
  recreate the lab instead.

## Your Own Configs

Generate machine configs with `talosctl`:

```
talosctl gen config my-cluster https://<controlplane-ip>:6443
```

Reference each node's config with [`ztp_config`](../../manifest.md#ztp_config-string). It is
delivered byte for byte as the node's NoCloud `user-data`, alongside Sherpa's static
management network settings. Drop the `UnattendedInstallConfig` document: the NoCloud image is
already installed.

A node **without** a `ztp_config` boots into maintenance mode with its management address and
waits to be configured:

```
talosctl apply-config --insecure -n <node-ip> --file controlplane.yaml
```

```toml
name = "talos-byo"

[[nodes]]
name = "cp01"
model = "talos_linux"
ztp_config = "controlplane.yaml"

[[nodes]]
name = "worker01"
model = "talos_linux"
ztp_config = "worker.yaml"

[[nodes]]
name = "spare01"
model = "talos_linux"
```

With your own configs you run `talosctl bootstrap` and fetch the kubeconfig yourself.

## Node Access

There is no SSH or console access. `sherpa ssh` and `sherpa console` do not apply to Talos
nodes, and they are left out of the lab's SSH config. Use `talosctl` and `kubectl`.

## Notes

- Nodes pull Kubernetes images from `ghcr.io` and `registry.k8s.io` through the lab's NAT,
  so the Sherpa server needs internet access.
- Sherpa-built clusters do not use the Talos discovery service.
- A node is reported ready when its Talos API answers. Maintenance mode also answers, so for
  your own configs **ready means reachable, not configured**. Override with `ready_port`.
- Approximate time from power-on to a Ready cluster: about 2 minutes.
