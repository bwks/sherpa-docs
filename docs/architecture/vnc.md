# VNC

VNC (Virtual Network Computing) provides graphical console access to virtual machine nodes. This is useful for devices that require GUI interaction or when SSH is not yet available (e.g., during initial boot or password recovery).

## How it Works

Every virtual machine node in Sherpa has a VNC graphics adapter. When the lab is created, Sherpa
reserves a VNC port on the server for each VM, from `5900` to `6999`, and the VM keeps it for its
life: stopping, resuming and redeploying the node do not change it. The port is written into the
libvirt domain, for example:

```xml
<graphics type='vnc' port='5901' autoport='no'/>
```

## Finding the VNC Port

The VNC port for each VM node is displayed in the `sherpa inspect` output under the `VNC Port` column.

```
sherpa inspect
```

The web UI's node page shows it too. Container and unikernel nodes do not have VNC ports.

## Connecting

### From the Sherpa Server

If you have direct access to the Sherpa server, connect with any VNC client:

```
vncviewer localhost:<vnc-port>
```

### From a Remote Machine

Use SSH tunneling to forward the VNC port from the Sherpa server to your local machine:

```bash
# ssh -N -L {local-port}:localhost:{vnc-port} {sherpa-server}

ssh -N -L 5901:localhost:5901 sherpa-server
```

Then connect your VNC client to `localhost:5901` on your local machine.

## Applicability

| Node Kind | VNC Available |
| --------- | ------------- |
| Virtual Machine | Yes |
| Container | No |
| Unikernel | No |

!!! note

    VNC binds to `localhost` on the Sherpa server by default. It is not exposed externally — use SSH tunneling for remote access.
