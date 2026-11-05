# Kubernetes

Sherpa builds and bootstraps a Kubernetes cluster on [Talos Linux](../nodes/linux/talos-linux.md#sherpa-built-clusters)
nodes, with [Cilium](../nodes/linux/talos-linux.md#cilium) as its network. This example has three
controllers, which share a virtual IP for the Kubernetes API, and two workers. Cilium replaces
kube-proxy, gives the cluster a Gateway on the lab's management network, and shows the traffic
between pods in Hubble.

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
- **Virtual IP.** The controllers share an address on the management network, `.11`, which
  follows whichever controller holds it. The Kubernetes API stays on that address if a
  controller fails.
- **Gateway.** A [Gateway API](https://gateway-api.sigs.k8s.io) Gateway named `sherpa` at
  `.13`. Route HTTP to your services with HTTPRoutes.
- **Hubble UI** at `.14`: a live map of which pods talk to which, and what policy drops.

There are no data plane links: the nodes talk to each other, and Kubernetes pods talk across
nodes, over the management network. The addresses are in the lab's management network, so
`.13` is `172.31.1.13` in a lab on `172.31.1.0/24`. `sherpa up` prints them.

Running it takes about 20 GB of memory on the Sherpa server: each node has 4 GB.

## Manifest

```toml
name = "sherpa-kubernetes"

[[talos_clusters]]
name = "k8s"
controllers = ["cp01", "cp02", "cp03"]
workers = ["wrk01", "wrk02"]
cni = "cilium"

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
directory, and the output ends with the cluster's addresses:

```
✅ Cluster k8s credentials: kubeconfig-k8s and talosconfig-k8s
   export KUBECONFIG=kubeconfig-k8s TALOSCONFIG=talosconfig-k8s
   Gateway: http://172.31.1.13
   Hubble UI: http://172.31.1.14
```

Use `kubectl` for Kubernetes and `talosctl` for the Talos nodes:

```
export KUBECONFIG=$PWD/kubeconfig-k8s TALOSCONFIG=$PWD/talosconfig-k8s
kubectl get nodes
talosctl -n <node-ip> version
```

Talos nodes have no SSH or shell, so `sherpa ssh` does not apply. If you lose the config files,
`sherpa download` writes them again.

## Try It

The steps below use the addresses of a lab on `172.31.1.0/24`; use the ones `sherpa up`
printed.

### Publish an app through the Gateway

Run two replicas of an echo server and route the Gateway to them:

```
kubectl create namespace demo
kubectl -n demo create deployment echo --image=registry.k8s.io/echoserver:1.10 --replicas=2
kubectl -n demo expose deployment echo --port=80 --target-port=8080
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo
  namespace: demo
spec:
  parentRefs:
    - name: sherpa
      namespace: default
  rules:
    - backendRefs:
        - name: echo
          port: 80
EOF
```

Each request answers from one of the two pods:

```
curl -s http://172.31.1.13/ | grep Hostname
```

Open the Hubble UI at `http://172.31.1.14` and pick the `demo` namespace to watch the
requests arrive.

### Block it with a network policy

Deny all traffic into the `demo` namespace:

```
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: demo
spec:
  podSelector: {}
  policyTypes: [Ingress]
EOF
```

`curl` now times out, and Hubble shows the requests dropped by policy. Allow traffic from the
Gateway only, with a Cilium policy:

```
kubectl apply -f - <<'EOF'
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-gateway
  namespace: demo
spec:
  endpointSelector:
    matchLabels:
      app: echo
  ingress:
    - fromEntities: [ingress]
EOF
```

The Gateway reaches the pods again, while other pods in the cluster still cannot.
