# Quickstart

## Install

The quickest way to get started with Sherpa is to use the convenience installer [script](install-update/install/automated.md).

```
curl -fsSL https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_install.sh | sudo bash
```

This will install all the dependencies as well as the Sherpa, 
server and client binaries.

## Sherpa Server
Initialize the Sherpa server as the `sherpa` user, so the files it writes are `sherpa`'s;
`sherpad init` refuses any other account, root included. The
install script prints this command with the listen address and ports you gave it:
```
sudo -u sherpa -H sherpad init --server-ipv4 <address> --ws-port 3030 --http-port 3031
```
`sherpad init` writes `/opt/sherpa/config/sherpa.toml` readable by `sherpa` only (mode `600`);
see [file permissions](install-update/install/automated.md#file-permissions).
Leave a flag out to use its default: `0.0.0.0`, `3030` and `3031`. Add `--server-ipv6 <address>`
to also listen on IPv6. Labs' management subnets are taken from `172.31.0.0/16` and `fd00:b00b::/48`;
if either range is in use on your network, add `--management-prefix-ipv4 <prefix>` or
`--management-prefix-ipv6 <prefix>`. These values are written only
with a new `sherpa.toml`. See [`sherpad init`](command-reference.md#sherpad-init).

`sherpad init` creates two accounts:

- **`sherpa-admin`**, the built-in server account. It manages the server, users and images, and can
  stop, destroy and clean up any lab, but it cannot start labs. Its password is taken from
  `SHERPA_ADMIN_PASSWORD` if that is set, otherwise you are asked for one.
- **Your user account**, which you start labs from. You choose the username and password,
  whether it is an administrator, and an SSH public key, as a file path or the key itself.
  `sherpa` cannot read your home folder, so paste the key itself, or give a file `sherpa` can
  read. Labs need a key: if you skip it, add one later as described in
  [SSH Keys](architecture/ssh-keys.md).

Labs also need a device password, the password of your login on lab nodes. Set it after you
log in and before the first `sherpa up`; see [Device Password](#device-password).

Running `sherpad init` again keeps existing accounts: it only creates `sherpa-admin` if it is missing,
and only asks for a user account if there is none.

### Unattended initialization

Every answer can come from an environment variable instead of a prompt, so `sherpad init` can
run from a script. A variable that is not set is prompted for.

| Variable | Answer |
|---|---|
| `SHERPA_SERVER_IPV4` | Listen IPv4 address, as `--server-ipv4` |
| `SHERPA_SERVER_IPV6` | Listen IPv6 address, as `--server-ipv6` |
| `SHERPA_SERVER_WS_PORT` | Listen port, as `--ws-port` |
| `SHERPA_SERVER_HTTP_PORT` | Certificate endpoint port, as `--http-port` |
| `SHERPA_MANAGEMENT_PREFIX_IPV4` | Lab management IPv4 prefix, as `--management-prefix-ipv4` |
| `SHERPA_MANAGEMENT_PREFIX_IPV6` | Lab management IPv6 prefix, as `--management-prefix-ipv6` |
| `SHERPA_ADMIN_PASSWORD` | Password for `sherpa-admin` |
| `SHERPA_USER_NAME` | Your username |
| `SHERPA_USER_PASSWORD` | Your password |
| `SHERPA_USER_IS_ADMIN` | `yes` or `no`; empty means `yes` |
| `SHERPA_USER_SSH_KEY` | SSH public key, as a file path or the key itself; empty adds none |

These are read from the environment only, never from `/opt/sherpa/env/sherpa.env`, so your
password is not kept on the server. The install script reads `SHERPA_SERVER_IPV4`,
`SHERPA_SERVER_WS_PORT` and `SHERPA_SERVER_HTTP_PORT` too, so exporting them once covers both the
install and `sherpad init`. Passwords must meet the server's rules: at least 8 characters, with
upper and lower case letters and one of `!@#$%^&*_+-=`.

```
sudo -u sherpa -H --preserve-env=SHERPA_SERVER_IPV4,SHERPA_SERVER_IPV6,SHERPA_SERVER_WS_PORT,SHERPA_SERVER_HTTP_PORT,SHERPA_MANAGEMENT_PREFIX_IPV4,SHERPA_MANAGEMENT_PREFIX_IPV6,SHERPA_ADMIN_PASSWORD,SHERPA_USER_NAME,SHERPA_USER_PASSWORD,SHERPA_USER_IS_ADMIN,SHERPA_USER_SSH_KEY \
  sherpad init
```

`sherpa login` reads `SHERPA_USER_NAME` and `SHERPA_USER_PASSWORD` too.

## Sherpa Client
Initialize the Sherpa client.
```
sherpa init
```

## Manifest

A manifest describes the lab topology and node configuration parameters.

```toml
# manifest.toml
name = "labrador-infiniato"

[[nodes]]
name = "dev01"
model = "sonic_linux"

[[nodes]]
name = "dev02"
model = "sonic_linux"

[[links]]
src = "dev01::eth2"
dst = "dev02::eth2"
```

## Device Password
Set your device password before the first `sherpa up`. It is the password of your login on
every lab node, and `sherpa up` refuses to start a lab without one. The command asks for your
Sherpa login password, then the new device password twice. You can also set it on the **Profile**
page of the web UI. See [Device Password](architecture/device-password.md) for the rules.
```
sherpa server user device-password
```

## Build
Run the following command to start a lab.
```
sherpa up
```

## Access
Devices are available via SSH, as your Sherpa username, with your keys or your device password.
```
sherpa ssh dev01
```

## Destroy
Tear down the lab when you are finished.
```
sherpa destroy
```
