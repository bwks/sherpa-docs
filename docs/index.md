# Sherpa

Sherpa is a lab management platform that brings virtual machines, containers, and unikernels together
under a unified control plane. Define your topology in a simple TOML file, and Sherpa handles the rest — 
networking, storage, and initial configuration.

**Define a lab topology**
```toml
# manifest.toml
name = "my-lab"

nodes = [
  { name = "spine01", model = "arista_ceos" },
  { name = "spine02", model = "arista_ceos" },
  { name = "leaf01",  model = "sonic_linux" },
  { name = "leaf02",  model = "sonic_linux" },
  { name = "srv01",   model = "ubuntu_linux" },
]

links = [
  { src = "spine01::eth1", dst = "leaf01::eth1" },
  { src = "spine01::eth2", dst = "leaf02::eth1" },
  { src = "spine02::eth1", dst = "leaf01::eth52" },
  { src = "spine02::eth2", dst = "leaf02::eth52" },
  { src = "leaf01::eth1",  dst = "srv01::eth1" },
]
```

**Build the lab**
```
sherpa up
```

That's it. Five nodes, five links, one command.

---

## Why Sherpa?

- **Mixed workloads** — Run VMs and containers side-by-side with seamless network stitching.
- **Zero-touch provisioning** — Nodes boot fully configured. No pre-baked images or manual setup.
- **Minimal boilerplate** — Sane defaults mean most nodes need only a `name` and `model`.
- **Multi-vendor support** — Cisco, Arista, Juniper, Nokia, Sonic, Palo Alto, and many more.
- **Scales up** — Build topologies with hundreds of nodes.
- **Multiplayer** — Multiple users on the same server, each with their own isolated labs.

## Getting Started

Head to the [Quickstart](quickstart.md) guide for the full walkthrough.

## Source Code

- [GitHub](https://github.com/sherpalabs-net)
