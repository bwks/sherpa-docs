# SSH Tunneling

SSH tunneling allows for the connection of remote resources from your local machine.

For example, this is useful for connecting to a HTTP server.

```
ssh -N -L 9443:172.31.0.11:443 ubntv
```
