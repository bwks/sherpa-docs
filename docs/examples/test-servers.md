# Test Servers

Sherpa makes it convenient to deploy different platforms and operating systems
for testing software and configurations.

![Five VMs running Fedora, Ubuntu, Windows Server, FreeBSD and OpenBSD, each on the management network](test-servers.svg)

Five servers with no data plane links. Each one is reachable only over the lab's management
network, which makes this a quick way to stand up a set of operating systems side by side,
for example to test a script, package or agent across all of them.

| Node    | Model                                                | Operating system |
| ------- | ---------------------------------------------------- | ---------------- |
| `dev01` | [Fedora Linux](../nodes/linux/fedora-linux.md)       | Fedora           |
| `dev02` | [Ubuntu Linux](../nodes/linux/ubuntu-linux.md)       | Ubuntu           |
| `dev03` | [Windows Server](../nodes/windows/windows-server.md) | Windows Server   |
| `dev04` | [FreeBSD](../nodes/bsd/free-bsd.md)                  | FreeBSD          |
| `dev05` | [OpenBSD](../nodes/bsd/open-bsd.md)                  | OpenBSD          |

The servers can reach each other over the management network, and reach outside the lab
through it. See [Management](../architecture/networking/modes/management.md).

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
