# Keycloak

[Keycloak](https://www.keycloak.org) is an identity provider, and a container based image.
Sherpa runs it in production mode, serving HTTPS only with the node's
[lab certificate](../../architecture/certificates.md).

## Base Image

Base images are on [Quay](https://quay.io/repository/keycloak/keycloak).

### Import Image

Pull the image through Sherpa:

```
sherpa server image pull --model keycloak_server --version 26.4
```

Sherpa records the version, so a lab can use it. An image already pulled with the `docker` CLI
is not known to Sherpa until it is scanned. The scan records each local tag of `quay.io/keycloak/keycloak` as a
version:

```
docker pull quay.io/keycloak/keycloak:26.4
sherpa server image scan --kind container
```

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| Tested Version       | 26.4      |
| CPU                  | Not limited |
| RAM                  | Not limited |
| ZTP                  | `disabled`|
| Management Interface | eth0      |
| Interface Driver     | macvlan   |

## Example Manifest

```toml
name = "keycloak"

[[nodes]]
name = "kc01"
model = "keycloak_server"
```

## Node Access

Keycloak serves HTTPS on port `8443`, on the node's management address. Plain HTTP is
disabled.

| | |
| - | - |
| Admin console | `https://<keycloak_mgmt_ip>:8443/admin/master/console/` |
| Username | `admin` |
| Password | generated for the node, in `.sherpa/keycloak/keycloak-<node>.toml` |
| OpenID Connect issuer | `https://<keycloak_mgmt_ip>:8443/realms/<realm>` |
| Health | `https://<keycloak_mgmt_ip>:9000/health/ready` |

`admin` is the `master` realm's bootstrap admin. Each Keycloak node gets its own, with a random
password Sherpa generates when the node is created; no two nodes share one, and no password is
published. Keycloak marks the bootstrap admin as temporary in the admin console; create your own
admin user to replace it if you keep the lab.

`sherpa up` and `sherpa download` write the admin and its password to
`.sherpa/keycloak/keycloak-<node>.toml` in the lab folder, readable only by you (see
[below](#sherpa-realm)). Only you, the lab's owner, can download them; an admin of the Sherpa
server cannot. If you are in another folder, or lost the file, run `sherpa download` from the lab
folder.

Your browser trusts the pages once you import the lab's `.sherpa/ca/lab-ca.crt`; command line clients
can use it directly:

```
curl --cacert .sherpa/ca/lab-ca.crt https://<keycloak_mgmt_ip>:8443/realms/master/.well-known/openid-configuration
```

## Sherpa Realm

After the node starts, Sherpa makes a realm named `sherpa`, which
[Kubernetes clusters](../linux/talos-linux.md#keycloak-login) accept logins from:

| | |
| - | - |
| Users | you, the lab owner, with a generated password |
| Groups | `cluster-admins`, which you are in, and `cluster-viewers` |
| Client | `kubernetes`, a public client for `kubectl oidc-login` |
| Issuer | `https://<keycloak_mgmt_ip>:8443/realms/sherpa` |
| Account console | `https://<keycloak_mgmt_ip>:8443/realms/sherpa/account` |

`sherpa up` and `sherpa download` write the node's admin and the realm's users and passwords to
`.sherpa/keycloak/keycloak-<node>.toml` in your working directory, readable only by you:

```toml
address = "https://172.31.1.23:8443"
realm = "sherpa"
issuer = "https://172.31.1.23:8443/realms/sherpa"
account_console = "https://172.31.1.23:8443/realms/sherpa/account"
admin_console = "https://172.31.1.23:8443/admin/master/console/"

[admin]
username = "admin"
password = "…"

[[users]]
username = "alice"
password = "…"
```

Add your own users and groups to the realm in the admin console. A Kubernetes cluster sees a
user's groups as `oidc:<group>`.

## Settings

Sherpa sets these environment variables. Values you set in the node's
[`environment_variables`](../../manifest.md) come after them, so they override Sherpa's.

| Variable | Value |
| -------- | ----- |
| `KC_DB` | `dev-file`, the built-in database |
| `KC_HTTP_ENABLED` | `false` |
| `KC_HOSTNAME` | `https://<keycloak_mgmt_ip>:8443` |
| `KC_HTTPS_CERTIFICATE_FILE` | `/etc/sherpa/certs/node.crt` |
| `KC_HTTPS_CERTIFICATE_KEY_FILE` | `/etc/sherpa/certs/node.key` |
| `KC_HEALTH_ENABLED` | `true` |
| `KC_BOOTSTRAP_ADMIN_USERNAME` | `admin` |
| `KC_BOOTSTRAP_ADMIN_PASSWORD` | the node's generated admin password |

Sherpa logs in as the bootstrap admin to make the `sherpa` realm, so do not override
`KC_BOOTSTRAP_ADMIN_USERNAME` or `KC_BOOTSTRAP_ADMIN_PASSWORD`. The password is in the
container's environment, so anyone in the Sherpa host's `docker` group can read it with
`docker inspect`. Membership of `docker` is root on the host, so that gives nothing away that
root does not already have.

## Notes

- Approximate time for the system to be ready: `30 seconds` after the container starts.
  `sherpa up` reports a container as ready when it has started.
- The container runs as root, so it can read the lab certificate key mounted from the server.
- Keycloak's data is kept in the container. `sherpa down` and `sherpa resume` keep it;
  `sherpa redeploy` starts an empty Keycloak, with the same admin and password. Sherpa then
  makes the `sherpa` realm again, with the same users and passwords; users and groups you added
  are gone. Your `.sherpa/keycloak/keycloak-<node>.toml` stays right.
- A Keycloak node created before Sherpa 0.7.0 keeps its old `sherpa` admin, with the password
  every node had then, until you run `sherpa redeploy -n <node>`. The redeploy gives it its own
  `admin` and removes the `sherpa` user from the realm; run `sherpa download --force` afterwards
  for the new file.
