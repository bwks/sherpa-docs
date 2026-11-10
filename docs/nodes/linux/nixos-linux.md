# NixOS

## Base Image

NixOS does not publish a cloud-init enabled disk image, so you build one from the NixOS
configuration in [bwks/nixos-image](https://github.com/bwks/nixos-image). It is a flake:
`flake.nix` picks the NixOS release, `flake.lock` pins the exact packages, and
`configuration.nix` sets the system up for Sherpa:

- cloud-init, which applies Sherpa's accounts, SSH keys, hostname and management address on
  first boot;
- interfaces named `eth0`, `eth1`, ..., as in the manifest;
- passwordless `sudo` for the `wheel` group, which Sherpa's accounts join;
- SSH password logins allowed, as on Sherpa's other Linux nodes;
- the serial console, for `sherpa console`.

You can add your own packages and services to `configuration.nix` before building, the NixOS way
of customising an image.

## Build Image

With [Nix](https://nixos.org/download/) installed:

```
git clone https://github.com/bwks/nixos-image.git
cd nixos-image
nix --extra-experimental-features "nix-command flakes" build \
  .#nixosConfigurations.sherpa-node.config.system.build.images.qemu
cp -L result/*.qcow2 /some/path/nixos.qcow2
```

Without Nix installed, build it in the official `nixos/nix` container. The build runs a small VM,
so the container needs `/dev/kvm`:

```
cd nixos-image
docker run --rm --device /dev/kvm -v "$PWD:/src" -w /src nixos/nix sh -c '
  git config --global --add safe.directory /src
  nix --extra-experimental-features "nix-command flakes" --option sandbox false \
    --option system-features "kvm nixos-test benchmark big-parallel" \
    build .#nixosConfigurations.sherpa-node.config.system.build.images.qemu
  mkdir -p out && cp -L result/*.qcow2 out/nixos.qcow2'
```

The image is written to `out/nixos.qcow2`, owned by `root`. A build takes about 5 minutes.
To reuse downloaded packages between builds, add `-v sherpa-nix-store:/nix` to keep the Nix
store in a Docker volume.

To move to newer packages within the release, run `nix flake update` in the `nixos-image` checkout before
building.

## Import Image

```
sherpa server image import \
  --src /some/path/nixos.qcow2 \
  --model nixos_linux \
  --version 26.05 \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Tested Version       | 26.05           |
| Kind                 | Virtual Machine |
| CPU                  | 2               |
| RAM                  | 2GB             |
| BIOS                 | SeaBIOS         |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `cloud-init`    |
| Management Interface | eth0            |
| Interface Driver     | virtio          |

More memory than the other distros, because rebuilding the system with `nixos-rebuild` runs Nix
on the node.

## Example Manifest

```toml
name = "nixos-lab"
provision_current_user = true

[[nodes]]
name = "nix01"
model = "nixos_linux"
```

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

- Approximate time for the system to be ready: `30 seconds`
- Accounts use Bash from the system profile, `/run/current-system/sw/bin/bash`: NixOS has no
  `/bin/bash`. Scripts with a `#!/bin/bash` shebang need `#!/usr/bin/env bash` instead.
- Admin rights come from the `wheel` group. See [Personal Accounts](../../architecture/personal-accounts.md).
- Changes made with `nixos-rebuild switch` on the node keep Sherpa's accounts, because the image
  keeps `users.mutableUsers` on.
