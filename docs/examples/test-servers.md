# Test Servers

Sherpa makes it convenient to deploy different platforms and operating systems
for testing software and configurations.

```toml
name = "sherpa-testservers"

[[nodes]]
name = "dev01"
model = "fedora_linux"

[[nodes]]
name = "dev02"
model = "ubuntu_linux"

[[nodes]]
name = "dev03"
model = "windows_server"

[[nodes]]
name = "dev04"
model = "free_bsd"

[[nodes]]
name = "dev05"
model = "open_bsd"
```
