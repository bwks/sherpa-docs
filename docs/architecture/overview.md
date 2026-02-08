# Overview

Sherpa is designed as a client/server architecture.

![Client/Server Architecture](client-server-architecture.svg)

## Client/Server

### Client

The `sherpa` client is is a CLI utility is used to interact with
the [sherpad](#server) service. The client can be installed on
Linux, MacOS and Windows.

### Server

The `sherpad` process runs as a systemd service and is installed
on the host compute server.

## Providers

Emulation technologies are supported via providers. The following
providers are currnetly supported:

- [Virtual Machine](virtual-machine.md)
- [Container](container.md)
- [Unikernel](unikernel.md)

## Virtual Machines

Virtual machines use the `KVM/QEMU` hypervisor stack.

### KVM/QEMU

INSERT KVM/QEMU Hypervisor stack diagram

### Libvirt

The Libvirt virtualisation API library is used as the
interface to manage virtual machines via Sherpa.

## Containers

Containers are supported via the Docker API.

### Docker

## Unikernels

Unikernels are supported via the NanoOS framework.

### NanoOS
