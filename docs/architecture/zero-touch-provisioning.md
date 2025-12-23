# Zero Touch Provisioning

Configuring nodes via Zero Touch Provisioning (ZTP) is a core design goal of Sherpa. Every supported device has a method to apply a configuration to a node on first boot.

## Default Node Configuration

The following configuration parameters are applied to nodes via ZTP:

- Hostname
- Management IPv4/6 addresses
- Default route
- DNS domain
- DNS name servers
- DNS search domains
- Sherpa user with password and SSH key authentication.

## Custom Node Configuration

User defined configuration can be applied to devices by specifying
the location with the `ztp_config` parameter in the `manifest.toml`
file.

### Example

```toml
# manifest.toml
nodes = [
  { name = "dev01", model = "sonic_linux", ztp_config = "/some/path/dev01.conf" }
]
```

## ZTP Methods

### Cloud-Init

### Ignition

### USB Disk

### Config Disk

### TFTP

### HTTP
