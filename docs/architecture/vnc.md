# VNC

VNC (Virtual Network Computing) shows a virtual machine node's screen and takes its keyboard and
mouse. Use it for devices that need a graphical console, or when SSH is not up yet, for example
during the first boot or a password recovery. `sherpa vnc <node>` connects your own VNC viewer to
it, from any machine with the CLI.

## How it Works

Every virtual machine node has a VNC graphics adapter. QEMU listens for VNC on a UNIX socket on
the Sherpa server, next to the node's [serial console](console.md):

```
/opt/sherpa/run/console/<lab-id>/<node-index>.vnc
```

Nothing listens for VNC on a network port. Before 0.7.1 each VM had a VNC port on the server's
loopback address, from `5900` to `6999`, that any account on the server could reach. Nodes no
longer get a port, and `sherpa inspect`, the inspect API and the web UI no longer show one.

The socket is in the lab's console folder, owned `sherpa:kvm` with mode `2770`. Only `sherpa`,
members of `kvm` and root can reach it. Members of `kvm` can already read every lab's disks.

## Connecting

Run `sherpa vnc` in the lab's folder:

```
sherpa vnc <node> [--force]
```

It first asks the server whether you can open the node's VNC console, and stops with the reason
if not (see [Who Can Connect](#who-can-connect)). Then it opens a port on `127.0.0.1` on your
machine, picked by the system, and prints the address:

```
VNC console of ubu01 in lab my-lab: connect a VNC viewer to 127.0.0.1:40123. Ctrl+C to stop.
```

Point any VNC viewer at that address. Each connection your viewer makes is relayed over a
WebSocket to `sherpad`, which connects to the node's socket:

```
GET /api/v1/labs/{lab_id}/nodes/{node_name}/vnc
```

`sherpa vnc` sends your login token and uses the same TLS settings and trusted certificate as
every other command. See the [API Reference](../api-reference.md#vnc-console). There is no SSH
tunnel, so you need no SSH key or account on the server. It works the same on Windows.

`sherpa vnc` keeps listening until you press `Ctrl+C`, so your viewer can disconnect and connect
again. Viewers that read a small number after a colon as a display number take a port this
high as a port; TigerVNC's `vncviewer` also takes `127.0.0.1::40123`, with two colons, as always
meaning a port.

!!! note

    The port is on your machine's loopback address, but other accounts on your machine can
    connect to it while `sherpa vnc` runs. The node's VNC server asks for no password.

## Who Can Connect

Only the lab's owner can open a node's VNC console. Admins are refused too. `sherpa vnc` asks
the server before it opens a port, so a refusal ends it at once, with the server's reason and exit
code 1, and no address is printed:

- `Access denied: only the owner of lab '<lab-id>' can open its consoles`
- the node or lab not found, or `Not logged in`
- a container or a unikernel, which have no VNC console
- `Node '<node>' is not running. Start it with 'sherpa resume'.`
- a node still on its old VNC port (see [Nodes Running at an Upgrade](#nodes-running-at-an-upgrade))

A VNC console in use by another session of yours is not a refusal: `sherpa vnc` prints its address,
then `The VNC console of <node> is in use by <user> from <client-ip> since <time> UTC: viewers are
refused until that session ends, or take it over with 'sherpa vnc <node> --force'.`, and keeps
listening. With `--force` it says `...: a viewer connecting takes it over.` instead.

Once it is listening, the server checks again each time your viewer connects. If the console is
in use or the node has stopped by then, `sherpa vnc` prints the reason and keeps listening, so you
can connect again; any other refusal ends it.

## One Session

A VNC console serves one session at a time, as the serial console does, so one viewer at a time
sees and drives the screen. A node's VNC and serial consoles are separate: you can have both
open. While your viewer is connected, a second connection is refused at once with
`The VNC console of <node> is in use by <user> from <client-ip> since <time> UTC. Close that
session, or take it over with 'sherpa vnc <node> --force'.`

With `sherpa vnc <node> --force`, each connection takes the VNC console over from a session of
your own, for example one left open on another machine. A session of another user is never taken
over.

## How a Session Ends

A viewer's connection ends when the viewer disconnects, when you press `Ctrl+C`, when the node's
VNC server closes it (`The node's VNC console closed the connection.`, for example when the node
stops), when another session of yours takes it over with `--force`, and when your login ends. The
server checks the login every 30 seconds. `sherpa vnc` prints a line for each connection that
ends, with the server's reason.

`sherpad` logs each session as the events `console.opened`, `console.refused` and
`console.closed` with `console = "vnc"`, with the user, lab, node, client address, duration and
reason. It never logs the screen or the keys.

## Nodes Running at an Upgrade

Nodes that are running when the server is upgraded to 0.7.1 keep their VNC port until they stop,
and `sherpa vnc` refuses them with `Node '<node>' was started before its VNC console moved behind
Sherpa. Stop and resume the lab ('sherpa down', then 'sherpa resume'), or redeploy the node, to
use its VNC console.` `sherpad` moves every stopped node's VNC to its socket at startup, and
`sherpa resume` moves a node's VNC when it starts the node. See
[Updating to 0.7.1](../install-update/update/sherpa.md#vnc-goes-through-sherpad).

## Applicability

| Node Kind | VNC Available |
| --------- | ------------- |
| Virtual Machine | Yes |
| Container | No |
| Unikernel | No |
