# CLAUDE.md - Sherpa Docs

## Project Overview

This is the MkDocs documentation site for the [Sherpa](https://docs.sherpa.com) project — a lab management platform for building virtual network topologies using VMs (libvirt/KVM/QEMU), containers (Docker), and unikernels.

The Sherpa source code lives at `../sherpa`. Refer to that codebase when you need to verify features, CLI commands, models, default parameters, or implementation details.

## Tech Stack

- **MkDocs** with **Material** theme (Catppuccin color schemes)
- Markdown with extensions: admonition, superfences, tabbed content, TOC with permalinks
- Custom CSS in `docs/stylesheets/`
- Docker support for building/serving docs

## Project Structure

```
docs/
├── index.md, about.md, quickstart.md, manifest.md, command-reference.md
├── architecture/          # How sherpa works (VMs, containers, networking, storage, etc.)
├── install-update/        # Installation and update guides
├── configuration/         # sherpa.toml configuration
├── nodes/<vendor>/        # Per-device/service documentation (16+ vendors)
├── examples/              # Lab topology examples
├── help/                  # Troubleshooting guides
└── stylesheets/           # Custom CSS
```

Navigation is defined in `mkdocs.yml`. Update it when adding new pages.

## Node Documentation Template

All node pages follow a consistent structure. Use this template:

### Virtual Machine Nodes

```markdown
# [Device Name]

## Base Image

[Download source or vendor reference link]

## Import Image

```
sherpa server image import \
  --src <filename> \
  --version <version> \
  --model <model_name> \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | <version>       |
| CPU                  | <count>         |
| RAM                  | <size>          |
| CDROM Driver         | <driver>        |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | <driver>        |
| ZTP Method           | <method>        |
| Management Interface | <interface>     |
| Data Interfaces      | <range>         |
| Interface Driver     | <driver>        |

## Example Manifest

```toml
name = "<lab-name>"

nodes = [
  { name = "dev01", model = "<model_name>" },
]
```

## Notes

- Approximate time for the system to be ready: `X minutes`
```

### Container Nodes

Container nodes differ slightly:
- Use `sherpa server image pull <image>:<tag>` for import (not `image import`)
- Mention Docker CLI as an alternative import method
- Parameters table uses `Container` for Kind, includes `macvlan` interface driver
- No CDROM/DISK fields in the parameters table
- ZTP Method is typically `Volume`
- Example manifest includes `version` field in the node definition

## Writing Style

- **Direct and concise** — no filler, no marketing language
- **H1** for page title, **H2** for major sections, **H3** for subsections
- Code blocks use triple backticks with language identifiers (`bash`, `toml`, etc.)
- Use `inline code` for commands, filenames, model names, interface names
- Use admonitions (`!!! info`, `!!! warning`, `!!! danger`) sparingly for important callouts
- Tables for specifications and parameter lists
- Cross-reference other docs with relative markdown links: `[text](relative/path.md)`
- Model names use underscores: `cisco_asav`, `ubuntu_linux`, `mysql`
- Lab names in manifests use hyphens: `cisco-asav`, `ubuntu-linux`

## Key Rules

- All configuration files referenced in docs use **TOML format only** (no JSON/YAML/INI)
- The manifest file is `manifest.toml` — document it accordingly
- The sherpa config file is `sherpa.toml`
- Verify model names and CLI commands against the Rust source at `../sherpa` when uncertain
- When adding a new node page, also add its entry to the `nav` section of `mkdocs.yml`

## Git

- Use `git config user.name "Claude"` and `git config user.email "noreply@anthropic.com"` for commits in this repo.
- Use the `gh` CLI for all GitHub operations (push, PRs, issues). Auth is configured via `GH_TOKEN`. Run `gh auth setup-git` before `git push` if needed.

## Building / Serving Docs

```bash
# Serve locally (from project root)
docker compose up

# Or with mkdocs directly
mkdocs serve
```
