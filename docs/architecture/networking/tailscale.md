# Tailscale

Sherpa can create a dedicated Tailscale subnet router for each lab. It exposes the
lab's IPv4 and optional IPv6 management addresses to the lab owner's tailnet.
Lab nodes do not need a Tailscale agent.

## Prerequisites

- A Linux Sherpa server with Docker, `/dev/net/tun`, and nftables support.
- Server TLS enabled and a WSS client connection with certificate validation.
  Enrollment rejects plaintext connections and `--insecure`.
- A Tailscale auth key for the intended tailnet and a client device connected to it.
- Non-overlapping management networks and a tailnet policy that permits the intended
  users to reach them.

Sherpa configures forwarding inside the gateway. See the
[TLS configuration](../../configuration/sherpa.md#tls) for server settings.

## Manifest

Add this section to your existing `manifest.toml`, after lab-level fields such as
`nodes` and `links`:

```toml
[tailscale]
enabled = true
auth_key_env = "SHERPA_TAILSCALE_KEY"
```

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `enabled` | bool | `false` | Create a Tailscale gateway for this lab |
| `auth_key_env` | string | unset | Client environment variable containing the auth key; required when enabled |

The variable name must use letters, digits, and underscores and cannot start with
a digit. See the [manifest reference](../../manifest.md#tailscale-object).

Set the named environment variable in the shell that runs `sherpa up`, using a
Tailscale **auth key** from your own tailnet. Supply the real value through your
secret manager or shell's secure input facility. Do not put the key in the
manifest. OAuth client secrets are not supported.

The CLI resolves the key locally and sends it separately over WSS with certificate
validation enabled. REST callers must supply `tailscale_auth_key` separately in
the authenticated HTTPS creation request; the server never resolves client
variable names. Web UI enrollment is not supported in this version.

An omitted section, or `enabled = false`, leaves the lab disconnected from Tailscale.
The auth key is required only for initial creation. Use a non-ephemeral key so the
gateway identity survives normal lab shutdown. If your tailnet requires device
approval, use a pre-approved key or complete device approval during enrollment.

## Route Approval

Joining the tailnet and approving subnet routes are separate operations.

For unattended creation:

1. Create a tag such as `tag:sherpa-lab` in your tailnet and authorize its owners.
2. Configure `autoApprovers.routes` in your **Tailscale policy**, allowing that tag
   to advertise the management address pools configured on your Sherpa server.
3. Generate the auth key with that tag attached.
4. Create the lab. Sherpa advertises only its allocated management subnets.

The policy lives in Tailscale, not in the Sherpa manifest. Sherpa does not change
it or require a Tailscale administrative API credential. An authorized larger
prefix also permits advertisements of subnets within that prefix.

Alternatively, open the gateway device in the Tailscale admin console and approve
its advertised IPv4 and IPv6 routes manually.

If route approval is pending, **lab creation succeeds with a warning** and a link
to Sherpa's Tailscale setup documentation. If Sherpa cannot verify approval, it
reports that uncertainty rather than claiming the routes are usable.
`sherpa inspect` refreshes this status. Approval
can settle shortly after enrollment; inspect again after updating the policy.
No warning is needed once every advertised route is approved.

Route approval does not grant access by itself. Configure Tailscale grants/ACLs
for the intended users and management destinations. Client machines must accept
subnet routes. On a Linux client accessing the lab, enable route acceptance:

```bash
sudo tailscale set --accept-routes
```

See [Tailscale client route acceptance](https://tailscale.com/docs/features/subnet-routers#use-your-subnet-routes-from-other-devices).

References: [Tailscale subnet routers](https://tailscale.com/docs/features/subnet-routers),
[Tailscale auth keys](https://tailscale.com/docs/features/access-control/auth-keys).

## Lifecycle and Access

- `sherpa up` creates the gateway and joins the tailnet. Enrollment failure fails
  startup and invokes the existing lab rollback. Route approval warnings do not.
- Full `sherpa down` stops the gateway; full `sherpa resume` starts it using its
  persistent identity before resuming nodes. Individual node operations leave the
  gateway alone.
- `sherpa inspect` shows gateway state, route approval, advertised management
  networks, Tailscale addresses, and warnings.
- `sherpa destroy` and administrative `sherpa server clean <lab_id>` remove the
  gateway and its identity volume before removing lab networks. If either removal
  fails, Sherpa retains the lab's database ownership and saved configuration so
  cleanup can be retried.

Cleanup identifies gateways using Docker labels and verifies exact lab ownership
before deleting the gateway or volume. Ordinary lab containers whose names begin
with `sherpa-tailnet-` are still removed.

Connect directly to the management IPs reported by Sherpa, using the node's normal
SSH/HTTPS credentials. Existing generated SSH configurations still use their
configured Sherpa jump host. Automatic DNS names for individual lab nodes are not
part of this feature.

Each gateway uses its own Docker network namespace, the lab's management network,
and a protected identity volume. Its management address is offset 3 in each subnet,
below the node allocation range. It uses `/dev/net/tun` and `NET_ADMIN`/`NET_RAW`,
without host networking or full privileged mode. The host must support nftables;
the gateway uses Tailscale's nftables backend and installs forwarding restrictions
through the image's `iptables-nft`/`ip6tables-nft` tools. Forwarding restrictions permit
only that lab's management subnets; the gateway uses source NAT. The official
container image defaults to `tailscale/tailscale:v1.102.3` and is pulled if absent.
Server administrators can override the image, socket path, and timeouts in the
server configuration's [`[tailscale]` section](../../configuration/sherpa.md#tailscale).
Enrollment credentials travel over Docker exec stdin into a temporary in-memory
file, which is removed after enrollment. They are not stored in Docker environment
variables, exec arguments, manifests, or database records. Tailscale's persistent
node identity is itself sensitive and remains in the protected Docker volume
named `sherpa-tailnet-state-<lab_id>`.

## Recovery

- **Missing environment variable:** set the variable named by `auth_key_env` on
  the client, then retry creation.
- **Plaintext connection or disabled certificate validation:** enable server TLS,
  connect using WSS, and configure certificate trust without `--insecure`.
- **Invalid/expired auth key or enrollment timeout:** check the key, device approval,
  outbound connectivity, and the server's Docker/TUN availability. Startup rolls back.
  After cleanup succeeds, retry with a fresh key. A one-use key may already have
  been consumed by an interrupted enrollment.
- **Gateway requires reauthentication on resume:** existing lab resources remain
  intact. A server administrator can authenticate the existing gateway through an
  interactive Tailscale login inside the container. The owner may instead destroy
  and recreate the lab with a fresh key when its data is no longer needed. Sherpa
  does not retain enrollment keys for automatic reauthentication.
- **Pending routes:** follow the approval instructions above; a restart is unnecessary.
- **Routes approved but unreachable:** check tailnet access policy, client route
  acceptance, node state, and address conflicts. Approval alone is not an end-to-end
  connectivity test.
- **Address conflicts:** management pools must not overlap other networks advertised
  into the same tailnet or the connecting client's local networks. Sherpa allocates
  unique subnets on one server, but cannot discover conflicts across tailnets or
  separate Sherpa servers. Configure distinct management pools before creating labs.
  4via6 and automatic renumbering are not supported.
- **Partial cleanup:** retry the normal destroy/administrator clean operation. Sherpa
  retains database ownership and saved configuration when gateway or identity volume
  removal fails, so the same owner can retry destroy. Other infrastructure may
  already have been removed. Sherpa verifies exact gateway ownership labels and
  refuses to delete unrelated resources.
- **Old Tailscale device records:** deleting local state does not guarantee that the
  device record disappears from Tailscale. Remove stale gateway devices through the
  Tailscale admin console; no administrative Tailscale key is stored by Sherpa.
