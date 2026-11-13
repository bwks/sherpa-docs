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

Sherpa records the version, so a lab can use it. An image already pulled with the `docker` CLI
is not known to Sherpa until it is scanned. The scan records each local tag of `hashicorp/vault` as a
version:

```
docker pull hashicorp/vault:1.21
sherpa server image scan --container
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | Not limited |
| RAM                  | Not limited |
| ZTP                  | `disabled`|
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

### When Initialisation Fails

Vault hands out the unseal key and root token once, in its answer to the init request. Sherpa
waits up to 90 seconds for it, since Vault is slow to initialise while a lab is starting. If the
request fails, Sherpa checks Vault's status again before doing anything else:

- Vault is not initialised: Sherpa sends the init request once more.
- Vault is initialised: Vault completed the init but Sherpa never got its answer, so nobody has
  the unseal key or root token. `sherpa up` reports:

    ```
    Vault node 'vault01' is initialised, but Sherpa lost the init response carrying its unseal
    key and root token: ...
    ```

Sherpa does not reset the node's Vault data on its own. To recover, run this in the lab
directory:

```
sherpa redeploy --node vault01
```

The node starts again with empty Vault storage, and Sherpa initialises it, unseals it and writes
its new credentials. Anything already written to that Vault is lost.

A Vault that was already initialised before Sherpa sent any init, with no credentials saved by
Sherpa, is reported as "initialised outside Sherpa" instead. `sherpa redeploy` resets that node
the same way.

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

A node with its own [`ztp.config`](../../manifest.md) runs that config instead. Vault's ZTP
setting is `disabled`, and it is the one node that takes a `ztp.config` with ZTP off: the file
is Vault's own configuration. Sherpa then
does not initialise or unseal it, and sets `VAULT_ADDR=http://127.0.0.1:8200` in the container.
The lab certificate is still mounted at `/etc/sherpa/certs/` for your config to use.

## Notes

- Approximate time for the system to be ready: `1 minute`
- Vault is configured with Raft integrated storage and the web UI enabled.
- Vault's data is kept in the container. `sherpa down` and `sherpa resume` pause and resume
  it, so it stays unsealed. `sherpa redeploy` starts an empty Vault: Sherpa initialises it again,
  writes its new root token and unseal key, and sets it up again for the clusters that use it.
  Secrets you wrote are gone.
