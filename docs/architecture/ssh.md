# SSH

## Config File

An SSH config file named `sherpa_ssh_config` is created per-lab which
is used by the `sherpa ssh <node-name>` command to access lab nodes.

### Users SSH Config File
To allow seamless conectivity to lab nodes, the users ssh config file
in `~/.ssh/config` will have a line added: 
`Include <home_dir>/.ssh/sherpa_lab_hosts` to the top of the file.

The `sherpa_lab_hosts` file has `Include` references to the labs SSH
config file added and removed during start up and tear down.

## Jumphost

When the Sherpa server is running on a remote host, lab nodes
can be accessed via SSH using the Sherpa server as a jumphost.

The `sherpa ssh <node-name>` command uses the generated
`sherpa_ssh_config` file to jump to the lab nodes via the 
Sherpa server. 

`sherpa ssh` and [SSH provisioners](provisioners/ssh.md) use Sherpa's own SSH client, which
reads `sherpa_ssh_config` as `ssh -F sherpa_ssh_config` would. No `ssh` or `scp` program is
needed. Like `ssh`, they ask for your key's passphrase or your password on the Sherpa server
when they need them. Provisioners ask once per run and reuse the answer for every node. A key
loaded in your SSH agent (`ssh-add`; on Windows the OpenSSH agent service, or Pageant) needs no
prompt.

The Sherpa server's host key is checked against `~/.ssh/known_hosts`. The first time you
connect, you are shown its fingerprint and asked to confirm it, as with OpenSSH; a confirmed
key is recorded there. A server whose key has changed is refused.

## Tunneling

SSH tunneling allows for the connection of remote resources from your local
machine by tunneling through SSH.

`TODO: Add diagram showing SSH tunneling`


For example, connecting to a HTTP server running on a lab-node.

```
# ssh -N -L {local-port}:{node-ipv4}:{node-port} {sherpa-server}

ssh -N -L 9443:172.31.1.21:443 lab01
```

You can now open a browser and from `https://localhost:9443` access the web server
on the lab node `172.31.1.21:443` 

!!! Note
    In a future release, SSH tunneling of service ports will be built into Sherpa.
