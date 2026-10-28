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

## Node Host Keys

When a lab node answers on SSH, the Sherpa server records the host key it offers with the
node. The lab's keys are saved in a `known_hosts` file named `sherpa_known_hosts`, next to
`sherpa_ssh_config`, which `sherpa up` and `sherpa download` write to the lab folder. For each
node with a recorded key, `sherpa_ssh_config` points to the file and checks the key strictly:

```
Host 172.31.1.21 dev01.abcd1234 dev01.abcd1234.sherpa.lab.local
    ...
    StrictHostKeyChecking yes
    UserKnownHostsFile /home/me/labs/dev/sherpa_known_hosts
```

So you are never asked to confirm a node's key. This applies to `sherpa ssh`, provisioners,
and `ssh` itself through the `~/.ssh/config` include.

- **Which nodes:** virtual machines whose readiness check is SSH, on port 22. Containers,
  unikernels, nodes with another `ready_port`, nodes with `skip_ready_check`, and labs created
  before this feature keep `StrictHostKeyChecking no`.
- **When keys change:** some network operating systems, such as Cisco IOSv, make a new key
  every time they boot, and a redeployed node has a new one. The server records the new key
  when the node starts, whether from `sherpa resume`, `sherpa redeploy` or the web UI.
- **Keys that do not match:** when `sherpa ssh` or a provisioner finds that a node's key is
  missing from `sherpa_known_hosts`, or is not the one recorded, it asks the server to read
  the node's key again, saves the lab's current keys and connects once more. A changed key
  is reported with a warning:

    ```
    Warning: the SSH host key of dev01 has changed. Loaded its new key from the Sherpa server.
    ```

- **`ssh` itself** cannot fetch keys. After a node's key changes, run any `sherpa` command
  that connects to it, or `sherpa download <lab-id> --force`, to update the file.

### Using the File Elsewhere

`sherpa_known_hosts` is a standard OpenSSH `known_hosts` file, so other SSH tools can use it.
`UserKnownHostsFile` takes several files, so you can check lab nodes against it as well as
your own file:

```
Host 172.31.1.*
    UserKnownHostsFile ~/.ssh/known_hosts /home/me/labs/dev/sherpa_known_hosts
```

Keys are recorded by address, as `172.31.1.21`, or `[172.31.1.21]:2222` for a port other than
22, the names `ssh` looks up when it connects to the address in `HostName`.

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
