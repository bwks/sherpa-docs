# About

Sherpa is a tool that aims to make creating IT infrastructure labs intuitive and painless.

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

## Device Support Matrix

- ✅ - Working
- 🚧 - Planned
- ⚠️ - Partially Working

| Vendor    | Model          | Minimum Tested Version | Status | ZTP Method     |
| --------- | -------------- | ---------------------- | ------ | -------------- |
| Arista    | vEOS           | 4.32.2f                | ✅     | TFTP           |
| Aruba     | AOS-CX         | 10.07                  | ✅     | TFTP           |
| Cisco     | ASAv           | 9.20.2                 | ✅     | CDROM          |
| Cisco     | CSR 1000v      | 17.03.08a              | ✅     | CDROM          |
| Cisco     | Catalyst 8000v | 17.13.01a              | ✅     | CDROM          |
| Cisco     | Catalyst 9000v | 17.12.01               | ✅     | CDROM          |
| Cisco     | XRv 9000       | 7.11.1                 | ✅     | CDROM          |
| Cisco     | Nexus 9300v    | 10.4.2.f               | ✅     | CDROM          |
| Cisco     | IOSv           | 159-3.m8               | ✅     | Disk           |
| Cisco     | IOSv L2        | 20200920               | ✅     | Disk           |
| Juniper   | vRouter        | 23.4R2-S2.1            | ✅     | CDROM          |
| Juniper   | vSwitch        | 23.4R2-S2.1            | ✅     | CDROM          |
| Juniper   | vSRXv3         | 23.2R2.21              | ✅     | CDROM          |
| Juniper   | vEvolved       | 23.4R2-S2.1            | ✅     | TFTP           |
| Nvidia    | Cumulus Linux  | 5.9.2                  | ✅     | USB            |
| Nokia     | SR Linux       | 24.10.1                | ✅     | TBA            |
| Microsoft | FlatCar Linux  | 3975.2.2               | ✅     | Ignition       |
| Microsoft | Windows Server | 2024                   | ✅     | CloudBase-Init |
| Canonical | Ubuntu Linux   | 24.04                  | ✅     | Cloud-Init     |
| RedHat    | Fedora Linux   | 40-1.14                | ✅     | Cloud-Init     |
| SONiC     | Sonic Linux    | 25051122               | ✅     | TFTP           |
