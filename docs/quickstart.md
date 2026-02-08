# Quickstart

## Install

```
curl https://blah.bleh | sudo sh
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

Link describe how nodes are connected.

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
