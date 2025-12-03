# About

Sherpa is a IT lab tool inspired by the Vagrant, Containerlab and Netlabs of the world.

## Why?

I love the workflow of Vagrant. Define an environment in a config file and
build/destroy it with a few commands. This also made sharing labs with peers much easier.

Docker came along and it's great when you can get by with only using Containers.
I come from a networking background and in that space, VM's are mostly still king.

## Project Goals

- Multi-threaded/Asynchronous all the things.
- Effortless VM <--> Container network stitching.
- No need to pre-provision Vagrant style boxes.
- HTTP/TFTP/PXE/cloud-init ZTP options for all supported devices.
- Network based platforms are a first class citizen.
- Support for large topology scenarios.
- Labs defined in TOML files, with sane defaults and minimal effort.
- Multiplayer support for teams with dreams.

## Hypervisor/Container Runtime Support

- Initially only KVM/QEMU will be supported via [libvirt](https://libvirt.org/)
- Potential future [Cloud Hypervisor](https://github.com/cloud-hypervisor/cloud-hypervisor) support.
- Docker
