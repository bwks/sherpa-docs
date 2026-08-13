# Infrahub Server

Infrahub Server is a virtual machine based image built on top of a Linux base with cloud-init support.

## Base Image

A cloud-init enabled Linux qcow2 image with [Infrahub](https://docs.infrahub.app) pre-installed is required.
You can use [this](https://github.com/bwks/packer-infrahub) packer template to build the image.

## Import Image

```
sherpa server image import \
  --src infrahub-server.qcow2 \
  --version 0.1.0 \
  --model infrahub_server \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| CPU                  | 6               |
| RAM                  | 12GB            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Data Interfaces      | eth1            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "infrahub-server"

nodes = [
  { name = "infrahub01", model = "infrahub_server" },
]
```

## Node Access

Infrahub exposes a web UI on port `8000`.

=== "Web UI"

    From the server host, browse to `http://<infrahub_mgmt_ip>:8000`.

=== "SSH"

    ```
    sherpa ssh infrahub01
    ```

=== "SSH Tunnel"

    ```
    ssh -L 8000:<infrahub_mgmt_ip>:8000 user@sherpa-server
    ```

    Then browse to `http://localhost:8000`.

## Notes

- Default web UI login: `admin` / `infrahub`. The image ships with Infrahub's stock
  credentials and default API token, do not expose it to untrusted networks without
  changing them.
- First boot starts the full Infrahub docker compose stack from pre-pulled images.
- Approximate time for the system to be ready: `5 minutes`
