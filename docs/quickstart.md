# Quickstart

## Install

The quickest way to get started with Sherpa is to use the convenience installer [script](install-update/install/automated.md).

```
curl https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_install.sh | sudo bash
```

This will install all the dependencies as well as the Sherpa, 
server and client binaries.

## Sherpa Server
Initialize the Sherpa server.
```
sherpad init
```

## Sherpa Client
Initialize the Sherpa client.
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
Run the following command to start a lab.
```
sherpa up
```

## Access
Devices are available via SSH.
```
sherpa ssh dev01
```

## Destroy
Tear down the lab when you are finished.
```
sherpa destroy
```
