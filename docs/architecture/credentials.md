# Node Credentials

Node credential are configured via ZTP during the first boot.

## Default Credentials

The default credentials for all node are:

| Username | Password       | SSH Key                      |
| -------- | -------------- | ---------------------------- |
| `sherpa` | `Everest1953!` | `/opt/sherpa/sherpa_ssh_key` |

!!! Info

    A unique SSH key-pair is generated when the `sherpa init`
    command is executed.

## User Credentials

User specific credentials can be applied via ZTP.

TODO: Update process.

## Custom Credentials

Default credentials are defined under the `ztp_server` section
in the `/opt/sherpa/sherpa.toml` configuration file.

```toml
# /opt/sherpa/sherpa.toml
[ztp_server]
enable = true
username = "sherpa"
password = "Everest1953!"
```
