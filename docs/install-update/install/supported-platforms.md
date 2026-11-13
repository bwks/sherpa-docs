# Supported Platforms

The Sherpa platform has both client and server applications.

## Sherpa Server

Sherpa server is available for Linux operating systems only.

## Sherpa Client

The `sherpa` CLI is available for Windows (x86_64), Linux (x86_64) and macOS (Intel and Apple
silicon). The binaries are on the GitHub [releases](https://github.com/bwks/sherpa/releases) page;
see [Client](client.md) for how to install them.

## Host Machine

Sherpa server is tested with Intel `i9` and `xeon` series x86_64 CPU's.

## Host Operating System

Sherpa is tested on the `two` most recent version of Ubuntu server LTS.
The current LTS version under test is `24.04` and will move to `26.04` once it's released.

## Virtualization Provider

The `QEMU/KVM/Libvirt` stack is used for Virtual Machine nodes.

## Container Provider

`Docker Engine` is used for containerized nodes.
