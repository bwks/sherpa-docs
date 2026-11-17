# Node Credentials

Node credentials are configured via ZTP during the first boot. Where a node's login comes from
depends on the lab and the node, not on any server setting.

## Your Login

Nodes that Sherpa provisions have one login: yours. It is your Sherpa username, with the SSH
public keys registered to your account and your [device password](device-password.md) as its
password. Nothing is shared between users or labs, and no password is published.

| Username              | Password        | SSH Key                           |
| --------------------- | --------------- | --------------------------------- |
| your Sherpa username  | device password | your registered public keys       |

Devices that have fixed vendor accounts, such as `admin` on NX-OS and `root` on Junos, take your
device password for those too. Cisco FTDv has only `admin`, with your device password and no key.
Aruba AOS-CX takes no password: you log in by key only, and its `admin` is locked.
See [Your Login on Nodes](personal-accounts.md) for each model.

A lab's credentials belong to its owner. `sherpa download` hands the lab's SSH config, host keys,
Talos cluster credentials, Vault, Keycloak and SurrealDB credentials and lab CA to the owner only,
not to admins. An admin who resets a user's Sherpa password can still sign in as them; that is logged.
See [Overview](overview.md).

Before 0.7.0 every node also had a `sherpa` account with a published password, and Keycloak and
SurrealDB nodes had it as their administrator. New nodes do not.
See [Updating Sherpa](../install-update/update/sherpa.md) for labs built before then.

## Application Administrators

Some application containers have an administrator of their own. Sherpa gives each node its own,
with a random password generated when the node is created and kept when it is redeployed:

| Model | Administrator | Where to find it after `sherpa up` or `sherpa download` |
| ----- | ------------- | ------------------------------------------------------- |
| `keycloak_server` | `admin`, in the `master` realm | `.sherpa/keycloak/keycloak-<node>.toml` |
| `surreal_db` | `root` | `.sherpa/surrealdb/surrealdb-<node>.toml` |

The files are readable only by you. The server keeps its copy in the lab's directory, readable
only by `sherpad`, not in its database. A password is also in its container's environment, where
anyone in the Sherpa host's `docker` group can read it; that group is root on the host.

!!! Info

    `sherpa up` and `sherpa redeploy` stop, before they create anything, if you have not set a
    device password. See [Device Password](device-password.md).

## Custom ZTP Configuration

A node with a [`ztp.config`](../manifest.md#ztp-object) boots with that file instead of the
configuration Sherpa generates, so it has the accounts and passwords the file sets, and no login
for you. A node with `ztp.method = "disabled"` boots as its image ships, with the vendor's own
login.

## Server Configuration

No setting in `sherpa.toml` changes node credentials. Releases up to 0.6.5 wrote a
`[ztp_server]` table there with the default password; nothing read it, and `sherpad` now
ignores it with a warning. You can delete it; see
[Updating Sherpa](../install-update/update/sherpa.md).
