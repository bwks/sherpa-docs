# API Reference

Sherpa provides a unified API accessible via three transports. The API specification is auto-generated from the codebase and served as a live OpenAPI 3.1 document.

## Swagger UI

Sherpa ships with a built-in Swagger UI for interactive API exploration. Access it from any running Sherpa server at:

```
https://<server>:3030/api/docs
```

The Swagger UI lets you browse all available operations, inspect request/response schemas, and test endpoints directly from the browser. It is served from the Sherpa server itself, so it always reflects the exact API version running on that server.

## OpenAPI Specification

The raw OpenAPI 3.1 JSON specification is available at:

```
GET https://<server>:3030/api/v1/openapi.json
```

This can be imported into tools like Postman, Insomnia, or any OpenAPI-compatible client for generating API bindings or documentation.

## Transports

### REST API

Standard HTTP endpoints served on the configured `ws_port` (default: `3030`). Supports JSON request/response bodies and Server-Sent Events (SSE) for streaming operations.

### WebSocket RPC

JSON-RPC 2.0 over WebSocket at `wss://<server>:3030/ws`. This is the transport used by the `sherpa` CLI.

### CLI

The `sherpa` command-line tool wraps the WebSocket RPC transport. See the [Command Reference](command-reference.md) for all available commands.

## Authentication

All authenticated endpoints support two methods:

- **Bearer Token**: `Authorization: Bearer <jwt>` header
- **Cookie**: `sherpa_auth` cookie (used by the web UI)

Obtain a token via the login endpoint:

```bash
# CLI
sherpa login

# REST
curl -X POST https://<server>:3030/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password"}'
```

