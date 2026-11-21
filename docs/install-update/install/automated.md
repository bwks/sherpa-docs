# Automated

Sherpa can be installed via a convenience installation script.

`sudo` privileges are required. Download the install script and the release's checksums from the
[releases page](https://github.com/bwks/sherpa/releases), check the script, read it, and run it.
Set `VERSION` to the release's tag, such as `v0.7.2`.

```
VERSION=<release tag>
cd "$(mktemp -d)"
curl -fsSLO "https://github.com/bwks/sherpa/releases/download/${VERSION}/sherpa_install.sh"
curl -fsSLO "https://github.com/bwks/sherpa/releases/download/${VERSION}/SHA256SUMS"
sha256sum --check --ignore-missing SHA256SUMS
sudo bash sherpa_install.sh --version "${VERSION}"
```

`sha256sum` must print `sherpa_install.sh: OK`. The script checks each archive it downloads
against the same `SHA256SUMS` before it uses it, and stops at one that does not match. It
installs Docker from [Docker's apt repository](https://docs.docker.com/engine/install/ubuntu/)
once Docker's signing key matches the one the script pins, and pulls the Sherpa router image by
its digest.

No database server is installed: `sherpad` keeps its data in an embedded database,
`/opt/sherpa/db/sherpa.sqlite`, which `sherpad init` creates. See [Database](../../architecture/database.md).

## File Permissions

The install script, `sherpad init` and the update script give Sherpa's configuration and log
files these modes, all owned by `sherpa:sherpa`. The files that can hold secrets are readable
by the `sherpa` user only, not by members of the `sherpa` group: `sherpa.toml` can hold
passwords, and `sherpa.env` whatever you add to it, such as `OTEL_EXPORTER_OTLP_HEADERS` for an
OpenTelemetry collector that needs a token.

| Path | Mode | Set by |
|---|---|---|
| `/opt/sherpa/config` | `750` | install, update |
| `/opt/sherpa/config/sherpa.toml` | `600` | `sherpad init`, update |
| `/opt/sherpa/env` | `750` | install, update |
| `/opt/sherpa/env/sherpa.env` | `600` | install, update |
| `/opt/sherpa/env/sherpa.env.example` | `600` | install, update |
| `/opt/sherpa/logs` | `750` | install, update, `sherpad` |
| `/opt/sherpa/logs/sherpad.log` | `640` | `sherpad`, update |
| `/opt/sherpa/.secret` | `700` | install, update, `sherpad` |
| `/opt/sherpa/.certs` | `700` | `sherpad` |
| `/opt/sherpa/db` | `750` | install, update, `sherpad` |

Run `sherpad init` as `sherpa` (`sudo -u sherpa -H sherpad init`): `sherpad` runs as `sherpa`
and cannot read a `sherpa.toml` another account owns. `sherpad init` refuses any other account,
root included. systemd reads `sherpa.env` as root. To
edit either file, use `sudoedit` or `sudo -u sherpa`. Members of the `sherpa` group can read the
log, `/opt/sherpa/logs/sherpad.log`, which `sherpad` writes when it is not run by systemd; under
systemd it logs to the journal.

## Blank Disks

Some nodes boot with a small configuration disk, which `sherpad` copies from a blank disk
template in `/opt/sherpa/images/blank_disk/` and writes the node's config onto:

| File | Disk | Used by |
|---|---|---|
| `fat32.img` | 64 MiB, FAT32 | Cumulus Linux USB, MikroTik CHR config disk |
| `junos.img` | 64 MiB, FAT16, label `vmm-data` | Juniper vEvolved USB |
| `iosv.img` | 64 MiB, FAT16 | Cisco IOSv and IOSvL2 config disk |
| `ise.img` | 10 MiB, ext4, label `ISE-ZTP` | Cisco ISE config disk |
| `ext4-500mb.img` | 500 MiB, ext4, label `data-disk` | Flatcar Linux data disk |

The install script creates them, with `base.img`, `fat16.img` and ext4 `data-disk` disks of
100 MiB, 200 MiB and 1 to 5 GiB that no node uses yet. Each is `644`, owned by `sherpa:sherpa`,
in a folder `775`. It installs the tools that make them, `qemu-utils`, `dosfstools` and
`e2fsprogs`, with its other packages.

The script only creates a disk that is missing, and never changes one that is there. The
[update script](../update/sherpa.md) does the same on every run, so running it again restores a
disk that was deleted.

## Before the First Lab

Each user sets a [device password](../../architecture/device-password.md), with
`sherpa server user device-password` or on the web UI **Profile** page, and registers an SSH
key, before the first `sherpa up`. `sherpad init` sets neither password for you, and `sherpa up`
refuses to start a lab without a device password.

## Certificate Fingerprint

`sherpad` generates a self-signed TLS certificate when it first starts. The first time a client
connects, it shows the certificate's fingerprint and asks the user to check it. Read the
fingerprint on the server and give it to your users:

```
sudo openssl x509 -in /opt/sherpa/.certs/server.crt -noout -fingerprint -sha256
```

`sherpad` also logs it each time it starts, as `TLS certificate fingerprint (SHA-256)`.

## Transparent Hugepages

The script sets the host's transparent hugepages to `madvise`, so QEMU can back VM memory with
2 MiB pages. It sets it for the running system and adds a boot rule,
`/etc/tmpfiles.d/sherpa-thp.conf`, so it stays set after a reboot. A host already set to `always`
is left as it is, and a kernel without transparent hugepages is skipped with a warning.

`madvise` gives huge pages only to programs that ask for them, such as QEMU. To go back to the
kernel's default, delete `/etc/tmpfiles.d/sherpa-thp.conf` and reboot. The uninstall script
deletes it too.
