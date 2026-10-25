# Tailscale

Sherpa can connect a lab to your [Tailscale](https://tailscale.com) tailnet. It creates one
gateway per lab that makes the lab's management addresses reachable from your other tailnet
devices. Lab nodes do not need Tailscale installed.

![A WireGuard tunnel from your device reaches the lab's Tailscale gateway container through the host uplink and management bridge, and the gateway forwards the traffic back onto the bridge to the nodes](tailscale.svg)

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

2. Set the auth key in the shell that runs `sherpa up` and `sherpa resume`:

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

Use a **reusable, ephemeral, pre-approved** key with the tag your route auto-approval uses
(see [Automatic approval](#automatic-approval)):

- **Ephemeral** means the gateway device leaves your tailnet as soon as Sherpa logs it out on
  `sherpa down` and `sherpa destroy`, so labs do not leave devices behind for you to delete by
  hand.
- **Pre-approved** is needed if your tailnet requires device approval.
- **Reusable** lets one key enroll many labs, and enroll a lab again each time it resumes.

The key is needed when the lab is created and each time the whole lab is resumed, because
`sherpa down` logs the gateway out. Sherpa never stores the key; keep it in the variable named
by `auth_key_env`.

!!! warning "Non-ephemeral keys"

    Both kinds of key work, but logging out does not remove a device enrolled with a
    non-ephemeral key. It stays in your tailnet, offline, after each `sherpa down` and
    `sherpa destroy` until you remove it in the Tailscale admin console.

- REST API callers send the key as `tailscale_auth_key` in the creation and resume requests.
  The web UI cannot enroll a lab, so it cannot resume a whole lab that uses Tailscale.

## Route Approval

Joining the tailnet and approving routes are separate steps. Until the gateway's routes are
approved, other devices cannot reach the lab. Lab creation still succeeds, with a warning.

### Automatic approval

1. Create a tag in your tailnet, for example `tag:sherpa-lab`, and authorize its owners.
2. In your Tailscale policy, add `autoApprovers.routes` allowing that tag to advertise the
   management address ranges configured on your Sherpa server.
3. Generate the auth key with that tag attached.
4. Create the lab.

Each resume enrolls a new gateway device, so with automatic approval its routes are approved
again without you doing anything.

The policy lives in Tailscale. Sherpa never changes it and needs no Tailscale admin credential.

### Manual approval

Open the gateway device in the Tailscale admin console and approve its advertised IPv4 and
IPv6 routes. Each `sherpa resume` enrolls a new device, so approve its routes again after every
resume.

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
| `sherpa down` | Logged out of the tailnet, then stopped along with the lab. An ephemeral device is removed at once. |
| `sherpa resume` | Started and enrolled again with the key from `auth_key_env` before nodes resume, as a new device with new Tailscale addresses. Its routes need approval again, which is automatic with [automatic approval](#automatic-approval). |
| `sherpa destroy` or `sherpa server clean <lab_id>` | Logged out if it is running, then removed with its identity volume. If removal fails, the lab record is kept so you can retry. |

If logging out fails, for example because the server has no internet access, Sherpa still
stops or removes the gateway. Tailscale then removes an ephemeral device by itself, typically
30 to 60 minutes after it goes offline.

Stopping or resuming an individual node leaves the gateway alone.

## Recovery

| Problem | What to do |
| ------- | ---------- |
| Environment variable is not set | Set the variable named by `auth_key_env` in your client shell, then retry. |
| Resume asks for an auth key | Run `sherpa resume` in the lab folder, so it can read `auth_key_env` from `manifest.toml`, with that variable set. REST callers send `tailscale_auth_key`. |
| Plaintext connection, or certificate validation disabled | Enable server TLS, connect over WSS and trust the server certificate without `--insecure`. |
| Invalid or expired key, or enrollment timed out | Check the key, device approval, the server's internet access and `/dev/net/tun`. The lab is rolled back. Retry with a fresh key. A one-use key may already be spent. |
| Gateway does not reconnect on resume | Check the key as for enrollment: it may have expired, been revoked, or been a one-use key that is already spent. Generate a new key and run `sherpa resume` again. |
| Routes are pending | Approve them as described above. No restart is needed. |
| Routes approved but unreachable | Check your ACLs, that your client accepts routes, the node state, and address conflicts. |
| Address conflicts | Management ranges must not overlap other advertised networks or your client's local networks. Sherpa avoids conflicts on one server, but cannot see other servers or tailnets. Configure distinct management ranges before creating labs. |
| Destroy failed part way | Resolve the Docker error or volume attachment, then run `sherpa destroy` again as the lab owner, or `sherpa server clean <lab_id>` as an administrator. Sherpa keeps the lab record and only deletes gateways it can verify belong to that lab. Other lab resources may already have been removed. |
| Stale device in Tailscale | An ephemeral device that Sherpa could not log out is removed by Tailscale once it has been offline for a while. A device enrolled with a non-ephemeral key stays until you remove it in the Tailscale admin console. Sherpa stores no admin credential and cannot remove it. |

## Server Settings

Administrators can change the gateway image, socket path and timeouts. See the
[server configuration](../../configuration/sherpa.md#tailscale).

## How It Works

Each gateway is a container with its own network namespace, attached to the lab's management
network, with an identity volume named `sherpa-tailnet-state-<lab_id>`.

- It uses `/dev/net/tun` with the `NET_ADMIN` and `NET_RAW` capabilities, not host networking
  or full privilege.
- Its only interface is on the management network, beside the lab nodes. Your device reaches it
  over a WireGuard tunnel that enters through the host uplink and the management bridge, the
  same way the gateway reaches the internet. The gateway decrypts the traffic and forwards it
  back onto the management bridge to the node.
- The Tailscale coordination server exchanges keys, advertised routes and policy with the
  gateway, but carries no lab traffic. When a direct tunnel cannot be set up, Tailscale relays
  it through a DERP server.
- The gateway's address is offset 3 in each management subnet, below the node range.
- Forwarding uses nftables and only permits that lab's management subnets. Forwarded traffic is
  source NATed to the gateway's address, so nodes need no route back to the tailnet.
- The auth key is passed over Docker exec stdin into a temporary in-memory file that is removed
  after enrollment. It is not stored in manifests, environment variables, command arguments or
  the database.
- The identity volume holds the gateway's Tailscale identity and is sensitive.

## References

- [Tailscale subnet routers](https://tailscale.com/docs/features/subnet-routers)
- [Tailscale auth keys](https://tailscale.com/docs/features/access-control/auth-keys)
