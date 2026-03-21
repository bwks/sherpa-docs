# Hashicorp Vault

Hashicorp Vault is a container based image.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/r/hashicorp/vault).

### Import Image

#### Sherpa

```
sherpa server image pull  -m hashicorp_vault -v 1.21
```

#### Docker

Sherpa uses the system's docker images, so you can also pull the image down via the `docker` cli.

```
docker image pull hashicorp/vault:1.21
```

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

nodes = [
  { name = "vault01", model = "hashicorp_vault" },
]
```

## Node Access

Vault exposes a web UI and API on port `8200`.

=== "Web UI"

    From the server host, browse to `http://<vault_mgmt_ip>:8200`.

=== "SSH Tunnel"

    ```
    ssh -L 8200:<vault_mgmt_ip>:8200 user@sherpa-server
    ```

    Then browse to `http://localhost:8200`.

=== "CLI"

    ```
    export VAULT_ADDR=http://<vault_mgmt_ip>:8200
    vault status
    ```

## Notes

- Approximate time for the system to be ready: `1 minute`
- Vault is configured with Raft integrated storage and the web UI enabled.
- TLS is disabled by default on the listener.
