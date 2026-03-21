# Jenkins Server

Jenkins Server is a virtual machine based image built on top of a Linux base with cloud-init support.

## Base Image

A cloud-init enabled Linux qcow2 image with Jenkins pre-installed is required.
You can use [this](https://github.com/bwks/packer-jenkins) packer template to build the image.

## Import Image

```
sherpa server image import \
  --src jenkins-server.qcow2 \
  --version 0.1.0 \
  --model jenkins_server \
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
name = "jenkins-server"

nodes = [
  { name = "jenkins01", model = "jenkins_server" },
]
```

## Node Access

Jenkins exposes a web UI on port `8080`.

=== "Web UI"

    From the server host, browse to `http://<jenkins_mgmt_ip>:8080`.

=== "SSH"

    ```
    sherpa ssh jenkins01
    ```

=== "SSH Tunnel"

    ```
    ssh -L 8080:<jenkins_mgmt_ip>:8080 user@sherpa-server
    ```

    Then browse to `http://localhost:8080`.

## Notes

- Approximate time for the system to be ready: `3 minutes`
- The initial admin password can be retrieved from `/var/lib/jenkins/secrets/initialAdminPassword` inside the VM.
