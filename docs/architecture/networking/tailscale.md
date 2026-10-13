# Tailscale

Sherpa can connect a lab to your [Tailscale](https://tailscale.com) tailnet. It creates one
gateway per lab that makes the lab's management addresses reachable from your other tailnet
devices. Lab nodes do not need Tailscale installed.

## Requirements

- A Linux Sherpa server with Docker, `/dev/net/tun` and nftables.
- Server TLS enabled, and a client connected over WSS with certificate validation.
  Plaintext connections and `--insecure` are rejected.
- A Tailscale **auth key** from your own tailnet. OAuth client secrets are not supported.
- Lab management networks that do not overlap other networks in your tailnet or on your client.

## Quick Start

1. Add the section to `manifest.toml`:

    ```toml
    [tailscale]
    enabled = true
    auth_key_env = "SHERPA_TAILSCALE_KEY"
    ```

2. Set the auth key in the shell that runs `sherpa up`:

    ```bash
    export SHERPA_TAILSCALE_KEY=<your-auth-key>
    ```

3. Create the lab:

    ```bash
    sherpa up
    ```

4. Approve the gateway's routes (see [Route Approval](#route-approval)), then connect to the
   management IPs shown by `sherpa inspect`.

The manifest holds only the variable name, never the key. See the
[manifest reference](../../manifest.md#tailscale-object) for the settings.

### Choosing an Auth Key

- Use a **non-ephemeral** key. An ephemeral key removes the gateway when the lab stops.
- If your tailnet requires device approval, use a **pre-approved** key.
- The key is only needed when the lab is first created. `sherpa down` and `sherpa resume` reuse
  the gateway's saved identity.
- REST API callers send the key as `tailscale_auth_key` in the creation request. The web UI
  cannot enroll a lab.

## Route Approval

Joining the tailnet and approving routes are separate steps. Until the gateway's routes are
approved, other devices cannot reach the lab. Lab creation still succeeds, with a warning.

### Automatic approval

1. Create a tag in your tailnet, for example `tag:sherpa-lab`, and authorize its owners.
2. In your Tailscale policy, add `autoApprovers.routes` allowing that tag to advertise the
   management address ranges configured on your Sherpa server.
3. Generate the auth key with that tag attached.
4. Create the lab.

The policy lives in Tailscale. Sherpa never changes it and needs no Tailscale admin credential.

### Manual approval

Open the gateway device in the Tailscale admin console and approve its advertised IPv4 and
IPv6 routes.

### Check the result

Run `sherpa inspect <lab-id>`. It shows the gateway state, route approval, advertised networks,
Tailscale addresses and any warnings. Approval can take a moment, so inspect again after
changing the policy.

### Access

Route approval does not grant access by itself:

- Grant your users access to the management addresses in your Tailscale ACLs or grants.
- Your client must accept subnet routes. On Linux:

    ```bash
    sudo tailscale set --accept-routes
    ```

Connect with the node's normal SSH or HTTPS credentials. The generated `sherpa ssh` config still
uses the Sherpa server as a jump host. Per-node DNS names are not provided.

## Lab Lifecycle

| Command | Gateway |
| ------- | ------- |
| `sherpa up` | Created and joined to the tailnet. If enrollment fails, the lab is rolled back. A route approval warning does not fail the lab. |
| `sherpa down` | Stopped along with the lab. |
| `sherpa resume` | Started with its saved identity before nodes resume. |
| `sherpa destroy` or `sherpa server clean <lab_id>` | Removed, with its identity volume. If removal fails, the lab record is kept so you can retry. |

Stopping or resuming an individual node leaves the gateway alone.

## Recovery

| Problem | What to do |
| ------- | ---------- |
| Environment variable is not set | Set the variable named by `auth_key_env` in your client shell, then retry. |
| Plaintext connection, or certificate validation disabled | Enable server TLS, connect over WSS and trust the server certificate without `--insecure`. |
| Invalid or expired key, or enrollment timed out | Check the key, device approval, the server's internet access and `/dev/net/tun`. The lab is rolled back. Retry with a fresh key. A one-use key may already be spent. |
| Gateway needs reauthentication on resume | The lab is intact. An administrator can log the existing gateway in interactively inside its container. Alternatively, destroy and recreate the lab with a fresh key. Sherpa does not keep keys for automatic reauthentication. |
| Routes are pending | Approve them as described above. No restart is needed. |
| Routes approved but unreachable | Check your ACLs, that your client accepts routes, the node state, and address conflicts. |
| Address conflicts | Management ranges must not overlap other advertised networks or your client's local networks. Sherpa avoids conflicts on one server, but cannot see other servers or tailnets. Configure distinct management ranges before creating labs. |
| Destroy failed part way | Run destroy or clean again. Sherpa keeps the lab record and only deletes gateways it can verify belong to that lab. |
| Stale device in Tailscale | Remove it in the Tailscale admin console. Sherpa stores no admin credential and cannot remove it. |

## Server Settings

Administrators can change the gateway image, socket path and timeouts. See the
[server configuration](../../configuration/sherpa.md#tailscale).

## How It Works

Each gateway is a container with its own network namespace, attached to the lab's management
network, with an identity volume named `sherpa-tailnet-state-<lab_id>`.

- It uses `/dev/net/tun` with the `NET_ADMIN` and `NET_RAW` capabilities, not host networking
  or full privilege.
- The gateway's address is offset 3 in each management subnet, below the node range.
- Forwarding uses nftables and only permits that lab's management subnets, with source NAT.
- The auth key is passed over Docker exec stdin into a temporary in-memory file that is removed
  after enrollment. It is not stored in manifests, environment variables, command arguments or
  the database.
- The identity volume holds the gateway's Tailscale identity and is sensitive.

## References

- [Tailscale subnet routers](https://tailscale.com/docs/features/subnet-routers)
- [Tailscale auth keys](https://tailscale.com/docs/features/access-control/auth-keys)
