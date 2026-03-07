# Quickstart

## Install

The quickest way to get started with Sherpa is to use the convenience [script](install-update/install/automated.md).

```
curl https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_install.sh | sudo bash
```

## Sherpa Server

```
sherpad init
```

## Sherpa Client
```
sherpa init
```

## Manifest

A manifest describes the lab topology and node configuration parameters.

```toml
# manifest.toml
name = "labrador-infiniato"

nodes = [
  { name = "dev01", model = "sonic_vlinux" },
  { name = "dev02", model = "sonic_vlinux" },
]

links = [
  { src = "dev01::eth2", dst = "dev02::eth2" },
]
```

### Nodes

A node is a virtual machine, container or unikernel
that is managed as part of a lab environment.

### Links

Links describe how nodes are connected.

## Build

```
sherpa up
```

## Access

```
sherpa ssh dev01
```

## Destroy

```
sherpa destroy
```