A wrong password, an unknown username and a login refused by the login limit all get the same
`401 Unauthorized` and message. See
[Login refused with the right password](help/troubleshooting.md#login-refused-with-the-right-password).

Check a token with the validate endpoint, the REST form of `sherpa whoami`. It answers
`"valid": false` for a token that is invalid or expired, or whose session has ended, rather than
an error:

```bash
curl -X POST https://<server>:3030/api/v1/auth/validate \
  -H "Content-Type: application/json" \
  -d '{"token": "<jwt>"}'
```

Each login starts a session on the server, and its token works only while the session lasts.
End it with the logout endpoint, the REST form of `sherpa logout`. The token stops working at
once; other sessions of the same user are not affected. `"ended": false` means the session had
already ended:

```bash
curl -X POST https://<server>:3030/api/v1/auth/logout \
  -H "Authorization: Bearer <jwt>"
```

A session also ends when:

- the user changes their password, for every session but the one used to change it;
- an admin resets the user's password, or deletes the user, for all of the user's sessions;
- it expires, 7 days after login (30 days for a web login with **Remember me**).

A request with a token whose session has ended gets `401 Unauthorized`.

A change to a user that races another change to the same user, such as two SSH key edits at
once, is refused with `409 Conflict` instead of overwriting the other change. Retry it.

## Tailscale Enrollment and Status

When the lab manifest enables `[tailscale]`, the authenticated lab-creation request
must supply `tailscale_auth_key` separately from the manifest. REST enrollment
requires HTTPS; WebSocket enrollment requires WSS. The CLI reads this value from
the client environment variable named by `tailscale.auth_key_env`. The server
validates that variable name but never resolves it from its own environment.

| Field | Direction | Description |
| ----- | --------- | ----------- |
| `tailscale_auth_key` | Creation and resume requests | Tailscale auth key. Creation: required when enabled, omitted when disabled. Resume: required to resume a whole lab with a gateway, omitted otherwise |
| `tailscale` | Creation, inspect, and full-resume responses | Optional gateway status with state, route approval, advertised routes, Tailscale addresses, and warnings |

Auth keys are used for enrollment and are not saved in manifests or database
records. Stopping a lab logs the gateway out, so resuming the whole lab enrolls it
again with the key from the resume request. Pending or unknown route approval is
reported as a warning; enrollment failure during creation triggers rollback.
Web UI enrollment is not supported, so the web UI cannot resume a whole lab with a
gateway.

See [Tailscale setup and recovery](architecture/networking/tailscale.md) and the
running server's Swagger UI for the request and response schemas.

Admin rights are read from the user database on every request, not from the token.
Demoting an admin removes their admin rights immediately, and deleting a user makes
their existing tokens stop working.

## Operation Categories

| Category | Operations | Auth Level |
| -------- | ---------- | ---------- |
| Auth | Login, validate token | None |
| Lab | List, create, destroy, inspect, down, resume, cancel, download | Authenticated |
| Node | Redeploy | Authenticated |
| Link | Update impairment | Authenticated |
| Image | List, show | Authenticated |
| Image | Import, pull, delete, set-default, scan, download, upload | Admin |
| User | Change password, info | Self, or admin for any user |
| User | Set device password | Self only, admins included |
| User | Add own SSH key | Self only, admins included |
| User | Create, list, delete | Admin |
| Admin | Force clean lab | Admin |
| Admin | Back up database | Admin |

To change your own password, admins included, send `current_password` with `new_password`
(`POST /api/v1/admin/users/{username}/password`, or the RPC method `user.passwd`). An admin
resetting another user's password leaves it out.

To set your own [device password](architecture/device-password.md), send `username` (your own),
`login_password` and `device_password` (`POST /api/v1/admin/users/{username}/device-password`,
or the RPC method `user.device_password.set`). The answer is `username` and
`device_password_set`. Another user's, an admin's call included, is refused (403, or
`AccessDenied`), and so is a wrong login password; a password that breaks the
[rules](architecture/device-password.md#rules) or equals the login password is invalid (400, or
`InvalidParams`). User details (`user.info`, `user.list` and their REST routes) carry
`device_password_set`, never the password.

The server sends no CORS headers, so a web page on another origin cannot call the API.

The database backup is WebSocket RPC only: the method `server.backup` takes only `token` and
returns `path`, the backup file on the server, and `size_bytes`. See
[`sherpa server backup`](command-reference.md#sherpa-server-backup).

## Node images

Showing an image (`GET /api/v1/images/{model}/{kind}`, the WebSocket RPC method `image.show`, or
`sherpa server --output json image show <model>`) returns its definition: the settings every kind
of image takes, `kind`, and one group of settings for that kind alone, named as the manifest
names the kind groups: `vm`, `container` or `unikernel`. For `ubuntu_linux`:

```json
{
  "image": {
    "model": "ubuntu_linux",
    "version": "24.04",
    "kind": "virtual_machine",
    "default": true,
    "memory": 1024,
    "cpu": {
      "count": 1
    },
    "interfaces": {
      "data_count": 1,
      "management": "eth0",
      "reserved_count": 0
    },
    "vm": {
      "os_variant": "linux",
      "cpu": {
        "architecture": "x86_64",
        "model": "host-model",
        "vmx": false
      },
      "machine": {
        "kind": "q35",
        "bios": "sea_bios"
      },
      "boot_disk": {
        "bus": "virtio"
      },
      "cdrom": {
        "image": null,
        "bus": "sata"
      },
      "interfaces": {
        "kind": "virtio",
        "mtu": 9216
      },
      "ztp": {
        "method": "cloud-init"
      }
    }
  }
}
```

A container image, `nokia_srlinux`:

```json
{
  "image": {
    "model": "nokia_srlinux",
    "version": "25.3.2",
    "kind": "container",
    "default": true,
    "memory": 4096,
    "cpu": {
      "count": 2
    },
    "interfaces": {
      "data_count": 34,
      "management": "mgmt0",
      "reserved_count": 0
    },
    "container": {
      "repo": "ghcr.io/nokia/srlinux",
      "ztp": {
        "method": "volume"
      }
    }
  }
}
```

A unikernel image, `nanos_unikernel`:

```json
{
  "image": {
    "model": "nanos_unikernel",
    "version": "0.1.52",
    "kind": "unikernel",
    "default": true,
    "memory": 512,
    "cpu": {
      "count": 1
    },
    "interfaces": {
      "data_count": 0,
      "management": "eth0",
      "reserved_count": 0
    },
    "unikernel": {
      "boot_mode": "disk_boot",
      "cpu": {
        "architecture": "x86_64",
        "model": "host-model"
      },
      "machine": {
        "kind": "pc"
      },
      "interfaces": {
        "kind": "virtio",
        "mtu": 1500
      }
    }
  }
}
```

| Field | Kinds | Description |
| ----- | ----- | ----------- |
| `model`, `version`, `kind`, `default` | all | The image |
| `memory` | all | Memory in MiB |
| `cpu` | all | `count` |
| `interfaces` | all | `data_count`, `management` and `reserved_count` |
| `vm` | virtual machine | `os_variant`; `cpu`: `architecture`, `model` and `vmx`, whether the guest sees the host's hardware virtualisation; `machine`: `kind`, the QEMU machine type, and `bios`; `boot_disk`: `bus`; `cdrom`: `image`, a CD-ROM file shipped with the image or `null`, and `bus`; `interfaces`: `kind`, the interface device, and `mtu`; `ztp`: `method`, the [ZTP setting](architecture/zero-touch-provisioning.md#the-ztp-setting) |
| `container` | container | `repo`, the Docker repo the image runs from, its tag being `version`, or `null`; `ztp`: `method` |
| `unikernel` | unikernel | `boot_mode`; `cpu`: `architecture` and `model`; `machine`: `kind`; `interfaces`: `kind` and `mtu` |

An image holds only its own kind's group. Reading one, the server refuses a group that is not
its kind's and an image without its kind's group, naming the group. A container has no CPU,
machine, disk, CD-ROM or interface device settings: Docker makes its interfaces. A unikernel has
no firmware, disks, CD-ROM, `vmx`, `os_variant` or ZTP setting.

The OpenAPI schema describes the same shape.

An `image.import` that sends a field it does not take is refused with an error naming the field.

### The image's kind

An image is a model, a kind and a version. The RPC requests that name one image, `image.show`,
`image.import`, `image.delete`, `image.set_default`, `image.pull` and `image.download`, and the
JSON bodies of `POST /api/v1/images/import`, `pull` and `download`, take an optional `kind`:
`virtual_machine`, `container` or `unikernel`. Without it, the request is for the model's
default kind. `generic` has no default kind, so a request for a `generic` image must set
`kind`. A kind the model does not take is refused as invalid (400, or `InvalidParams`), naming
the kinds it takes. `image.pull` also refuses a kind other than `container`. For the container
images of `arista_eos` and `juniper_evolved`, which default to the virtual machine, set
`kind` to `container`.

The REST paths that name one image carry the kind:

| Method | Path | |
| ------ | ---- | - |
| `GET` | `/api/v1/images/{model}/{kind}` | Show the image; `?version=` picks a version, else the default |
| `DELETE` | `/api/v1/images/{model}/{kind}/{version}` | Delete the image |
| `POST` | `/api/v1/images/{model}/{kind}/{version}/default` | Make the version the default |

`{kind}` is `virtual_machine`, `container` or `unikernel`; an unknown model or kind, or a kind
the model does not take, is a bad request (400). The multipart form of
`POST /api/v1/images/upload` takes a `kind` field; without it, or empty, the model's default
kind.

The web UI's image pages are under `/admin/images/{model}/{kind}/`, and its image list has one
row per model and kind. The upload form and the lab-create page offer a kind for a model that
takes several.

An image's page, and the node page's image settings, show the settings every kind takes and the
image's own kind's. Its editor takes the same: CPU count, memory and interface counts for every
kind; the OS, CPU, machine, firmware, disk, CD-ROM, interface device and ZTP settings for a
virtual machine; the repo and ZTP setting for a container; the CPU, machine and interface device
settings for a unikernel, whose boot mode is kept. A form that sends a setting the image's kind
does not take is refused, naming it.

### Deleting an image

`image.delete` and `DELETE /api/v1/images/{model}/{kind}/{version}` delete the image's record,
then the image itself, and answer with `model`, `kind`, `version`, `db_deleted`,
`image_deleted` and `new_default`. `image_deleted` says whether the image itself was deleted: a
virtual machine's or unikernel's file, with its version folder once no other kind's file is
left in it, or a container's Docker image, its `repo` at its
`version`. Another tag of the same Docker image, such as the one it was pulled as, is kept.

The delete is refused as a conflict (409, or `Conflict`), naming what holds the image:

- a virtual machine or unikernel image while a disk of the storage pool is built on it, whether
  its VM is running or stopped;
- a container image while a running container runs it.

A disk built on another image does not block the delete. An image a node of a lab records is not
deleted either: destroy the lab, or redeploy the node onto another version, first.

## Errors

REST errors return a JSON body with an HTTP status:

```json
{ "error": { "code": "NOT_FOUND", "message": "...", "details": "...", "data": { } } }
```

`details` and `data` are present only when they apply. WebSocket RPC errors are JSON-RPC 2.0
error objects, with `code`, `message`, and `data` where the code defines it.

| Meaning | REST status, `code` | WebSocket RPC `code` |
| ------- | ------------------- | -------------------- |
| Invalid request | `400`, `BAD_REQUEST` | `-32602` |
| Not logged in, or the token expired | `401`, `UNAUTHORIZED` | `-32002` |
| Not allowed | `403`, `FORBIDDEN` | `-32003` |
| Does not exist | `404`, `NOT_FOUND` | `-32004` |
| The current state forbids it | `409`, `CONFLICT` | `-32000` |
| Not enough host memory | `507`, `INSUFFICIENT_MEMORY` | `-32005` |
| Host CPUs pinned by another node | `409`, `CPU_PINS_HELD` | `-32006` |
| Any other failure | `500`, `INTERNAL_ERROR` | `-32000` |

### A request that does not parse

A REST body, form or query string that is not of the request's type, such as
a missing field, a field the request does not take, a JSON key sent twice, or a value of the
wrong type or out of range, returns `400`, `BAD_REQUEST`, `Invalid request`. Its `details` are
`the request is not valid at <path>`, with the path of the field that is wrong, such as
`password`, `extra`, `port` or `files[0].mode`, and never the value sent:

```json
{ "error": { "code": "BAD_REQUEST", "message": "Invalid request", "details": "the request is not valid at nodes[0].model" } }
```

The `details` are `the request is not valid`, with no path, when a top-level field is missing or
when the path holds a name sent that is not plain letters, digits, `_` and `-`. They say nothing
else about what is wrong.

A path parameter that is not of its type, such as a link index that is not a number, returns
`400` with a plain-text message that can quote the value, which is part of the URL.

A JSON body that is not valid JSON, or that is sent without `Content-Type: application/json`, a
form sent without `Content-Type: application/x-www-form-urlencoded`, and a body that cannot be
read also return `400` with the JSON error object, and their `details` say only that. WebSocket
RPC parameters that do not parse return `-32602` (`InvalidParams`) with the same text in the
error's context.

### Not enough host memory

Creating a lab, redeploying a node or resuming nodes is refused when the virtual machines,
unikernels and memory-limited containers it would start do not fit in the server's memory now (see
[host memory](configuration/sherpa.md#host_memory)). Nothing is started, and the same request
can succeed once other nodes are stopped or destroyed. The error's `data` says by how much:

```json
{ "requested_mib": 16384, "available_mib": 11614, "numa_node": null }
```

| Field | Description |
| ----- | ----------- |
| `requested_mib` | Memory the refused nodes need, in MiB |
| `available_mib` | Guest memory left for them, in MiB |
| `numa_node` | The NUMA node that is short, for nodes held strictly to one; `null` when the whole server is |

Lab creation and redeploy stream their progress over REST, so their HTTP status is sent before
they can fail: the stream's `error` event carries the refusal as
`{"error": "...", "code": "INSUFFICIENT_MEMORY", "data": {...}}`. The CLI exits with status `75`
(see [exit status](command-reference.md#exit-status)).

### CPU pins held

Creating a lab or redeploying a node is refused when a host CPU one of its virtual machines
pins is held by another node: stored in another lab, or being started by another operation
(see [CPU pins held](manifest.md#cpu-pins-held)). Nothing is started, and the same request can
succeed once that node is destroyed or redeployed on other CPUs. The error's `data` says which
CPUs, and what each side pins to them:

```json
{ "host_cpus": [2, 3], "requested_role": "vcpu", "held_role": "vcpu" }
```

| Field | Description |
| ----- | ----------- |
| `host_cpus` | The host CPUs in conflict, in ascending order |
| `requested_role` | What the refused node would pin to them: `vcpu`, or `thread` for QEMU emulator and disk I/O threads |
| `held_role` | What the holding node pins to them: `vcpu` or `thread` |

The `message` names the holding node and its lab to admins and to that lab's owner, and says
"a node of another lab" to everyone else; `data` never names them. The REST status is `409`
with its own `code`, `CPU_PINS_HELD`, so it can be told from other conflicts. As with the
memory refusal, the stream's `error` event of lab creation and redeploy carries
`"code": "CPU_PINS_HELD"` and the `data`, and the CLI exits with status `75`.

## Long-Running Operations

Lab creation, destroy, redeploy, resume, down, admin clean and image operations run on the
server as their own tasks. They keep running when the client that started them disconnects,
on every transport, and are never stopped partway through a step.

To stop a running `up`, `redeploy` or `resume`, call **cancel** for the lab
(`POST /api/v1/labs/{id}/cancel`, or the WebSocket RPC method `cancel` with `lab_id`). The
server stops the operation at its next safe point and responds once it has ended:

```json
{ "lab_id": "a1b2c3d4", "stopped": true }
```

`stopped` is `false` if nothing was running. A cancelled `up` removes what it had created. The
CLI calls cancel when you answer yes after pressing Ctrl-C. Destroying a lab also stops any of
these operations first.

## Lab Phases

A lab's list entry has `status`, derived from its nodes, and `phase`, which operation owns the
lab: `creating`, `ready`, `destroying`, `destroy_failed`, `interrupted` or `unknown` (see
[lab phases](command-reference.md#lab-phases)). `unknown` is a phase this version does not know,
such as one written by a newer server. Inspect returns them as `lab_state` and `lab_phase`.

- Creating a lab whose ID is in use, by an existing lab or one being created, fails before
  anything is created, with an error that says the lab already exists.
- Down, resume and redeploy refuse a lab that is not `ready`, with an error that says what to do
  (`409 Conflict` where the REST response is not a progress stream).
- The creation response's `success` is `false` when any error has `is_critical`: a container that
  exited, or a Kubernetes cluster, Vault or Keycloak that did not come up. The lab is created
  either way. Errors without `is_critical` are warnings, such as a node slow to become ready.

## Link Impairment

Change the impairment on a running P2P link with
`POST /api/v1/labs/{lab_id}/links/{link_index}/impairment`, or the WebSocket RPC method
`link.update_impairment`. `link_index` is the link's position in the manifest's `[[links]]`,
starting at `0`, and is the `index` of the link in the inspect response's `links[]`.

```json
{
  "lab_id": "a1b2c3d4",
  "link_index": 0,
  "direction": "src_to_dst",
  "delay": 20,
  "jitter": 2,
  "loss_percent": 1.0,
  "reorder_percent": 0.0,
  "corrupt_percent": 0.0
}
```

| Field | Description |
| ----- | ----------- |
| `direction` | `src_to_dst` (traffic from the link's `src` to its `dst`), `dst_to_src`, or `both`. Defaults to `both`. |
| `delay` | One-way delay in milliseconds, up to `274877` |
| `jitter` | Delay jitter in milliseconds, up to `274877` |
| `loss_percent` | Packet loss percentage (`0.0` - `100.0`) |
| `reorder_percent` | Packet reordering percentage (`0.0` - `100.0`). Reordered packets skip the delay, so it needs a `delay`. |
| `corrupt_percent` | Bit-flip corruption percentage (`0.0` - `100.0`) |

The values replace the impairment on the directions named; the other direction keeps its own.
Omitted values are `0`, and all zeros remove the impairment from those directions. The change
applies at once and is kept across `down`/`resume` and redeploying either end.

An unknown `direction`, or a number out of range for its field, does not parse: it returns
`400 Bad Request` on REST and `InvalidParams` on WebSocket RPC, with the field's path (see
[A request that does not parse](#a-request-that-does-not-parse)). A delay or jitter
over `274877` ms (the longest netem holds) or a percentage outside `0` - `100` returns
`400 Bad Request` and `InvalidParams`. When `direction` is `both` and the second direction
cannot be changed, the first is put back, so the link is never left half changed. If the change
cannot be recorded, the changed directions are put back, and the request fails with the old
impairment in place. Clearing a direction fails if its impairment cannot be removed; only a
direction with none counts as already clear.

## Link States After Resume And Redeploy

A node that resume boots, and a redeployed node, get new link ends, and the server attaches their
links again. Each resume result (`results[]`) and the redeploy response carry `links`, the state
of each of that node's links, when there are any; the field is absent otherwise.

```json
{
  "name": "vm1",
  "success": true,
  "message": "Started and ready",
  "links": [
    { "link": "vm1::eth1 <-> vm2::eth1", "state": "peer_down", "peer": "vm2" },
    { "link": "vm1::eth2 <-> ctr1::eth1", "state": "attached" },
    { "link": "vm1::eth3 <-> uk1::eth1", "state": "failed", "reason": "..." }
  ]
}
```

| `state` | Meaning |
| ------- | ------- |
| `attached` | Both ends redirect to each other, with the link's impairments |
| `peer_down` | The peer (`peer`) is down, and the other end has no carrier. The link is attached in both directions, with carrier, when it starts |
| `failed` | The link could not be attached (`reason`). It carries no traffic, and neither end has carrier, until it is attached again: by the next scan, or by resuming or redeploying either end |

A link that is not attached does not make the node's `success` false.

### Link state in inspect

The inspect response's `links[]` carry `state`, the link's last state as the server found or
left it, in the same form: from the server's scan of the lab every `scanner.interval_secs`, or
from the last resume or redeploy. The field is absent while the server has not checked the
link since it started. `index` is the link's
`link_index` for [Link Impairment](#link-impairment).

```json
{
  "node_a_name": "vm1",
  "int_a": "eth1",
  "node_b_name": "ctr1",
  "int_b": "eth1",
  "kind": "p2p",
  "state": { "state": "peer_down", "peer": "ctr1" },
  "index": 0
}
```

### Serial console

```
GET /api/v1/labs/{lab_id}/nodes/{node_name}/console
```

Upgrades to a WebSocket that relays the serial console of a virtual machine or unikernel node.
This is what `sherpa console` uses. See [Serial Console](architecture/console.md).

- **Auth**: `Authorization: Bearer <token>` only. The `sherpa_auth` cookie is not accepted.
- **Access**: the lab's owner only. Admins are refused.
- **Query**: `force=true` takes the console over from a session of the caller's own. It never
  takes over another user's session.
- **Frames**: raw serial bytes in binary frames, both ways. Text
  frames are ignored.

The errors come as HTTP statuses before the upgrade:

| Status | Message |
| ------ | ------- |
| `401` | The token is missing, invalid or expired |
| `403` | `Access denied: only the owner of lab '<lab-id>' can open its consoles` |
| `404` | The lab or the node was not found |
| `400` | `<node> is a container, and containers have no serial console. Connect with 'sherpa ssh <node>' instead.` |
| `409` | `Node '<node>' is not running. Start it with 'sherpa resume'.` |
| `409` | `The console of <node> is in use by <user> from <client-ip> since <YYYY-MM-DD HH:MM:SS> UTC. Close that session, or take it over with 'sherpa console <node> --force'.` |

With `check=true` (`GET .../console?check=true`), the route only checks: it needs no WebSocket
upgrade and makes none, and takes no session. It refuses with the errors above, except that a
console in use is not refused, and otherwise answers `200`:

```json
{ "held_by": "<user> from <client-ip> since <YYYY-MM-DD HH:MM:SS> UTC" }
```

`held_by` is `null` when no session holds the console. `sherpa vnc` checks the VNC console this
way before it opens its local port.

### VNC console

```
GET /api/v1/labs/{lab_id}/nodes/{node_name}/vnc
```

Upgrades to a WebSocket that relays the VNC console of a virtual machine node. This is what
`sherpa vnc` uses. See [VNC](architecture/vnc.md).

- **Auth**, **Access** and **Query** (`force=true`, `check=true`): as for the serial console. A
  node's VNC and serial consoles are held apart: one session each.
- **Frames**: the RFB protocol of the node's VNC server, as QEMU speaks it, in binary frames both
  ways. Text frames are ignored. The server's VNC asks for no password.

The errors are those of the serial console, with these differences:

| Status | Message |
| ------ | ------- |
| `400` | `<node> is a container, and containers have no VNC console. Connect with 'sherpa ssh <node>' instead.` |
| `400` | `<node> is a unikernel, and unikernels have no VNC console. Use 'sherpa console <node>' instead.` |
| `409` | `The VNC console of <node> is in use by <user> from <client-ip> since <YYYY-MM-DD HH:MM:SS> UTC. Close that session, or take it over with 'sherpa vnc <node> --force'.` |

A session ends with the serial console's close frames, except that `1000` says `The node's VNC
console closed the connection.`: the node's VNC server closed it, for example as the node
stopped.

A session ends with a close frame:

| Code | Meaning |
| ---- | ------- |
| `1000` | The node's console closed: the node stopped |
| `4001` | Another session took it over; the reason names the user, address and time |
| `4002` | The login session behind the token ended. Checked every 30 seconds |
| `1011` | The relay failed |

The inspect response's `devices[]` carry no console address and no VNC port.

## Lab Access

Every lab operation applies the same rule on REST, WebSocket RPC and the web UI:

| Operation | Who may perform it |
| --------- | ------------------ |
| Create | Any authenticated user; the lab is owned by the caller |
| List | The caller's own labs. Admins may list another user's labs with `GET /api/v1/labs?username=<user>` |
| Inspect, destroy, down, resume, cancel, update link impairment | The lab owner or an admin |
| Open a node's serial or VNC console | The lab owner only, including for admins |
| Download (RPC `download`; the web UI's lab download) | The lab owner only, including for admins |
| Refresh a node's host key (RPC `node.host_keys`) | The lab owner only, including for admins |
| Redeploy a node | The lab owner only, including for admins, because the node is rebuilt with the owner's SSH keys and account |
| Force clean | Admins only |

The built-in `admin` account cannot create, resume or redeploy labs, on any transport: these
return `403 Forbidden` on REST and `AccessDenied` on WebSocket RPC. It can still inspect, stop,
destroy and clean up any lab. Start labs from your own account, which may also be an admin. Labs also need the account to have a [device password](architecture/device-password.md).

Downloads hold the SSH config, `known_hosts`, the Talos cluster credentials, the Vault,
Keycloak and SurrealDB credentials and the lab CA, which a lab's owner needs to log in to its nodes, so an
admin is refused them with `Only the owner of lab '<id>' can perform this operation`. Likewise
a node's serial and VNC consoles reach it without its login, so an admin is refused both.
Admins keep
everything else: listing, inspect, down, resume, cancel, link impairment, destroy and clean.
The server logs a warning (`auth.admin_lab_access`) each time an admin acts on another user's
lab, and each refusal (`auth.access_denied`).

A request for another user's lab returns `403 Forbidden` on REST and an `AccessDenied`
error on WebSocket RPC. A lab that does not exist returns `404 Not Found` or `NotFound`.

## SSH Keys

Users add their own SSH public keys. Admins can list and remove anyone's, but cannot add one to
another account:

| Operation | REST | WebSocket RPC |
| --------- | ---- | ------------- |
| Add a key | `POST /api/v1/admin/users/{username}/ssh-keys` | `user.ssh_key.add` |
| Remove a key | `DELETE /api/v1/admin/users/{username}/ssh-keys` | `user.ssh_key.remove` |
| List keys | `GET /api/v1/admin/users/{username}` (`ssh_keys`) | `user.info` |

Adding a key is for the caller's own account only, admins included: a `username` other than the
caller's is refused with `only user '<name>' can do this for their own account`, `403 Forbidden`
on REST. Removing a key is allowed for the user or an admin. The request body carries
`username`, `ssh_key` and `token`. For removal, `ssh_key` may be the
key or its `SHA256:` fingerprint. Both return the user's keys after the change. A duplicate key
returns `409 Conflict`, an invalid key `400 Bad Request`, another user's keys `403 Forbidden`,
and a key that is not registered `404 Not Found`.

Creating a lab or redeploying a node fails until the caller has at least one registered key.

## User Creation

`user.create` (RPC) and `POST /api/v1/admin/users` (REST) take a username, a password and the
admin flag, and no `ssh_keys`. Both refuse unknown fields, `ssh_keys` included. Each user adds their own keys
afterwards; see [SSH Keys](#ssh-keys).

## Usernames

Creating a user on any transport applies the same username rules as
[`sherpa server user create`](command-reference.md#sherpa-server-user-create): 3–32 letters,
digits, underscores or hyphens, starting with a letter or underscore, and not a reserved name.
Usernames are saved in lower case and matched without regard to case, so logging in as `BRAD`
finds `brad`. An invalid username returns `400 Bad Request` on REST.

## User Deletion

Deleting a user follows the same rules on REST, WebSocket RPC and the web UI:

| Refusal | REST | WebSocket RPC |
| ------- | ---- | ------------- |
| Deleting your own account | `403 Forbidden` | `AccessDenied` |
| Deleting the built-in `admin` account | `403 Forbidden` | `AccessDenied` |
| Deleting the last admin account | `403 Forbidden` | `AccessDenied` |
| The user owns labs | `409 Conflict`, listing the labs | `ServerError`, listing the labs |

Destroy the user's labs first, then delete the user. The web UI shows the same messages
on the users page.

`GET /api/v1/labs` requires authentication. Without `?username=` it lists the
caller's labs.

The caller's identity always comes from their token. A `username` field in a request body is ignored.
