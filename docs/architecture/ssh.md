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
The config's `UserKnownHostsFile` is an absolute path to `.sherpa/ssh/known_hosts`, so `ssh -F .sherpa/ssh/config <node>.<lab-id>` works from the
lab folder.

A lab folder whose path has spaces is included in double quotes, as `ssh` needs. If
`~/.ssh/config` is a symbolic link, as dotfile managers make it, the file it points to is
updated and the link is kept. Each file is replaced whole, keeping its permissions, so an
interrupted update never leaves it cut short.

## Logging In to Nodes

Every node logs in as you, with your own [SSH keys](ssh-keys.md) or your
[device password](device-password.md), so `.sherpa/ssh/config` names your username and no
identity file:

```
Host 172.31.1.22 router1.abcd1234 router1.abcd1234.sherpa.lab.local
    User alice
```

`ssh`, `sherpa ssh` and provisioners use the keys in your SSH agent or your default key files.

- **Redeploy:** `sherpa redeploy` rebuilds the node with your login.

## Reaching Nodes

`.sherpa/ssh/config` reaches every node directly, at its management address, with no jump host.
That works from wherever the lab's management network is routed:

- **The Sherpa server itself.**
- **A machine on the lab's tailnet** that accepts its routes, for a lab with a
  [Tailscale gateway](networking/tailscale.md).

`sherpa ssh` and [SSH provisioners](provisioners/ssh.md) use Sherpa's own SSH client, which
reads `.sherpa/ssh/config` as `ssh -F .sherpa/ssh/config` would. No `ssh` or `scp` program is
needed. Like `ssh`, they ask for your key's passphrase when they need it. Provisioners ask once
per run and reuse the answer for every node, and never ask for a node's password. A key loaded
in your SSH agent (`ssh-add`; on Windows the OpenSSH agent service, or Pageant) needs no prompt.

When a node cannot be reached from your machine, `sherpa ssh` and the provisioners stop at once,
after waiting at most 10 seconds for the node to answer, rather than retrying until the lab's
ready timeout:

```
dev01 at 172.31.1.21:22 is not reachable from this machine (no answer within 10s). Use --ssh-jump to go through the Sherpa server, or join the lab's tailnet and accept its routes.
```

They never fall back to the jump on their own.

## Jump Through the Sherpa Server

From a machine with no route to the management network, such as a laptop off the lab's tailnet,
go through the Sherpa server as an SSH jump host. Add `--ssh-jump` to the command, as `ssh -J`
adds a jump to a config that has none:

```
sherpa ssh dev01 --ssh-jump
sherpa provision --ssh-jump
sherpa up --ssh-jump
sherpa redeploy -n dev01 --ssh-jump
```

The jump is `<user>@<server>`: your Sherpa username, at the host of the server URL the CLI uses.
It applies to that one command; nothing is saved in the manifest or the lab folder. It needs an
account on the Sherpa server's host of the same name as your Sherpa user, that accepts your SSH
key. Sherpa does not create it: ask the server's administrator.

With plain OpenSSH, add the jump yourself:

```
ssh -F .sherpa/ssh/config -J alice@sherpa.example.com dev01.abcd1234
```

If your key has a passphrase or the server needs your password, you are asked for it, once per
run for provisioners. The Sherpa server's host key is checked against `~/.ssh/known_hosts`. The
first time you connect, you are shown its fingerprint and asked to confirm it, as with OpenSSH; a
confirmed key is recorded there. A server whose key has changed is refused.

## Node Host Keys

When a lab node answers on SSH, the Sherpa server records the host key it offers with the
node in its database, and builds the lab's `known_hosts` file from the recorded keys when it
sends it. The lab's keys are saved in a `known_hosts` file, `.sherpa/ssh/known_hosts`, next to
`.sherpa/ssh/config`, which `sherpa up` and `sherpa download` write in the lab folder. For each
node with a recorded key, `.sherpa/ssh/config` points to the file and checks the key strictly:

```
Host 172.31.1.21 dev01.abcd1234 dev01.abcd1234.sherpa.lab.local
    ...
    StrictHostKeyChecking yes
    UserKnownHostsFile /home/me/labs/dev/.sherpa/ssh/known_hosts
```

So you are never asked to confirm a node's key. This applies to `sherpa ssh`, provisioners,
and `ssh` itself through the `~/.ssh/config` include, with or without the jump.

- **Which nodes:** virtual machines whose readiness check is SSH, on port 22, and containers
  with `ready_check.port = 22`. Other containers, unikernels, nodes with another
  `ready_check.port` and nodes with `ready_check.skip` keep
  `StrictHostKeyChecking no`.
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
