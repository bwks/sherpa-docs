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
allow_signup = false

[ztp_server]
enable = true
username = "sherpa"
password = "sherpa"

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

[host_memory]
reserve_mib = 4096
overcommit_percent = 100
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
| `allow_signup` | bool | `false` | Let anyone create an account on the web UI's signup page. Off, the page returns 404 and only admins create accounts, with [`sherpa server user create`](../command-reference.md#sherpa-server-user-create) |

### `[ztp_server]`

Zero-Touch Provisioning server settings.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `enable` | bool | `true` | Enable or disable the ZTP server |
| `username` | string | `"sherpa"` | ZTP authentication username |
| `password` | string | `"Everest1953!"` | ZTP authentication password |

### `[server_connection]`

Internal server connection settings.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `url` | string | | WebSocket URL override |
| `http_port` | int | `3031` | The server's HTTP port, which serves its certificate on first connect |
| `timeout_secs` | int | `3` | Connection timeout in seconds |
| `validate_certs` | bool | `true` | Trust a server certificate a public CA issued without asking; see below |
| `ca_cert_path` | string | | Path to custom CA certificate for self-signed certs |
| `insecure` | bool | `false` | Skip certificate validation (development only) |

With `validate_certs = true`, the client first trusts the public certificate authorities. A
server with a publicly issued certificate is trusted without a prompt. For any other
certificate, such as the self-signed one Sherpa generates, the client shows the certificate and
its fingerprint and asks you to trust it (see [Certificate Commands](../command-reference.md#certificate-commands)).
With `validate_certs = false`, the client trusts only certificates you have trusted, and asks
about every new server. `ca_cert_path` and `insecure` take precedence over both.

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
| `endpoint` | string | `http://localhost:4317` | OTLP collector endpoint, over gRPC |
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

### `[host_memory]`

How much memory the server may give its virtual machines and unikernels. Before `sherpa up`,
`sherpa redeploy`, `sherpa resume` or a node start in the web UI starts any node, the server
adds up the memory already promised and refuses the request if the new nodes do not fit.
Nothing is created or started when a request is refused.

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `reserve_mib` | int | `4096` | Memory in MiB kept back for the host: its operating system, `sherpad`, QEMU's own memory and containers |
| `overcommit_percent` | int | `100` | The percentage of the memory left after the reserve guests may be given in total, for example `150` for 1.5 times. Must be at least `1` |

The memory promised is the configured memory of every running or paused virtual machine and
unikernel on the server, Sherpa's and any others libvirt runs, plus the nodes other requests are
starting. It is compared with the server's memory, less any reserved hugepages and
`reserve_mib`, times `overcommit_percent` percent, rounded down to a whole MiB. Free memory is
not used: a guest takes its memory only as it touches it, so a server that looks free when a lab
starts can run out later.

A virtual machine with [`numa_node`](../manifest.md#performance_tuning-object) held strictly
(`numa_memory_mode = "strict"`, the default) is also checked against that NUMA node. Its memory
cannot move to another node, so the node must have room for it beside the other virtual
machines held strictly there, after the node's share of `reserve_mib`. A virtual machine with
`numa_memory_mode = "preferred"` can take memory from other nodes, so it is checked against the
whole server only.

Containers are not counted, as Sherpa does not limit their memory; keep `reserve_mib` large
enough for them. With `overcommit_percent = 100` the guests are never given more memory than the
server has. Raise it only if the guests do not use all their memory, for example idle router
labs; if they touch more than the server has, the host's OOM killer stops virtual machines.

A refusal names the numbers that fell short, for example:

```
Not enough memory on the server: node 'r3' needs 8192 MiB, but only 2048 MiB of guest memory
is left, 6144 MiB short. ...
```

An `overcommit_percent` below `1` prevents server startup, and the error names the setting.
Restart `sherpad` after editing the server configuration.

## Client Configuration

The client configuration file is located at `~/.sherpa/config/sherpa.toml`. It is created by running `sherpa init`.

### Example

```toml
name = "my-client"
server_ipv4 = "10.0.0.1"
ws_port = 3030

[server_connection]
http_port = 3031
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

The client also supports the `[server_connection]` and `[tls]` sections with the same fields as the server configuration.
The server's HTTP port, if it is not `3031`, goes in `[server_connection]` as `http_port`.
A field left out of a section takes its default. `timeout_secs` limits connecting to the
server; a long operation such as `sherpa up` then runs for as long as it needs.

Without the file, the client uses these defaults. A file that exists but cannot be read or
parsed is an error naming the file, rather than being silently replaced by the defaults.
