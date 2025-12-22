# About

Sherpa makes building IT infrastructure labs intuitive and painless.

## Why?

I love the workflow of Vagrant, define an environment in a config file
and manage Virtual Machine lifecycle with a few commands.

Then, Docker came along and it's awesome when you are only using Containers.
Le-sigh, I came from a networking background and in that space, VM's are mostly still king.

Sherpa takes the convenience of these tools and dials them up to 🔥 `over 9000` 🔥.

## Project Goals

- Network based platforms are a first class citizen.
- Effortless VM <--> Container network stitching.
- ZTP all the things. No need to pre-provision Vagrant style boxes.
- HTTP/TFTP/PXE/cloud-init ZTP options for supported devices.
- TLS certificate generation.
- Support for large topologies up to hundreds of nodes.
- Labs defined in TOML files, with sane defaults and minimal boilerplate.
- Multiplayer support, for teams with dreams.

## Hypervisor/Container Runtime Support

- Virtual Machines via KVM/QEMU and the [Libvirt](https://libvirt.org/) API.
- Containers via [Docker Engine](https://docs.docker.com/engine/).
