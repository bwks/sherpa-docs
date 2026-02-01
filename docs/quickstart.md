# Quickstart

## Install

```
curl https://blah.bleh | sudo sh
```

## Nodes

In Sherpa, a node is a virtual machine or container
that is managed as part of a lab environment.

## Manifest

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
