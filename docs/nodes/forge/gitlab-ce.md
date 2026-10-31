# GitLab Community Edition

GitLab CE is a container based image.

## Base Image

Base images can be obtained from [Docker Hub](https://hub.docker.com/r/gitlab/gitlab-ce).

### Import Image

Pull the image through Sherpa:

```
sherpa server image pull --model gitlab_ce --version 18.7.6-ce.0
```

Sherpa records the version, so a lab can use it. An image pulled only with the `docker` CLI is
not known to Sherpa, so a lab cannot use it.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 2         |
| RAM                  | 4GB       |
| ZTP Method           | None      |
| Management Interface | eth0      |
| Interface Driver     | macvlan   |

## Example Manifest

```toml
name = "gitlab-ce"

[[nodes]]
name = "gitlab01"
model = "gitlab_ce"
```

## Node Access

GitLab exposes a web UI on ports `80` and `443`.

=== "Web UI"

    From the server host, browse to `http://<gitlab_mgmt_ip>`.

=== "SSH Tunnel"

    ```
    ssh -L 8080:<gitlab_mgmt_ip>:80 user@sherpa-server
    ```

    Then browse to `http://localhost:8080`.

## Notes

- Approximate time for the system to be ready: `3 minutes`
- GitLab CE requires significant resources. The default allocation is 2 CPUs and 4GB RAM.
- The initial `root` password can be retrieved from the container after first boot.
