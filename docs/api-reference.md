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
| User | Create, list, delete | Admin |
| Admin | Force clean lab | Admin |
| Admin | Back up database | Admin |

To change your own password, admins included, send `current_password` with `new_password`
(`POST /api/v1/admin/users/{username}/password`, or the RPC method `user.passwd`). An admin
resetting another user's password leaves it out.

The server sends no CORS headers, so a web page on another origin cannot call the API.

The database backup is WebSocket RPC only: the method `server.backup` takes only `token` and
returns `path`, the backup file on the server, and `size_bytes`. See
[`sherpa server backup`](command-reference.md#sherpa-server-backup).

## Node images

Showing an image (`GET /api/v1/images/{model}`, the WebSocket RPC method `image.show`, or
`sherpa server --output json image show <model>`) returns its definition, with its settings
nested by group. For `ubuntu_linux`:

```json
{
  "image": {
    "model": "ubuntu_linux",
    "version": "24.04",
    "repo": null,
    "os_variant": "linux",
    "kind": "virtual_machine",
    "default": true,
    "memory": 1024,
    "cpu": {
      "count": 1,
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
      "data_count": 1,
      "kind": "virtio",
      "mtu": 9216,
      "prefix": "eth",
      "first_index": 0,
      "management": "eth0",
      "reserved_count": 0
    },
    "ztp": {
      "method": "cloud-init",
      "username": null,
      "password": null,
      "password_auth": false
    },
    "unikernel": null
  }
}
```

| Field | Description |
| ----- | ----------- |
| `model`, `version`, `repo`, `os_variant`, `kind`, `default` | The image |
| `memory` | Memory in MiB |
| `cpu` | `count`, `architecture`, `model` and `vmx`, whether the guest sees the host's hardware virtualisation |
| `machine` | `kind`, the QEMU machine type, and `bios` |
| `boot_disk` | `bus` |
| `cdrom` | `image`, a CD-ROM file shipped with the image or `null`, and `bus` |
| `interfaces` | `data_count`, `kind`, `mtu`, `prefix`, `first_index`, `management` and `reserved_count` |
| `ztp` | `method` (the [ZTP setting](architecture/zero-touch-provisioning.md#the-ztp-setting)), `username`, `password` and `password_auth` |
| `unikernel` | `boot_mode` for a unikernel; `null` for every other kind |

Every image carries every group, but not every kind uses them. A container does not use
`machine`, `boot_disk` or `cdrom`. A unikernel uses `machine.kind` and not `machine.bios`,
`boot_disk` or `cdrom`. Their images carry the defaults there: `pc`, `sea_bios`, `virtio`, a
`null` CD-ROM image and `virtio`. Images stored by releases up to 0.6.0 could hold other values,
such as a `q35` machine on `arista_ceos`; the update resets them. The `image show` tables and
the web UI's image and node pages leave these settings out; the JSON keeps them.

Releases up to 0.5.35 returned these settings as flat fields. Each moved into its group:

| Old field | New field |
| --------- | --------- |
| `cpu_count` | `cpu.count` |
| `cpu_architecture` | `cpu.architecture` |
| `cpu_model` | `cpu.model` |
| `vmx_enabled` | `cpu.vmx` |
| `machine_type` | `machine.kind` |
| `bios` | `machine.bios` |
| `hdd_bus` | `boot_disk.bus` |
| `cdrom` | `cdrom.image` |
| `cdrom_bus` | `cdrom.bus` |
| `data_interface_count` | `interfaces.data_count` |
| `interface_type` | `interfaces.kind` |
| `interface_mtu` | `interfaces.mtu` |
| `interface_prefix` | `interfaces.prefix` |
| `first_interface_index` | `interfaces.first_index` |
| `management_interface` | `interfaces.management` |
| `reserved_interface_count` | `interfaces.reserved_count` |
| `ztp` | `ztp.method` |
| `ztp_username` | `ztp.username` |
| `ztp_password` | `ztp.password` |
| `ztp_password_auth` | `ztp.password_auth` |
| `boot_mode` | `unikernel.boot_mode` |

`memory`, `model`, `version`, `repo`, `os_variant`, `kind` and `default` are unchanged. The
OpenAPI schema describes the same shape.

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
| Any other failure | `500`, `INTERNAL_ERROR` | `-32000` |

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
lab: `creating`, `ready`, `destroying`, `destroy_failed` or `interrupted` (see
[lab phases](command-reference.md#lab-phases)). Inspect returns them as `lab_state` and
`lab_phase`. A server before 0.5.27 sends no phase; read its labs as `ready`.

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
starting at `0`.

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

An unknown `direction`, or a number out of range for its field, returns
`422 Unprocessable Entity` on REST and `InvalidParams` on WebSocket RPC. A delay or jitter
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
| `peer_down` | The peer (`peer`) is down. The link is attached in both directions when it starts |
| `failed` | The link could not be attached (`reason`). It carries no traffic until either end is resumed or redeployed |

A link that is not attached does not make the node's `success` false.

## Lab Access

Every lab operation applies the same rule on REST, WebSocket RPC and the web UI:

| Operation | Who may perform it |
| --------- | ------------------ |
| Create | Any authenticated user; the lab is owned by the caller |
| List | The caller's own labs. Admins may list another user's labs with `GET /api/v1/labs?username=<user>` |
| Inspect, destroy, down, resume, cancel, download, update link impairment | The lab owner or an admin |
| Redeploy a node | The lab owner only, including for admins, because the node is rebuilt with the owner's SSH keys and account |
| Force clean | Admins only |

The built-in `admin` account cannot create, resume or redeploy labs, on any transport: these
return `403 Forbidden` on REST and `AccessDenied` on WebSocket RPC. It can still inspect, stop,
destroy and clean up any lab. Start labs from a personal account, which may also be an admin.

A request for another user's lab returns `403 Forbidden` on REST and an `AccessDenied`
error on WebSocket RPC. A lab that does not exist returns `404 Not Found` or `NotFound`.

## SSH Keys

Users manage their own SSH public keys, and admins may manage anyone's:

| Operation | REST | WebSocket RPC |
| --------- | ---- | ------------- |
| Add a key | `POST /api/v1/admin/users/{username}/ssh-keys` | `user.ssh_key.add` |
| Remove a key | `DELETE /api/v1/admin/users/{username}/ssh-keys` | `user.ssh_key.remove` |
| List keys | `GET /api/v1/admin/users/{username}` (`ssh_keys`) | `user.info` |

The request body carries `username`, `ssh_key` and `token`. For removal, `ssh_key` may be the
key or its `SHA256:` fingerprint. Both return the user's keys after the change. A duplicate key
returns `409 Conflict`, an invalid key `400 Bad Request`, another user's keys `403 Forbidden`,
and a key that is not registered `404 Not Found`.

Creating a lab or redeploying a node fails until the caller has at least one registered key.

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

The caller's identity always comes from their token. Request bodies do not carry a
`username` field, and one sent by an older client is ignored.
