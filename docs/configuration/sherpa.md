# Configuration

Sherpa uses TOML configuration files for both the server and client.

## Server Configuration

The server configuration file is located at `/opt/sherpa/config/sherpa.toml`.

### Example

```toml
name = "sherpa-server"
server_ipv4 = "10.0.0.1"
ws_port = 3030
http_port = 3031
vm_provider = "libvirt"
qemu_bin = "/usr/bin/qemu-system-x86_64"
management_prefix_ipv4 = "172.31.0.0/16"
images_dir = "/opt/sherpa/images"
containers_dir = "/opt/sherpa/containers"
bins_dir = "/opt/sherpa/bins"

[ztp_server]
enable = true
username = "sherpa"
password = "sherpa"

[configuration_management]
ansible = false
pyats = false
nornir = false

[tls]
enabled = true
auto_generate_cert = true
cert_validity_days = 365

[otel]
enabled = false

[scanner]
enabled = true
interval_secs = 30

[tailscale]
image = "tailscale/tailscale:v1.102.3"
socket_path = "/run/tailscale/tailscaled.sock"
exec_timeout_secs = 75
daemon_ready_timeout_secs = 20
enrollment_timeout_secs = 60
connection_timeout_secs = 30
stop_timeout_secs = 10
```

### Base Fields

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `name` | string | | Server name (required) |
| `server_ipv4` | string | `127.0.0.1` | Server IPv4 address |
| `server_ipv6` | string | | Server IPv6 address |
| `ws_port` | int | `3030` | WebSocket port |
| `http_port` | int | `3031` | HTTP port |
| `vm_provider` | string | | VM provider — `"libvirt"` (required) |
| `qemu_bin` | string | | Path to QEMU binary (required) |
| `management_prefix_ipv4` | string | `172.31.0.0/16` | Management network IPv4 CIDR |
| `management_prefix_ipv6` | string | `fd00:b00b::/48` when unset | Management network IPv6 CIDR. See [IP Addressing](../architecture/networking/ip-addressing.md) |
| `images_dir` | string | | Directory for VM/unikernel images (required) |
| `containers_dir` | string | | Directory for container images (required) |
| `bins_dir` | string | | Directory for binary files (required) |

### `[ztp_server]`

Zero-Touch Provisioning server settings.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `enable` | bool | `true` | Enable or disable the ZTP server |
| `username` | string | `"sherpa"` | ZTP authentication username |
| `password` | string | `"Everest1953!"` | ZTP authentication password |

### `[configuration_management]`

Configuration management tool integrations. When enabled, Sherpa generates inventory files.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `ansible` | bool | `false` | Generate Ansible inventory |
| `pyats` | bool | `false` | Generate pyATS testbed |
| `nornir` | bool | `false` | Generate Nornir inventory |

### `[server_connection]`

Internal server connection settings.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `url` | string | | WebSocket URL override |
| `timeout_secs` | int | `3` | Connection timeout in seconds |
| `validate_certs` | bool | `true` | Validate server TLS certificates |
| `ca_cert_path` | string | | Path to custom CA certificate for self-signed certs |
| `insecure` | bool | `false` | Skip certificate validation (development only) |

### `[tls]`

TLS configuration for the server.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `enabled` | bool | `true` | Enable TLS for connections |
| `cert_path` | string | `/opt/sherpa/.certs/server.crt` | Path to server certificate (PEM) |
| `key_path` | string | `/opt/sherpa/.certs/server.key` | Path to server private key (PEM) |
| `auto_generate_cert` | bool | `true` | Auto-generate self-signed certificate if none exists |
| `cert_validity_days` | int | `365` | Certificate validity in days (for auto-generated certs) |
| `san` | list&lt;string&gt; | `[]` | Subject Alternative Names (DNS names, IPs) |

### `[otel]`

OpenTelemetry observability configuration. When enabled, Sherpa exports distributed traces via OTLP.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `enabled` | bool | `false` | Enable OpenTelemetry trace export |
| `endpoint` | string | `http://localhost:4317` | OTLP collector endpoint |
| `protocol` | string | `grpc` | OTLP transport protocol (`grpc` or `http`) |
| `service_name` | string | `sherpad` | Service name reported to the collector |
| `sample_ratio` | float | `1.0` | Trace sampling ratio (`0.0` - `1.0`) |

### `[scanner]`

Background scanner service configuration for periodic image discovery.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `enabled` | bool | `true` | Enable the background scanner service |
| `interval_secs` | int | `30` | Interval between scan cycles in seconds |

### `[tailscale]`

Server settings for each lab's [Tailscale gateway](../architecture/networking/tailscale.md).
These defaults are included in newly generated server configurations. Existing
files may omit the section, and partial sections override only the listed fields.
Restart `sherpad` after editing the server configuration.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `image` | string | `tailscale/tailscale:v1.102.3` | Gateway container image; pulled if absent |
| `socket_path` | string | `/run/tailscale/tailscaled.sock` | Absolute daemon socket path inside the gateway container |
| `exec_timeout_secs` | int | `75` | Maximum wait for each Docker exec command |
| `daemon_ready_timeout_secs` | int | `20` | Maximum wait for the daemon socket after starting the gateway |
| `enrollment_timeout_secs` | int | `60` | Timeout passed to `tailscale up` for enrollment |
| `connection_timeout_secs` | int | `30` | Maximum wait for the gateway to report connected after enrollment or resume |
| `stop_timeout_secs` | int | `10` | Docker stop grace period before the gateway is killed |

Timeouts must be positive seconds. `stop_timeout_secs` must fit a signed 32-bit
integer. Keep `exec_timeout_secs` longer than `enrollment_timeout_secs` so the
Docker command can finish. Socket paths must fit Linux's Unix socket path limit.
An empty image, invalid socket path, or invalid timeout prevents server startup.

For example, increase the enrollment wait while keeping the other defaults:

```toml
[tailscale]
exec_timeout_secs = 135
enrollment_timeout_secs = 120
```

Image changes apply to newly created gateways. Before changing `socket_path`,
destroy existing Tailscale-enabled labs and recreate them after restarting the
server so the daemon and CLI use the same path. Docker ownership label keys remain
fixed to allow safe resource identification and cleanup.

This server section is separate from the lab manifest's `[tailscale]` section,
which enables Tailscale and names the client auth-key environment variable.

## Client Configuration

The client configuration file is located at `~/.sherpa/config/sherpa.toml`. It is created by running `sherpa init`.

### Example

```toml
name = "my-client"
server_ipv4 = "10.0.0.1"
ws_port = 3030
http_port = 3031

[server_connection]
timeout_secs = 3
validate_certs = true

[tls]
enabled = true
```

### Client Fields

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `name` | string | `""` | Client name |
| `server_ipv4` | string | `127.0.0.1` | Server IPv4 address to connect to |
| `server_ipv6` | string | | Server IPv6 address to connect to |
| `ws_port` | int | `3030` | Server WebSocket port |
| `http_port` | int | `3031` | Server HTTP port |

The client also supports the `[server_connection]` and `[tls]` sections with the same fields as the server configuration.
