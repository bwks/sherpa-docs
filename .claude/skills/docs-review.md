---
name: docs-review
description: Review sherpa-docs against the sherpa codebase to identify documentation gaps, stale content, and missing features.
user_invocable: true
---

# Docs Review Skill

Review the sherpa documentation against the sherpa source code to identify what needs updating.

## Safety Rules

- **NEVER edit files in `../sherpa/`** — the sherpa codebase is a read-only reference. Only files in `./` may be created or modified.
- The sherpa repo is the source of truth for features, models, commands, and API operations. Read it to verify what the docs should say, but never change it.

## Instructions

You are reviewing the documentation site at `./` against the sherpa codebase at `../sherpa/`.

Perform the following checks and report findings in a structured format.

### 1. CLI Command Coverage

Read the CLI command definitions from `../sherpa/crates/client/src/cmd/cli.rs` and the server/image/user subcommand files in `crates/client/src/cmd/server/` and `crates/client/src/cmd/image.rs`. Compare against `./docs/command-reference.md`.

For each command in code:
- Is it documented?
- Are all flags/options listed?
- Is the description accurate?

### 2. Node Model Coverage

Read the `NodeModel` enum from `../sherpa/crates/shared/src/data/node.rs` and compare against the node pages in `./docs/nodes/`.

For each model in code:
- Does a docs page exist?
- Is the page included in `mkdocs.yml` nav (not commented out)?
- Does the model name in docs match the code enum variant exactly?

Also check the reverse direction: for each node page in docs, verify the model name it references actually exists in the `NodeModel` enum. Flag any docs pages that reference non-existent models.

Pay special attention to naming mismatches — model names that are similar but not identical between code and docs (e.g. code says `paloalto_panos` but docs page uses `paloalto_pavm`). These cause users to put the wrong model name in their manifests.

Additionally, verify that each node page uses the correct import command for its node kind:
- **Virtual Machine / Unikernel nodes** should use `sherpa server image import`
- **Container nodes** should use `sherpa server image pull`

### 3. Manifest Field Coverage

Read the manifest structs from `../sherpa/crates/topology/src/` (manifest.rs, node.rs, link.rs, bridge.rs) and compare against `./docs/manifest.md`.

For each field:
- Is it documented in the manifest reference?
- Is the type/description accurate?

Pay particular attention to:
- **Top-level fields**: `ready_timeout`, `ztp_server`, `config_management`
- **Node fields**: All properties in the `Node` struct (there are 25+)
- **Link impairment**: The `ManifestImpairment` struct has fields `delay` (u32), `jitter` (u32), `loss_percent` (f32), `reorder_percent` (f32), `corrupt_percent` (f32) — verify these are all documented
- **Link p2p flag**: The `p2p` boolean on `Link2`
- **Bridge**: Full `name` + `links` array documentation

### 4. API Reference Page

The API spec is auto-generated from code (`crates/shared/src/api_spec.rs` → OpenAPI 3.1 at `GET /api/v1/spec`). Do NOT audit individual operations — they are maintained in code.

Instead, check whether sherpa-docs has a page that:
- Points users to the live OpenAPI spec endpoint
- Explains the three transports (REST, WebSocket RPC, CLI)
- Notes authentication methods (JWT Bearer, Cookie)

If no such page exists, flag it as missing.

### 5. Architecture & Feature Coverage

Check the following code areas against corresponding docs:

- **Configuration**: There are TWO config structs in `crates/shared/src/data/config.rs` — `Config` (server-side, 15+ fields with sections: ztp_server, configuration_management, tls, otel, scanner) and `ClientConfig` (client-side, 7 fields with server_connection). Compare both against `./docs/configuration/sherpa.md`.
- **OpenTelemetry**: Check `[otel]` config section and tracing instrumentation vs docs
- **Network link types**: Link impairment and P2P modes vs networking docs
- **ZTP methods**: Methods in code vs ZTP docs
- **Authentication/user management**: JWT auth, user CRUD operations vs docs

### 6. Stale Content Check

Look for:
- Incorrect paths or references in CLAUDE.md
- Node pages referencing old model names or deprecated parameters
- Empty or stub pages (files with < 5 lines of content)
- Pages commented out in mkdocs.yml nav
- SQL node doc filenames that diverge significantly from model names (e.g. `mongo.md` vs model `mongo_db`)

## Output Format

Present findings as a categorized report:

```
## Docs Review Report

### Critical (blocking/incorrect information)
- [item]: [description]

### Missing (features in code, not in docs)
- [item]: [description]

### Stale (outdated information)
- [item]: [description]

### Incomplete (partial coverage)
- [item]: [description]

### Navigation Issues
- [item]: [description]
```

For each finding, include:
- The specific file(s) in both repos
- What action is needed (create, update, or remove)
- Priority: P0 (incorrect info), P1 (missing critical feature), P2 (missing nice-to-have), P3 (polish)
