# SSH

## Config File

An SSH config file named `sherpa_ssh_config` is created per-lab which
is used by the `sherpa ssh <node-name>` command to access lab nodes.

## Jumphost

When the Sherpa server is running on a remote host, lab nodes
can be accessed via SSH using the Sherpa server as a jumphost.

The `sherpa ssh <node-name>` command uses the generated
`sherpa_ssh_config` file to jump to the lab nodes via the 
Sherpa server. 

For ease of use, it is recommeded to copy your ssh keys to the Sherpa server
to allow passwordless connectivity to remote nodes.

## Tunneling

SSH tunneling allows for the connection of remote resources from your local
machine by tunneling through SSH.

For example, connecting to a HTTP server running on a lab-node.

```
# ssh -N -L {local-port}:{node-ipv4}:{node-port} {sherpa-server}

ssh -N -L 9443:172.31.0.11:443 lab01
```

You can now open a browser and from `https://localhost:9443` access the web server
on the lab node `172.31.0.11:443` 

!!! Note
    In a future release, SSH tunneling of service ports will be built into Sherpa.
