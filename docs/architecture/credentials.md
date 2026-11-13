# Node Credentials

Node credentials are configured via ZTP during the first boot.

## Default Credentials

The default credentials for all nodes are:

| Username | Password       | SSH Key                                  |
| -------- | -------------- | ---------------------------------------- |
| `sherpa` | `Everest1953!` | `.sherpa/ssh/key`, in the lab's folder   |

!!! Info

    `sherpa up` makes a new SSH key pair for each lab, and `sherpa up` and
    `sherpa download` save it to your lab folder. See
    [Lab SSH Key](ssh.md#lab-ssh-key).

## User Credentials

User specific credentials can be applied via ZTP.

!!! info

    Documentation for user credential configuration is in progress.

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
