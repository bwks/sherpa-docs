# Kubernetes

Sherpa builds and bootstraps a Kubernetes cluster on [Talos Linux](../nodes/linux/talos-linux.md#sherpa-built-clusters)
nodes. This example has three controllers, which share a virtual IP for the Kubernetes API,
and two workers.

![A Talos Linux Kubernetes cluster with three controllers and two workers on the management network](kubernetes.svg)

| Role       | Nodes                    | Model                                           |
| ---------- | ------------------------ | ----------------------------------------------- |
| Controller | `cp01`, `cp02`, `cp03`   | [Talos Linux](../nodes/linux/talos-linux.md)    |
| Worker     | `wrk01`, `wrk02`         | [Talos Linux](../nodes/linux/talos-linux.md)    |

- **Controllers** run the Kubernetes control plane and etcd. Three controllers let the
  cluster survive the loss of one, because etcd keeps a majority with two of three members.
  A cluster has either one or three controllers.
- **Workers** run your workloads. With no workers, workloads would be allowed on the
  controllers instead.
- **Virtual IP.** The controllers share an address on the management network, which follows
  whichever controller holds it. The Kubernetes API stays on that address if a controller
  fails.

There are no data plane links: the nodes talk to each other, and Kubernetes pods talk across
nodes, over the management network.

## Manifest

```toml
name = "sherpa-kubernetes"

[[talos_clusters]]
name = "k8s"
controllers = ["cp01", "cp02", "cp03"]
workers = ["wrk01", "wrk02"]

[[nodes]]
name = "cp01"
model = "talos_linux"

[[nodes]]
name = "cp02"
model = "talos_linux"

[[nodes]]
name = "cp03"
model = "talos_linux"

[[nodes]]
name = "wrk01"
model = "talos_linux"

[[nodes]]
name = "wrk02"
model = "talos_linux"
```

## Access

After `sherpa up`, the cluster's `kubeconfig-k8s` and `talosconfig-k8s` are in your working
directory. Use `kubectl` for Kubernetes and `talosctl` for the Talos nodes:

```
export KUBECONFIG=$PWD/kubeconfig-k8s TALOSCONFIG=$PWD/talosconfig-k8s
kubectl get nodes
talosctl -n <node-ip> version
```

Talos nodes have no SSH or shell, so `sherpa ssh` does not apply. If you lose the config files,
`sherpa download` writes them again.
