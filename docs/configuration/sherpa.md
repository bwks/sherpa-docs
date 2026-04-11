# Configuration

Sherpa uses TOML configuration files for both the server and client.

## Server Configuration

The server configuration file is located at `/opt/sherpa/sherpa.toml`.

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
| `management_prefix_ipv6` | string | | Management network IPv6 CIDR |
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
