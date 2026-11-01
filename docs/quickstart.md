# Quickstart

## Install

The quickest way to get started with Sherpa is to use the convenience installer [script](install-update/install/automated.md).

```
curl https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_install.sh | sudo bash
```

This will install all the dependencies as well as the Sherpa, 
server and client binaries.

## Sherpa Server
Initialize the Sherpa server.
```
sherpad init
```

`sherpad init` creates two accounts:

- **`admin`**, the built-in server account. It manages the server, users and images, and can
  stop, destroy and clean up any lab, but it cannot start labs. Its password is taken from
  `SHERPA_ADMIN_PASSWORD` if that is set, otherwise you are asked for one.
- **Your user account**, which you start labs from. You choose the username and password,
  whether it is an administrator, and an SSH public key, as a file path or the key itself.
  Labs need a key: if you skip it, add one later as described in
  [SSH Keys](architecture/ssh-keys.md).

Running `sherpad init` again keeps existing accounts: it only creates `admin` if it is missing,
and only asks for a user account if there is none.

### Unattended initialization

Every answer can come from an environment variable instead of a prompt, so `sherpad init` can
run from a script. A variable that is not set is prompted for.

| Variable | Answer |
|---|---|
| `SHERPA_ADMIN_PASSWORD` | Password for `admin`. Also read from `/opt/sherpa/env/sherpa.env` |
| `SHERPA_USER_NAME` | Your username |
| `SHERPA_USER_PASSWORD` | Your password |
| `SHERPA_USER_IS_ADMIN` | `yes` or `no`; empty means `yes` |
| `SHERPA_USER_SSH_KEY` | SSH public key, as a file path or the key itself; empty adds none |

The `SHERPA_USER_*` variables are only read from the environment, never from the env file, so
your password is not kept on the server. Passwords must meet the server's rules: at least 8
characters, with upper and lower case letters and one of `!@#$%^&*_+-=`.

```
sudo -u sherpa -H --preserve-env=SHERPA_ADMIN_PASSWORD,SHERPA_USER_NAME,SHERPA_USER_PASSWORD,SHERPA_USER_IS_ADMIN,SHERPA_USER_SSH_KEY \
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

## Build
Run the following command to start a lab.
```
sherpa up
```

## Access
Devices are available via SSH.
```
sherpa ssh dev01
```

## Destroy
Tear down the lab when you are finished.
```
sherpa destroy
```
