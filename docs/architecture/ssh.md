# SSH

## SSH Config File

An SSH config file named `sherpa_ssh_config` is created per-lab which
is used by the `sherpa ssh <device-name>` command to access lab devices.

## SSH Jumphost

When the Sherpa server is running on a remote host, lab devices
can be accessed via SSH using the server as a jump host with
the `sherpa ssh <device-name>` command and the generated
`sherpa_ssh_config` file.

## SSH Tunneling

SSH tunneling allows for the connection of remote resources from your local machine.

For example, this is useful for connecting to a HTTP server.

```
ssh -N -L 9443:172.31.0.11:443 ubntv
```
