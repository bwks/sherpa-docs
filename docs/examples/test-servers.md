# Test Servers

Sherpa makes it convenient to deploy different platforms and operating systems
for testing software and configurations.

```toml
name = "sherpa-testservers"

nodes = [
  { name = "dev01", model = "fedora_linux" },
  { name = "dev02", model = "ubuntu_linux" },
  { name = "dev03", model = "windows_server" },
  { name = "dev04", model = "free_bsd" },
  { name = "dev05", model = "open_bsd" },
]
```
