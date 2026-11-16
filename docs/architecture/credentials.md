# Node Credentials

Node credentials are configured via ZTP during the first boot. Where a node's login comes from
depends on the lab and the node, not on any server setting.

## Default Credentials

Nodes that Sherpa provisions get the `sherpa` account. Its credentials are built into Sherpa and
are the same on every server:

| Username | Password       | SSH Key                                  |
| -------- | -------------- | ---------------------------------------- |
| `sherpa` | `Everest1953!` | `.sherpa/ssh/key`, in the lab's folder   |

!!! Info

    `sherpa up` makes a new SSH key pair for each lab, and `sherpa up` and
    `sherpa download` save it to your lab folder. See
    [Lab SSH Key](ssh.md#lab-ssh-key).

The password is published here, so treat it as known to anyone, and log in with the lab key
where the node takes one.

## Your Own Account

With [`provision_current_user = true`](../manifest.md#provision_current_user-bool) in the
manifest, nodes also get an account named after the lab owner's Sherpa username, with the SSH
public keys registered to that account. Where a device needs a password, the account gets a
random one that is never shown; you log in with your key. See
[Personal Accounts](personal-accounts.md) for the nodes it applies to.

## Custom ZTP Configuration

A node with a [`ztp.config`](../manifest.md#ztp-object) boots with that file instead of the
configuration Sherpa generates, so it has the accounts and passwords the file sets. A node with
`ztp.method = "disabled"` boots as its image ships, with the vendor's own login.

## Image ZTP Credentials

A node image can record a ZTP username and password, kept encrypted in the database; the web UI
and `sherpa server image show` say only whether the password is set. Sherpa's generated node
configurations do not use them: they set up the `sherpa` account above.

## Server Configuration

No setting in `sherpa.toml` changes node credentials. Releases up to 0.6.5 wrote a
`[ztp_server]` table there with the default password; nothing read it, and `sherpad` now
ignores it with a warning. You can delete it; see
[Updating Sherpa](../install-update/update/sherpa.md).
