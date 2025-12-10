# About

Sherpa is a tool that aims to make creating IT infrastructure labs intuitive and painless.

## Why?

I love the workflow of Vagrant. Define an environment in a config file and
build/destroy it with a few commands. This also made sharing labs with peers much easier.

Docker came along and it's great when you can get by with only using Containers.
I come from a networking background and in that space, VM's are mostly still king.

## Project Goals

- Network based platforms are a first class citizen.
- Effortless VM <--> Container network stitching.
- ZTP all the things. No need to pre-provision Vagrant style boxes.
- HTTP/TFTP/PXE/cloud-init ZTP options for supported devices.
- Support for large topology scenarios.
- Labs defined in TOML files, with sane defaults and minimal boilerplate.
- Multiplayer support for teams with dreams.

## Hypervisor/Container Runtime Support

- Virtual Machines via KVM/QEMU and the [Libvirt](https://libvirt.org/) API.
- Containers via [Docker Engine](https://docs.docker.com/engine/).
