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

Sherpa records the version, so a lab can use it. An image pulled only with the `docker` CLI is
not known to Sherpa, so a lab cannot use it.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| Tested Version       | 26.4      |
| CPU                  | 2         |
| RAM                  | 2GB       |
| ZTP Method           | None      |
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
| Admin console | `https://<keycloak_mgmt_ip>:8443/admin/` |
| Username | `sherpa` |
| Password | `Everest1953!` |
| OpenID Connect issuer | `https://<keycloak_mgmt_ip>:8443/realms/<realm>` |
| Health | `https://<keycloak_mgmt_ip>:9000/health/ready` |

The `sherpa` user is the `master` realm's bootstrap admin. Keycloak marks it as temporary in
the admin console; create your own admin user to replace it if you keep the lab.

Your browser trusts the pages once you import the lab's `lab-ca.crt`; command line clients
can use it directly:

```
curl --cacert lab-ca.crt https://<keycloak_mgmt_ip>:8443/realms/master/.well-known/openid-configuration
```

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
| `KC_BOOTSTRAP_ADMIN_USERNAME` | `sherpa` |
| `KC_BOOTSTRAP_ADMIN_PASSWORD` | the Sherpa password |

## Notes

- Approximate time for the system to be ready: `30 seconds` after the container starts.
  `sherpa up` reports a container as ready when it has started.
- The container runs as root, so it can read the lab certificate key mounted from the server.
- Keycloak's data is kept in the container. `sherpa down` and `sherpa resume` keep it;
  `sherpa redeploy` starts an empty Keycloak.
