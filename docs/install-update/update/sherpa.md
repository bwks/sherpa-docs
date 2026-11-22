# Sherpa

The update script replaces the Sherpa binaries with a release from GitHub and restarts `sherpad`,
taking a backup of the database and its key first.
It does not reinstall system packages or change users, and creates the
[blank disks](../install/automated.md#blank-disks) that are missing. It updates the `sherpa` CLI on the server
only: update it on every other client too, to the same version, as described in
[Client](client.md).

!!! danger

    Piping to sudo can be dangerous. You are strongly encouraged to review the below script
    before executing the below command.

Update to the latest release:

```
curl -fsSL https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_update.sh | sudo bash
```

Update to a specific release, or reinstall the current one:

```
curl -fsSLO https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_update.sh
sudo bash sherpa_update.sh --version v0.5.0
sudo bash sherpa_update.sh --force
```

## What the update does

1. It downloads the release while `sherpad` is still running. If a download fails, it stops and
   changes nothing, and `sherpad` keeps running.
2. It stops `sherpad` and copies the database, `/opt/sherpa/db/sherpa.sqlite` with its `-wal` and
   `-shm` files, and the [database key](../../architecture/database.md#database-key),
   `/opt/sherpa/.secret/db.key`, to a new folder, `/var/backups/sherpa/update-<UTC time>/`. Only
   root can read it. The script prints the folder's path, and at the end prints it again.
3. It installs the new binaries and starts `sherpad`. The new release counts as started once it
   has run for ten seconds without systemd restarting it.

If anything fails after `sherpad` stops, the script starts `sherpad` again. If the new release
does not start, for example because it cannot migrate the database, the script first puts back
the binaries that were installed, then restores the database and the key from the backup, and
starts the release you had. Anything the new release wrote in the seconds it ran is lost. The
script exits with an error and names the backup.

The script never removes its backups, and no uninstall mode removes `/var/backups/sherpa`. Remove
old backups yourself. To restore one by hand, stop `sherpad` and copy the files back as `sherpa`,
mode `600`. Delete the database's `-wal` and `-shm` files first if the backup has none.

```
sudo systemctl stop sherpad
sudo rm -f /opt/sherpa/db/sherpa.sqlite-wal /opt/sherpa/db/sherpa.sqlite-shm
sudo install -o sherpa -g sherpa -m 600 /var/backups/sherpa/update-<time>/sherpa.sqlite* /opt/sherpa/db/
sudo install -o sherpa -g sherpa -m 600 /var/backups/sherpa/update-<time>/db.key /opt/sherpa/.secret/
sudo systemctl start sherpad
```

`sherpad` encrypts passwords in the database with the key and does not start on a database
without it, so a backup is only usable with the key from the same folder. For backups you keep
yourself, use [`sherpa server backup`](../../architecture/database.md#backups) and keep a copy of
the key apart from it. The update script creates `/opt/sherpa/.secret` (mode `700`, owned by
`sherpa`) if it is missing.

On every run, even when there is nothing to install, the update script creates each
[blank disk](../install/automated.md#blank-disks) that is missing from
`/opt/sherpa/images/blank_disk/`, before it stops `sherpad`. It never changes a disk that is
there. Nodes that boot from one, such as Cumulus Linux, Juniper vEvolved, Cisco IOSv, IOSvL2 and
ISE, MikroTik CHR and Flatcar Linux, fail to start without it. If `qemu-img`, `mkfs.fat`,
`mkfs.vfat` or `mkfs.ext4` is missing, the script first installs `qemu-utils`, `dosfstools` and `e2fsprogs`; if
a disk cannot be made, it stops before changing the binaries.

On every run, even when there is nothing to install, the update script makes `/opt/sherpa`,
`/opt/sherpa/bin` and `/opt/sherpa/libvirt` root's and `755`, creates the folders `sherpad`
writes that are missing, and stops if any of these paths has a symlink in it. It runs an
installed binary to read its version only when the binary is root's and no other account can
write it. A binary owned by `sherpa`, as older releases installed them, is never run and is
replaced, even at the version asked for. It sets `/opt/sherpa/config`,
`/opt/sherpa/env` and `/opt/sherpa/logs` to `750`, `sherpa.toml`, `sherpa.env` and
`sherpa.env.example` to `600`, and `sherpad.log` and its rotated copies to `640`, and makes
`sherpa` their owner. It changes no file's contents and leaves a symlink alone. Members of the
`sherpa` group cannot read `sherpa.toml` or `sherpa.env`: edit them with `sudoedit` or
`sudo -u sherpa`. See [file permissions](../install/automated.md#file-permissions).
