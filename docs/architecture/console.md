# Serial Console

Every virtual machine and unikernel node has a serial console. `sherpa console <node>` opens it
in your terminal. Containers have no serial console; use `sherpa ssh`.

## How it Works

libvirt binds each node's serial console to a UNIX socket on the Sherpa server:

```
/opt/sherpa/run/console/<lab-id>/<node-index>.serial
```

Nothing listens on a network address for a console. Before 0.7.0 each console was a telnet
listener on a loopback address (`127.127.<lab>.<node-index>`, port `2323`) that any account on the
server could reach. That range is no longer used, and labs no longer get a loopback network.

Each lab's folder under `/opt/sherpa/run/console/` is owned `sherpa:kvm` with mode `2770`. Only
`sherpa`, members of `kvm` and root can reach the sockets. Members of `kvm` can already read
every lab's disks. `sherpad` creates the folder at `sherpa up` (and at `resume` or `redeploy` for
a lab made by an older release) and removes it at `sherpa destroy`.

## Connecting

`sherpa console` opens a WebSocket to `sherpad`:

```
GET /api/v1/labs/{lab_id}/nodes/{node_name}/console
```

It sends your login token as `Authorization: Bearer <token>` and uses the same TLS settings and
trusted certificate as every other command. `sherpad` connects to the node's socket and relays
the bytes in both directions. The bytes are raw serial data in binary frames, with no telnet
protocol. See the [API Reference](../api-reference.md#serial-console).

There is no SSH connection, so you need no SSH key or account on the server, and no `telnet`
program. It works the same on Windows.

## Who Can Connect

Only the lab's owner can open a node's console. Admins are refused too. The route takes only a
bearer token, not the web UI's session cookie.

## One Session

A console serves one session at a time. A second `sherpa console` to a console that is in use is
refused at once, and the message names the user, the client address and the time the session
began.

`sherpa console <node> --force` takes the console over from a session of your own, for example
one left open on another machine. The session taken over ends with a line saying who took it. A
session of another user is never taken over, though only the owner can open one.

## How a Session Ends

| Cause | Close code |
| ----- | ---------- |
| You escape with `Ctrl+]`, or `~.` at the start of a line | none; the client closes |
| The node stopped | `1000` |
| Another session took it over with `--force` | `4001` |
| The login behind the token ended: logout, password change, user deleted. Checked every 30 seconds | `4002` |
| The relay to the socket failed | `1011` |

## Guest Sessions

Disconnecting does not log the node's session out, because the serial port does not tell the
node. Log out before you disconnect. Since only the owner can attach, a session left logged in is
reachable only by the owner.

## Logging

`sherpad` logs each session as the events `console.opened`, `console.refused` and
`console.closed`, with the user, lab, node, client address, duration and reason. It never logs the
bytes.

## Nodes Running at an Upgrade

Nodes that are running when the server is upgraded to 0.7.0 keep their old TCP console until they
stop, and their console is refused. Stop and resume the lab, or redeploy the node. `sherpad` moves
every stopped node's console to its socket at startup, and `sherpa resume` moves a node's console
when it starts the node. See [Updating to 0.7.0](../install-update/update/sherpa.md#consoles-go-through-sherpad).
