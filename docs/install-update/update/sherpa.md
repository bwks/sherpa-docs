# Sherpa

The update script replaces the Sherpa binaries with a release from GitHub and restarts `sherpad`.
It does not reinstall system packages or change users, and creates the
[blank disks](../install/automated.md#blank-disks) that are missing. It updates the `sherpa` CLI on the server
only: update it on every other client too, to the same version, as described in
[Client](client.md).

Download the update script of the release you update to, with the release's checksums, check
the script, and run it. Set `VERSION` to the release's tag from the
[releases page](https://github.com/bwks/sherpa/releases).

```
VERSION=<release tag>
cd "$(mktemp -d)"
curl -fsSLO "https://github.com/bwks/sherpa/releases/download/${VERSION}/sherpa_update.sh"
curl -fsSLO "https://github.com/bwks/sherpa/releases/download/${VERSION}/SHA256SUMS"
sha256sum --check --ignore-missing SHA256SUMS
sudo bash sherpa_update.sh --version "${VERSION}"
```

`sha256sum` must print `sherpa_update.sh: OK`. Add `--force` to reinstall the version that is
there. The script checks each archive it downloads against the release's `SHA256SUMS` before it
uses it, and refuses a release that publishes none.

Take a [database backup](../../architecture/database.md#backups) before updating, and keep a
copy of the [database key](../../architecture/database.md#database-key),
`/opt/sherpa/.secret/db.key`, alongside it but separately. `sherpad` encrypts passwords in the
database with that key, and does not start on a database without it. The update
script creates `/opt/sherpa/.secret` (mode `700`, owned by `sherpa`) if it is missing.

On every run, even when there is nothing to install, the update script creates each
[blank disk](../install/automated.md#blank-disks) that is missing from
`/opt/sherpa/images/blank_disk/`, before it stops `sherpad`. It never changes a disk that is
there. Nodes that boot from one, such as Cumulus Linux, Juniper vEvolved, Cisco IOSv, IOSvL2 and
ISE, MikroTik CHR and Flatcar Linux, fail to start without it. If `qemu-img`, `mkfs.fat`,
`mkfs.vfat` or `mkfs.ext4` is missing, the script first installs `qemu-utils`, `dosfstools` and `e2fsprogs`; if
a disk cannot be made, it stops before changing the binaries.

On every run, even when there is nothing to install, the update script sets `/opt/sherpa/config`,
`/opt/sherpa/env` and `/opt/sherpa/logs` to `750`, `sherpa.toml`, `sherpa.env` and
`sherpa.env.example` to `600`, and `sherpad.log` and its rotated copies to `640`, and makes
`sherpa` their owner. It changes no file's contents and leaves a symlink alone. Members of the
`sherpa` group cannot read `sherpa.toml` or `sherpa.env`: edit them with `sudoedit` or
`sudo -u sherpa`. See [file permissions](../install/automated.md#file-permissions).
