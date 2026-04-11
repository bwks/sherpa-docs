# API Reference

Sherpa provides a unified API accessible via three transports. The API specification is auto-generated from the codebase and served as a live OpenAPI 3.1 document.

## Live API Specification

The full OpenAPI spec is available from any running Sherpa server:

```
GET https://<server>:3031/api/v1/spec
```

This endpoint returns the complete specification including all operations, request/response schemas, and authentication requirements.

## Transports

### REST API

Standard HTTP endpoints served on the configured `http_port` (default: `3031`). Supports JSON request/response bodies and Server-Sent Events (SSE) for streaming operations.

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
curl -X POST https://<server>:3031/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password"}'
```

## Operation Categories

| Category | Operations | Auth Level |
| -------- | ---------- | ---------- |
| Auth | Login, validate token | None |
| Lab | Create, destroy, inspect, down, resume | Authenticated |
| Node | Redeploy | Authenticated |
| Link | Update impairment | Authenticated |
| Image | List, show, import, pull, delete, set-default, scan, download, upload | Admin |
| User | Create, list, delete, change password, info | Admin |
| Admin | Force clean lab | Admin |
