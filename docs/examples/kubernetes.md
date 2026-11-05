# Kubernetes

Sherpa builds and bootstraps a Kubernetes cluster on [Talos Linux](../nodes/linux/talos-linux.md#sherpa-built-clusters)
nodes, with [Cilium](../nodes/linux/talos-linux.md#cilium) as its network. This example has three
controllers, which share a virtual IP for the Kubernetes API, and two workers. Cilium replaces
kube-proxy, gives the cluster a Gateway on the lab's management network, and shows the traffic
between pods in Hubble. Users log in to the cluster through Keycloak, and workloads read their
secrets from Vault.

![A Talos Linux Kubernetes cluster with three controllers and two workers, and Keycloak and Vault containers, on the management network](kubernetes.svg)

| Role       | Nodes                    | Model                                                   |
| ---------- | ------------------------ | ------------------------------------------------------- |
| Controller | `cp01`, `cp02`, `cp03`   | [Talos Linux](../nodes/linux/talos-linux.md)            |
| Worker     | `wrk01`, `wrk02`         | [Talos Linux](../nodes/linux/talos-linux.md)            |
| Identity   | `kc01`                   | [Keycloak](../nodes/keycloak/keycloak-server.md)        |
| Secrets    | `vault01`                | [Hashicorp Vault](../nodes/hashicorp/hashicorp-vault.md) |

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
- **Keycloak login.** The cluster accepts users of `kc01`'s `sherpa` realm; its
  `cluster-admins` group are cluster admins. See
  [Keycloak login](../nodes/linux/talos-linux.md#keycloak-login).
- **Vault secrets.** The Vault Secrets Operator syncs secrets from `vault01` into Kubernetes
  Secrets. See [Vault secrets](../nodes/linux/talos-linux.md#vault-secrets).

There are no data plane links: the nodes talk to each other, and Kubernetes pods talk across
nodes, over the management network. The addresses are in the lab's management network, so
`.13` is `172.31.1.13` in a lab on `172.31.1.0/24`. `sherpa up` prints them.

Running it takes about 23 GB of memory on the Sherpa server: each Talos node has 4 GB, Keycloak
2 GB and Vault 1 GB.

## Manifest

```toml
name = "sherpa-kubernetes"

[[talos_clusters]]
name = "k8s"
controllers = ["cp01", "cp02", "cp03"]
workers = ["wrk01", "wrk02"]
cni = "cilium"
oidc = "kc01"
vault = "vault01"

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

[[nodes]]
name = "kc01"
model = "keycloak_server"

[[nodes]]
name = "vault01"
model = "hashicorp_vault"
```

## Access

After `sherpa up`, your working directory has the cluster's `kubeconfig-k8s` and
`talosconfig-k8s`, the lab CA in `lab-ca.crt`, Vault's root token in `vault-vault01.toml`, and
the Keycloak realm's users in `keycloak-kc01.toml`. The output ends with:

```
✅ Lab CA certificate: /home/user/k8s/lab-ca.crt
✅ Vault vault01 credentials: /home/user/k8s/vault-vault01.toml
   export VAULT_ADDR=https://172.31.1.24:8200 VAULT_CACERT=/home/user/k8s/lab-ca.crt
✅ Keycloak kc01 users: /home/user/k8s/keycloak-kc01.toml
   Realm issuer: https://172.31.1.23:8443/realms/sherpa
✅ Cluster k8s credentials: /home/user/k8s/kubeconfig-k8s and /home/user/k8s/talosconfig-k8s
   export KUBECONFIG=/home/user/k8s/kubeconfig-k8s TALOSCONFIG=/home/user/k8s/talosconfig-k8s
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

### Log in through Keycloak

Install the [kubelogin](https://github.com/int128/kubelogin) plugin, for example with
`kubectl krew install oidc-login`, and use the kubeconfig's `oidc@k8s` context:

```
kubectl --context oidc@k8s auth whoami
```

A browser opens at Keycloak. Sign in as yourself, with the password from `keycloak-kc01.toml`,
and `kubectl` shows you as `oidc:<username>` in the group `oidc:cluster-admins`.

To give someone read-only access, add a user in Keycloak's admin console
(`https://172.31.1.23:8443/admin/`, as `sherpa`) to the `sherpa` realm and the
`cluster-viewers` group. They can read resources but not change them.

### Read a secret from Vault

Point the `vault` CLI at the node and write a secret under the cluster's path:

```
export VAULT_ADDR=https://172.31.1.24:8200 VAULT_CACERT=$PWD/lab-ca.crt
export VAULT_TOKEN=<root_token from vault-vault01.toml>
vault kv put secret/k8s/demo password=s3cret
```

Sync it into the `demo` namespace:

```
kubectl apply -f - <<'EOF'
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: demo
  namespace: demo
spec:
  type: kv-v2
  mount: secret
  path: k8s/demo
  destination:
    name: demo
    create: true
  refreshAfter: 30s
EOF
kubectl -n demo get secret demo -o jsonpath='{.data.password}' | base64 -d
```

Change the secret with `vault kv put` and the Kubernetes Secret follows within 30 seconds.
Secrets outside `secret/k8s/` are refused to the cluster.
