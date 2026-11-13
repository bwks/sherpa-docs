# SSH

## Config File

An SSH config file, `.sherpa/ssh/config` in the lab folder, is created per-lab which
is used by the `sherpa ssh <node-name>` command to access lab nodes.

### Users SSH Config File
To allow seamless conectivity to lab nodes, the users ssh config file
in `~/.ssh/config` will have a line added: 
`Include <home_dir>/.ssh/sherpa_lab_hosts` to the top of the file.

The `sherpa_lab_hosts` file has `Include` references to the labs SSH
config file (`<lab folder>/.sherpa/ssh/config`) added and removed during start up and tear down.
The config's `IdentityFile` and `UserKnownHostsFile` are absolute paths to `.sherpa/ssh/key`
and `.sherpa/ssh/known_hosts`, so `ssh -F .sherpa/ssh/config <node>.<lab-id>` works from the
lab folder. A lab from a client before 0.5.15 has these files loose in the lab folder; Sherpa moves
them into `.sherpa/` and repoints the include the next time a command uses the lab folder.

A lab folder whose path has spaces is included in double quotes, as `ssh` needs. If
`~/.ssh/config` is a symbolic link, as dotfile managers make it, the file it points to is
updated and the link is kept. Each file is replaced whole, keeping its permissions, so an
interrupted update never leaves it cut short.

## Lab SSH Key

Nodes that cannot take your own SSH keys are reached through the `sherpa` account with an SSH
key pair. `sherpa up` makes a new key pair for each lab on the Sherpa server, in the lab's
folder, readable only by the Sherpa server. Every lab has a different key, so the key of one
lab gives no access to the nodes of another.

`sherpa up` and `sherpa download` save the private key as `.sherpa/ssh/key` in your lab folder
when the lab has such nodes, and `.sherpa/ssh/config` uses it for them:

```
Host 172.31.1.22 router1.abcd1234 router1.abcd1234.sherpa.lab.local
    User sherpa
    IdentityFile /home/me/labs/dev/.sherpa/ssh/key
    IdentitiesOnly yes
```

- **Who gets it:** only the lab's owner and admins can download a lab's key, from the CLI or the
  web UI's lab download.
- **Redeploy and resume:** `sherpa redeploy` gives the node the lab's key again, and
  `sherpa resume` keeps it.
- **Destroy and clean:** `sherpa destroy` and `sherpa server clean` delete the key with the lab's
  folder on the server.
- **Labs created before Sherpa 0.5.15** used the server's shared key, which 0.6.0 removes.
  Destroy them before updating to 0.6.0; see
  [Updating to 0.6.0](../install-update/update/sherpa.md#updating-to-060).

## Jumphost

When the Sherpa server is running on a remote host, lab nodes
can be accessed via SSH using the Sherpa server as a jumphost.

The `sherpa ssh <node-name>` command uses the generated
`.sherpa/ssh/config` file to jump to the lab nodes via the 
Sherpa server. 

`sherpa ssh` and [SSH provisioners](provisioners/ssh.md) use Sherpa's own SSH client, which
reads `.sherpa/ssh/config` as `ssh -F .sherpa/ssh/config` would. No `ssh` or `scp` program is
needed. Like `ssh`, they ask for your key's passphrase or your password on the Sherpa server
when they need them. Provisioners ask once per run and reuse the answer for every node. A key
loaded in your SSH agent (`ssh-add`; on Windows the OpenSSH agent service, or Pageant) needs no
prompt.

The Sherpa server's host key is checked against `~/.ssh/known_hosts`. The first time you
connect, you are shown its fingerprint and asked to confirm it, as with OpenSSH; a confirmed
key is recorded there. A server whose key has changed is refused.

## Node Host Keys

When a lab node answers on SSH, the Sherpa server records the host key it offers with the
node. The lab's keys are saved in a `known_hosts` file, `.sherpa/ssh/known_hosts`, next to
`.sherpa/ssh/config`, which `sherpa up` and `sherpa download` write in the lab folder. For each
node with a recorded key, `.sherpa/ssh/config` points to the file and checks the key strictly:

```
Host 172.31.1.21 dev01.abcd1234 dev01.abcd1234.sherpa.lab.local
    ...
    StrictHostKeyChecking yes
    UserKnownHostsFile /home/me/labs/dev/.sherpa/ssh/known_hosts
```

So you are never asked to confirm a node's key. This applies to `sherpa ssh`, provisioners,
and `ssh` itself through the `~/.ssh/config` include.

- **Which nodes:** virtual machines whose readiness check is SSH, on port 22. Containers,
  unikernels, nodes with another `ready_check.port`, nodes with `ready_check.skip`, and labs created
  before this feature keep `StrictHostKeyChecking no`.
- **When keys change:** some network operating systems, such as Cisco IOSv, make a new key
  every time they boot, and a redeployed node has a new one. The server records the new key
  when the node starts, whether from `sherpa resume`, `sherpa redeploy` or the web UI.
- **Keys that do not match:** when `sherpa ssh` or a provisioner finds that a node's key is
  missing from `.sherpa/ssh/known_hosts`, or is not the one recorded, it asks the server to read
  the node's key again, saves the lab's current keys and connects once more. A changed key
  is reported with a warning:

    ```
    Warning: the SSH host key of dev01 has changed. Loaded its new key from the Sherpa server.
    ```

- **`ssh` itself** cannot fetch keys. After a node's key changes, run any `sherpa` command
  that connects to it, or `sherpa download <lab-id> --force`, to update the file.

### Using the File Elsewhere

`.sherpa/ssh/known_hosts` is a standard OpenSSH `known_hosts` file, so other SSH tools can use it.
`UserKnownHostsFile` takes several files, so you can check lab nodes against it as well as
your own file:

```
Host 172.31.1.*
    UserKnownHostsFile ~/.ssh/known_hosts /home/me/labs/dev/.sherpa/ssh/known_hosts
```

Keys are recorded by address, as `172.31.1.21`, or `[172.31.1.21]:2222` for a port other than
22, the names `ssh` looks up when it connects to the address in `HostName`.

## Tunneling

SSH tunneling allows for the connection of remote resources from your local
machine by tunneling through SSH.

![An SSH tunnel: ssh on your machine listens on a local port, carries the connection over its encrypted SSH connection to sshd on the Sherpa server, and sshd connects through the lab's management bridge to the port on the lab node](ssh-tunnel.svg)

For example, connecting to a HTTP server running on a lab-node.

```
# ssh -N -L {local-port}:{node-ipv4}:{node-port} {sherpa-server}

ssh -N -L 9443:172.31.1.21:443 lab01
```

You can now open a browser and from `https://localhost:9443` access the web server
on the lab node `172.31.1.21:443` 

!!! Note
    In a future release, SSH tunneling of service ports will be built into Sherpa.
