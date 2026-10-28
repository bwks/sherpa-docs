# Devbox Windows

Devboxes are nodes with a common set of tooling pre-installed.
Devbox Windows is a Windows 11 Enterprise developer workstation with
cloudbase-init, OpenSSH Server and [mise](https://mise.jdx.dev) for managing developer tools.

## Base Image

Microsoft does not provide ready built qcow2 images so you will need to build them yourself.
You can use [this](https://github.com/bwks/packer-devbox-windows) packer template to build a
Windows 11 Enterprise Evaluation image with cloudbase-init, an SSH server and the devbox tooling.

Sherpa runs Devbox Windows on SeaBIOS without a TPM or Secure Boot. The packer template
builds the image for that hardware, so other Windows 11 images may not boot.

## Import Image

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version windows11-20261028 \
  --model devbox_windows \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| CPU                  | 4               |
| RAM                  | 8GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP Method           | cloud-init      |
| Management Interface | eth0            |
| Data Interfaces      | eth1            |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "devbox-windows"

[[nodes]]
name = "dev01"
model = "devbox_windows"
```

## Node Access

=== "SSH"

    ```
    sherpa ssh dev01
    ```

=== "Console"

    ```
    sherpa console dev01
    ```

## Developer Tools

The image installs mise for all users, with the devbox tool selections in
`C:\ProgramData\mise\config.toml`. The tools are installed per user, so run
`mise install` once after the first login:

```powershell
mise install
```

This installs Node.js LTS, Rust (MSVC toolchain), GitHub CLI, Packer, Terraform, Azure CLI,
uv, ruff, ty, Claude Code, Codex, OpenCode, Pi and Herdr into the user's `%LOCALAPPDATA%\mise`.
Update them with `mise upgrade`.

Git for Windows, the Visual Studio C++ Build Tools, AWS CLI, Tailscale and Proton Pass CLI
are installed for all users, as mise cannot manage them on Windows.

## Notes

- The Windows 11 Enterprise Evaluation expires 90 days after the image is built.
- Docker, QEMU/KVM and other tools from [Devbox Linux](devbox-linux.md) that need nested
  virtualization or have no Windows release are not included.
- Run `tailscale up` to join the node to your tailnet.
