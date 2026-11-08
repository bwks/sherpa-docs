# Hashicorp Vault

Hashicorp Vault is a container based image. Sherpa serves its API over HTTPS with the node's
[lab certificate](../../architecture/certificates.md), then initialises and unseals it, so Vault
is ready to use when `sherpa up` finishes.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/r/hashicorp/vault).

### Import Image

Pull the image through Sherpa:

```
sherpa server image pull --model hashicorp_vault --version 1.21
```

Sherpa records the version, so a lab can use it. An image pulled only with the `docker` CLI is
not known to Sherpa, so a lab cannot use it.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 1         |
| RAM                  | 1GB       |
| ZTP Method           | None      |
| Management Interface | eth0      |
| Interface Driver     | macvlan   |

## Example Manifest

```toml
name = "hashicorp-vault"

[[nodes]]
name = "vault01"
model = "hashicorp_vault"
```

## Initialisation

After the node starts, Sherpa initialises Vault with a single unseal key, unseals it, and keeps
the unseal key and root token with the lab's files on the server. `sherpa up` and
`sherpa download` write them to `.sherpa/vault/vault-<node>.toml` in your working directory,
readable only by you, next to the lab's `.sherpa/ca/lab-ca.crt`:

```toml
address = "https://172.31.1.21:8200"
root_token = "hvs.…"
unseal_key = "…"
```

`sherpa up` prints how to point the `vault` CLI at the node:

```
✅ Vault vault01 credentials: /home/user/lab/.sherpa/vault/vault-vault01.toml
   export VAULT_ADDR=https://172.31.1.21:8200 VAULT_CACERT=/home/user/lab/.sherpa/ca/lab-ca.crt
```

!!! warning

    The root token has full access to Vault. Keep `.sherpa/vault/vault-<node>.toml` private, and
    create narrower tokens or auth methods for anything else.

## Node Access

Vault serves its web UI and API over HTTPS on port `8200`, on the node's management address.

=== "Web UI"

    Browse to `https://<vault_mgmt_ip>:8200` and sign in with the root token. Your browser
    trusts the page once you import `.sherpa/ca/lab-ca.crt`; see
    [Lab Certificates](../../architecture/certificates.md).

=== "CLI"

    ```
    export VAULT_ADDR=https://<vault_mgmt_ip>:8200 VAULT_CACERT=$PWD/.sherpa/ca/lab-ca.crt
    export VAULT_TOKEN=<root_token>
    vault status
    ```

=== "Inside the node"

    `VAULT_ADDR` and `VAULT_CACERT` are already set in the container:

    ```
    docker exec -it <container> vault status
    ```

## Kubernetes Clusters

A [Kubernetes cluster](../linux/talos-linux.md#vault-secrets) that sets `vault` to this node
gets the Vault Secrets Operator. For each such cluster, Sherpa sets up Vault:

| | |
| - | - |
| Secrets engine | KV version 2 at `secret/` |
| Auth method | `kubernetes-<cluster>`, which accepts the cluster's service account tokens |
| Role | `workload`, for any service account in the cluster |
| Policy | `kubernetes-<cluster>`: read the secrets under `secret/<cluster>/` |

## Your Own Config

A node with its own [`ztp_config`](../../manifest.md) runs that config instead. Sherpa then
does not initialise or unseal it, and sets `VAULT_ADDR=http://127.0.0.1:8200` in the container.
The lab certificate is still mounted at `/etc/sherpa/certs/` for your config to use.

## Notes

- Approximate time for the system to be ready: `1 minute`
- Vault is configured with Raft integrated storage and the web UI enabled.
- Vault's data is kept in the container. `sherpa down` and `sherpa resume` pause and resume
  it, so it stays unsealed. `sherpa redeploy` starts an empty Vault: Sherpa initialises it again,
  writes its new root token and unseal key, and sets it up again for the clusters that use it.
  Secrets you wrote are gone.
