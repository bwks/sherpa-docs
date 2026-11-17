# Windows Server

## Base Image

Microsoft does not provide ready built qcow2 images so you will need to build them yourself.
You can use [this](https://github.com/bwks/packer-windows) packer template to build windows
images with cloudbase-init and an SSH server enabled. 

Currently, only Windows Server 2022 is supported, but more versions are coming soon.

## Import

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version 2022-20261026 \
  --model windows_server \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 2022-20261026   |
| CPU                  | 4               |
| RAM                  | 8GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `cloud-init`    |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "silly-sausage"

[[nodes]]
name = "dev01"
model = "windows_server"
```


## Accounts

Your account, with your username, your keys and your [device password](../../architecture/device-password.md),
is the node's only enabled login, a member of `Administrators`. At first boot Sherpa disables
every other enabled local account, after your account exists and before the node's
`startup_scripts` run:

| Account | Where it comes from | State |
| ------- | ------------------- | ----- |
| you | Sherpa's cloudbase-init user data | enabled |
| `Administrator` | the image's built-in administrator | disabled |
| `Admin` | cloudbase-init's `CreateUserPlugin`, named by `username` in the image's `cloudbase-init.conf`, with a random password | disabled |
| `Guest`, `DefaultAccount`, `WDAGUtilityAccount` | Windows | disabled, as shipped |

Accounts your `startup_scripts` create are left alone. If your account cannot be created, no
account is disabled. Check with `Get-LocalUser` in PowerShell.

## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes

- Approximate time for the system to be ready: `3 minutes`
