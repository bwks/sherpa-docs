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
- **Cookie**: `sherpa_token` cookie (used by the web UI)

Obtain a token via the login endpoint:

```bash
# CLI
sherpa login

# REST
curl -X POST https://<server>:3030/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password"}'
```

## Tailscale Enrollment and Status

When the lab manifest enables `[tailscale]`, the authenticated lab-creation request
must supply `tailscale_auth_key` separately from the manifest. REST enrollment
requires HTTPS; WebSocket enrollment requires WSS. The CLI reads this value from
the client environment variable named by `tailscale.auth_key_env`. The server
validates that variable name but never resolves it from its own environment.

| Field | Direction | Description |
| ----- | --------- | ----------- |
| `tailscale_auth_key` | Creation request | Tailscale auth key; required when enabled and omitted when disabled |
| `tailscale` | Creation, inspect, and full-resume responses | Optional gateway status with state, route approval, advertised routes, Tailscale addresses, and warnings |

Auth keys are used only for initial enrollment and are not saved in manifests or
database records. Stop and resume retain the gateway identity. Pending or unknown
route approval is reported as a warning; enrollment failure triggers rollback.
Web UI enrollment is not supported in this version.

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
