# Automated

Sherpa can be installed via a convenience installation script.

!!! danger

    Piping to sudo can be dangerous. You are strongly encouraged to review the below script
    before executing the below command.

`sudo` privileges are requried. Run the following command to start the installation.

```
curl -fsSL https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_install.sh | sudo bash
```

No database server is installed: `sherpad` keeps its data in an embedded database,
`/opt/sherpa/db/sherpa.sqlite`, which `sherpad init` creates. See [Database](../../architecture/database.md).

To upgrade a server older than 0.5.0, update it to 0.5.12 first; see
[Updating to 0.5.0](../update/sherpa.md#updating-to-050). The install script refuses to run while
the old `sherpa-db` SurrealDB container exists.

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
and cannot read a `sherpa.toml` another account owns. systemd reads `sherpa.env` as root. To
edit either file, use `sudoedit` or `sudo -u sherpa`. Members of the `sherpa` group can read the
log, `/opt/sherpa/logs/sherpad.log`, which `sherpad` writes when it is not run by systemd; under
systemd it logs to the journal.

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
