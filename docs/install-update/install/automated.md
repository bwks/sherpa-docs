# Automated

Sherpa can be installed via a convenience installation script.

!!! danger

    Piping to sudo can be dangerous. You are strongly encouraged to review the below script
    before executing the below command.

`sudo` privileges are requried. Run the following command to start the installation.

```
curl -fsSL https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_install.sh | sudo bash
```

The script installs Docker from [Docker's apt repository](https://docs.docker.com/engine/install/ubuntu/),
once Docker's signing key matches the one the script pins. A key that does not match stops the
install before apt trusts it.

No database server is installed: `sherpad` keeps its data in an embedded database,
`/opt/sherpa/db/sherpa.sqlite`, which `sherpad init` creates. See [Database](../../architecture/database.md).

## File Permissions

`/opt/sherpa`, the binaries in `/opt/sherpa/bin` and `/opt/sherpa/libvirt` are owned by root
and `755`: systemd runs `sherpad` from there, so neither `sherpa` nor members of the `sherpa`
group can change them. `sherpa` owns only the folders `sherpad` writes to, which the install and
update scripts create, as `sherpad` cannot create a folder in `/opt/sherpa`. The scripts change
these folders' owners and modes only, never what is in them, and stop without changing a path
that has a symlink in it.

Members of the `sherpa` group can read the lab folders and the log, and can write the images
folder, `/opt/sherpa/images`, and its blank disk folder; nothing else.

The install script, `sherpad init` and the update script give Sherpa's configuration and log
files these modes, all owned by `sherpa:sherpa`. The files that can hold secrets are readable
by the `sherpa` user only, not by members of the `sherpa` group: `sherpa.toml` can hold
passwords, and `sherpa.env` whatever you add to it, such as `OTEL_EXPORTER_OTLP_HEADERS` for an
OpenTelemetry collector that needs a token.

| Path | Mode | Set by |
|---|---|---|
| `/opt/sherpa`, `/opt/sherpa/bin`, `/opt/sherpa/libvirt` | `755`, root's | install, update |
| `/opt/sherpa/bin/sherpad`, `/opt/sherpa/bin/sherpa` | `755`, root's | install, update |
| `/opt/sherpa/config` | `750` | install, update |
| `/opt/sherpa/config/sherpa.toml` | `600` | `sherpad init`, update |
| `/opt/sherpa/env` | `750` | install, update |
| `/opt/sherpa/env/sherpa.env` | `600` | install, update |
| `/opt/sherpa/env/sherpa.env.example` | `600` | install, update |
| `/opt/sherpa/logs` | `750` | install, update, `sherpad` |
| `/opt/sherpa/logs/sherpad.log` | `640` | `sherpad`, update |
| `/opt/sherpa/.secret` | `700` | install, update, `sherpad` |
| `/opt/sherpa/.certs` | `700` | install, update, `sherpad` |
| `/opt/sherpa/db` | `750` | install, update, `sherpad` |
| `/opt/sherpa/images` | `775` | install, update |
| `/opt/sherpa/containers`, `/opt/sherpa/bins`, `/opt/sherpa/run` | `755` | install, update |

Run `sherpad init` as `sherpa` (`sudo -u sherpa -H sherpad init`): `sherpad` runs as `sherpa`
and cannot read a `sherpa.toml` another account owns. `sherpad init` refuses any other account,
root included. systemd reads `sherpa.env` as root. Running the install script again on an
installed server keeps `sherpa.env` as it is, your own lines included, and only adds, at its
end, a setting the script writes that the file lacks. To
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

The install script creates them, as `sherpa`, with `base.img`, `fat16.img` and ext4 `data-disk`
disks of 100 MiB, 200 MiB and 1 to 5 GiB that no node uses yet. Each is `400`, owned by
`sherpa:sherpa`, in a folder `775`: only `sherpad`, as `sherpa`, reads a template, to copy it,
and nodes boot from the copies. `sherpad doctor --images` sets the templates back to `400`. It installs the tools that make them, `qemu-utils`, `dosfstools` and
`e2fsprogs`, with its other packages.

The script only creates a disk that is missing, and never changes one that is there. The
[update script](../update/sherpa.md) does the same on every run, so running it again restores a
disk that was deleted.

## Before the First Lab

Each user sets a [device password](../../architecture/device-password.md), with
`sherpa server user device-password` or on the web UI **Profile** page, and registers an SSH
key, before the first `sherpa up`. `sherpad init` sets neither password for you, and `sherpa up`
refuses to start a lab without a device password.

## Server Key Pin

`sherpad` makes its TLS key when it first starts and keeps it. On every start it writes a new
self-signed certificate for that key, valid for `cert_validity_days` and naming the server's
current addresses, so a restart renews the certificate and follows a changed address; see
[`[tls]`](../../configuration/sherpa.md#tls).

Clients trust the server's key, not one certificate. The first time a client connects, it shows
the key pin, the SHA-256 of the server's public key, and asks the user to check it. A renewed
certificate has the same key, so clients do not ask again. Read the key pin on the server and give
it to your users:

```
sudo -u sherpa -H sherpad status
```

`sherpad` also logs it each time it starts, as `TLS key pin (SHA-256 of the server's public key)`.

## Transparent Hugepages

The script sets the host's transparent hugepages to `madvise`, so QEMU can back VM memory with
2 MiB pages. It sets it for the running system and adds a boot rule,
`/etc/tmpfiles.d/sherpa-thp.conf`, so it stays set after a reboot. A host already set to `always`
is left as it is, and a kernel without transparent hugepages is skipped with a warning.

`madvise` gives huge pages only to programs that ask for them, such as QEMU. To go back to the
kernel's default, delete `/etc/tmpfiles.d/sherpa-thp.conf` and reboot. The uninstall script
deletes it too.

## Uninstall

To take Sherpa off the host, destroy its labs and run the uninstall script. See
[Uninstall](../uninstall.md) for what each mode removes and keeps.
