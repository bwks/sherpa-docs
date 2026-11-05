# Lab Certificates

Every lab has its own certificate authority (CA). Sherpa creates it when the lab is built, and
it issues each node a TLS certificate for the node's names and management addresses. Services
such as [Vault](../nodes/hashicorp/hashicorp-vault.md) and
[Keycloak](../nodes/keycloak/keycloak-server.md) serve HTTPS with them, and your workstation
and the lab's VMs can trust them through the lab CA.

## Node Certificates

| Field | Value |
| ----- | ----- |
| Names | `<node>`, `<node>.<lab-id>` and `<node>.<lab-id>.sherpa.lab.local` |
| Addresses | the node's IPv4 management address, and its IPv6 one when the lab has IPv6 |
| Usage | TLS server and client |
| Validity | 365 days |

Each node finds its files in `/etc/sherpa/certs/` (`C:\sherpa\certs\` on Windows):

| File | Content |
| ---- | ------- |
| `ca.crt` | The lab CA certificate |
| `node.crt` | The node's certificate |
| `node.key` | The node's private key, readable only by root |

Containers, Linux, BSD and Windows VMs get them. `sherpa redeploy` issues the node a new
certificate from the same lab CA.

## Trusting the Lab CA

**On lab VMs.** Linux VMs built with cloud-init have the lab CA in their system trust store, so
`curl`, package managers and other clients there trust lab services with no extra options.

**On your workstation.** `sherpa up` and `sherpa download` write the CA to `lab-ca.crt` in your
working directory. Pass it to command line clients:

```
curl --cacert lab-ca.crt https://172.31.1.21:8200/v1/sys/health
export VAULT_CACERT=$PWD/lab-ca.crt
```

To trust lab web pages in a browser, import `lab-ca.crt` as a certificate authority in the
browser's or operating system's certificate settings. Each lab has its own CA, so import it
again for a new lab, and remove it when the lab is destroyed.

## On the Server

The CA and the node certificates are in the lab's directory, `/opt/sherpa/labs/<lab-id>/certs/`.
The CA key is readable only by Sherpa. They are removed with the lab.
