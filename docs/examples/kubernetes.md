# Kubernetes

Sherpa builds and bootstraps a Kubernetes cluster on [Talos Linux](../nodes/linux/talos-linux.md#sherpa-built-clusters)
nodes, with [Cilium](../nodes/linux/talos-linux.md#cilium) as its network. This example has three
controllers, which share a virtual IP for the Kubernetes API, and two workers. Cilium replaces
kube-proxy, gives the cluster a Gateway on the lab's management network, and shows the traffic
between pods in Hubble. Users log in to the cluster through Keycloak, and workloads read their
secrets from Vault. A util node has the tools to work with all of it.

![A Talos Linux Kubernetes cluster with three controllers and two workers, Keycloak and Vault containers, and a util VM, on the management network](kubernetes.svg)

| Role       | Nodes                    | Model                                                   |
| ---------- | ------------------------ | ------------------------------------------------------- |
| Controller | `cp01`, `cp02`, `cp03`   | [Talos Linux](../nodes/linux/talos-linux.md)            |
| Worker     | `wrk01`, `wrk02`         | [Talos Linux](../nodes/linux/talos-linux.md)            |
| Identity   | `kc01`                   | [Keycloak](../nodes/keycloak/keycloak-server.md)        |
| Secrets    | `vault01`                | [Hashicorp Vault](../nodes/hashicorp/hashicorp-vault.md) |
| Tools      | `util`                   | [Ubuntu](../nodes/linux/ubuntu-linux.md)                |

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
- **Util node.** An Ubuntu VM with `kubectl`, `talosctl`, the `kubectl oidc-login` plugin, the
  `vault` CLI and the `cilium` CLI, installed by a startup script on its first boot. It trusts
  the lab CA, so the tools reach Keycloak and Vault over HTTPS without extra settings.

There are no data plane links: the nodes talk to each other, and Kubernetes pods talk across
nodes, over the management network. The addresses are in the lab's management network, so
`.13` is `172.31.1.13` in a lab on `172.31.1.0/24`. `sherpa up` prints them.

Running it takes about 25 GB of memory on the Sherpa server: each Talos node has 4 GB, Keycloak
and the util node 2 GB each, and Vault 1 GB.

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

[[nodes]]
name = "util"
model = "ubuntu_linux"
memory = 2048
boot_disk_size = 10
startup_scripts = ["kubernetes-install-tools.sh"]
```

Save [`kubernetes-install-tools.sh`](kubernetes-install-tools.sh) next to the manifest. On the
util node's first boot it installs:

| Tool | Version |
| ---- | ------- |
| `kubectl` | 1.37.1, the cluster's Kubernetes version |
| `talosctl` | 1.14.4 |
| `kubectl oidc-login` ([kubelogin](https://github.com/int128/kubelogin)) | 1.36.4 |
| `vault` | 1.21.4 |
| `cilium` | 0.20.2 |

Each download is pinned and checked against its published SHA-256. The util node gets more
memory and disk than an Ubuntu node's defaults (1 GB and the image's 2.3 GB), which the tools
need.

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

Copy the credential files to the util node and log in to it. Its SSH host name is
`util.<lab-id>`, as in `sherpa_ssh_config`:

```
scp -F sherpa_ssh_config kubeconfig-k8s talosconfig-k8s vault-vault01.toml keycloak-kc01.toml util.<lab-id>:
sherpa ssh util
```

Use `kubectl` for Kubernetes and `talosctl` for the Talos nodes:

```
export KUBECONFIG=$HOME/kubeconfig-k8s TALOSCONFIG=$HOME/talosconfig-k8s
kubectl get nodes
talosctl -n <node-ip> version
cilium status
```

The tools work from your workstation too, if you install them there. Talos nodes have no SSH
or shell, so `sherpa ssh` does not apply to them. If you lose the config files,
`sherpa download` writes them again.

## Try It

Run the steps below on the util node. They use the addresses of a lab on `172.31.1.0/24`; use
the ones `sherpa up` printed.

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

The kubeconfig's `oidc@k8s` context logs in through Keycloak in a browser. On a workstation
with the [kubelogin](https://github.com/int128/kubelogin) plugin (for example
`kubectl krew install oidc-login`):

```
kubectl --context oidc@k8s auth whoami
```

A browser opens at Keycloak. Sign in as yourself, with the password from `keycloak-kc01.toml`,
and `kubectl` shows you as `oidc:<username>` in the group `oidc:cluster-admins`.

The util node has no browser. Add a context there that asks for the username and password
instead:

```
kubectl config set-credentials oidc-password@k8s \
  --exec-api-version=client.authentication.k8s.io/v1 \
  --exec-command=kubectl \
  --exec-arg=oidc-login --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=https://172.31.1.23:8443/realms/sherpa \
  --exec-arg=--oidc-client-id=kubernetes \
  --exec-arg=--grant-type=password \
  --exec-interactive-mode=IfAvailable
kubectl config set-context oidc-password@k8s --cluster=k8s --user=oidc-password@k8s
kubectl --context oidc-password@k8s auth whoami
```

To give someone read-only access, add a user in Keycloak's admin console
(`https://172.31.1.23:8443/admin/`, as `sherpa`) to the `sherpa` realm and the
`cluster-viewers` group. They can read most resources, but not change them or read Secrets.

### Read a secret from Vault

Point the `vault` CLI at the node and write a secret under the cluster's path. The util node
trusts the lab CA; on a workstation, also set `VAULT_CACERT=$PWD/lab-ca.crt`.

```
export VAULT_ADDR=https://172.31.1.24:8200
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
