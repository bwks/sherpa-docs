# Nautobot Server

Nautobot Server is a virtual machine based image built on top of a Linux base with cloud-init support.

## Base Image

A cloud-init enabled Linux qcow2 image with Nautobot pre-installed is required.
You can use [this](https://github.com/bwks/packer-nautobot) packer template to build the image.

## Import Image

```
sherpa server image import \
  --src nautobot-server.qcow2 \
  --version 0.1.0 \
  --model nautobot_server \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 4GB             |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Data Interfaces      | eth1            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "nautobot-server"

nodes = [
  { name = "nautobot01", model = "nautobot_server" },
]
```

## Node Access

Nautobot exposes a web UI on port `443`.

=== "Web UI"

    From the server host, browse to `https://<nautobot_mgmt_ip>`.

=== "SSH"

    ```
    sherpa ssh nautobot01
    ```

=== "SSH Tunnel"

    ```
    ssh -L 8443:<nautobot_mgmt_ip>:443 user@sherpa-server
    ```

    Then browse to `https://localhost:8443`.

## Notes

- Approximate time for the system to be ready: `3 minutes`
