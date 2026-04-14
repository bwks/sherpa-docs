# VNC

VNC (Virtual Network Computing) provides graphical console access to virtual machine nodes. This is useful for devices that require GUI interaction or when SSH is not yet available (e.g., during initial boot or password recovery).

## How it Works

Every virtual machine node in Sherpa is configured with a VNC graphics adapter via libvirt. The VNC server is automatically started by QEMU when the VM is created, with an auto-assigned port.

The libvirt domain definition includes:

```xml
<graphics type='vnc' port='-1' autoport='yes'/>
```

Setting `port='-1'` with `autoport='yes'` tells QEMU to automatically assign an available port starting from `5900`.

## Finding the VNC Port

The VNC port for each VM node is displayed in the `sherpa inspect` output under the `VNC Port` column.

```
sherpa inspect
```

The VNC port is extracted from the running libvirt domain at inspect time. Container and unikernel nodes do not have VNC ports.

## Connecting

### From the Sherpa Server

If you have direct access to the Sherpa server, connect with any VNC client:

```
vncviewer localhost:<vnc-port>
```

### From a Remote Machine

Use SSH tunneling to forward the VNC port from the Sherpa server to your local machine:

```bash
# ssh -N -L {local-port}:{node-ipv4}:{vnc-port} {sherpa-server}

ssh -N -L 5900:172.31.0.11:5900 sherpa-server
```

Then connect your VNC client to `localhost:5900` on your local machine.

## Applicability

| Node Kind | VNC Available |
| --------- | ------------- |
| Virtual Machine | Yes |
| Container | No |
| Unikernel | Yes |

!!! note

    VNC binds to `localhost` on the Sherpa server by default. It is not exposed externally — use SSH tunneling for remote access.
