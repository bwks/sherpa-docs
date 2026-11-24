# Uninstall

The uninstall script removes the `sherpad` service and, depending on its mode, the data. It must
run as root.

```
curl -fsSL -o sherpa_uninstall.sh https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_uninstall.sh
sudo bash sherpa_uninstall.sh [--keep-data | --remove-data | --remove-all] [--force]
```

Before it asks to continue, the script prints what it will remove and what it will keep, and
where. It prints both lists again when it is done. Any answer but `yes` cancels it, and nothing
is changed. `--force` skips the question.

## Destroy labs first

While a lab runs, the script changes nothing in any mode, `--force` included. A running lab is
a VM, a container or a Tailscale gateway of a lab. The script exits with an error and lists each
running lab by its ID, with its nodes:

```
[ERROR] Labs are running. Nothing was changed.
  Lab 1a2b3c4d:
    container ctr01 (ctr01-1a2b3c4d)
    container sherpa-router (sherpa-router-1a2b3c4d)
Destroy each lab with `sherpa destroy`, or stop it with `sherpa down`, in its lab folder, then run this script again.
```

Destroy the labs with `sherpa destroy` in each lab folder, then run the script again. With
`--keep-data` and `--remove-data` you can also stop them with `sherpa down` and bring them back
after you install again.

The script finds labs without `sherpad`, so it works with `sherpad` stopped or broken. The labs
are the folders in `/opt/sherpa/labs`, named by lab ID. A VM, container or network is a lab's
when its name ends in `-<lab ID>`, the names Sherpa gives them. A Tailscale gateway is found by
its Docker labels. Lab names are in the database, which the script does not read, so it names
labs by ID. When labs exist and Docker or libvirt does not answer, the script cannot tell whether
they run, and it refuses too.

Destroy every lab before `--remove-all`. A stopped lab's VMs, containers, networks and gateway
volume are not removed, and `--remove-all` deletes their disks and folders, so they can no
longer start. The script lists these leftovers by name before it asks and again when it is
done, with the storage pool `sherpa-pool`, whose folder `--remove-all` deletes.

## Modes

Every mode stops and removes the `sherpad` service and:

- `/etc/systemd/system/sherpad.service` and its drop-ins
- `/etc/logrotate.d/sherpad`
- the transparent hugepages boot rule, `/etc/tmpfiles.d/sherpa-thp.conf`. The running setting
  stays as it is until the next reboot.
- `/opt/sherpa/bin/sherpad` and its link `/usr/local/bin/sherpad`
- the `sherpa-db` container of a release before 0.5.0, if there is one

No mode removes a package. Docker, libvirt and QEMU stay installed and running.

### `--keep-data` (default)

Removes only what every mode removes. It keeps:

| Kept | Where |
|---|---|
| The database and its backups | `/opt/sherpa/db` |
| The login token secret and the database key | `/opt/sherpa/.secret` |
| The server's certificate and key | `/opt/sherpa/.certs` |
| The server's settings | `/opt/sherpa/config/sherpa.toml` |
| The service's environment | `/opt/sherpa/env/sherpa.env` |
| The lab folders | `/opt/sherpa/labs` |
| The node images and the VM disks | `/opt/sherpa/images`, `/opt/sherpa/libvirt/images` |
| The logs, the `sherpa` CLI and its link | `/opt/sherpa/logs`, `/opt/sherpa/bin/sherpa`, `/usr/local/bin/sherpa` |
| The container secret files, until the next reboot | `/run/sherpa` |
| The `sherpa` account and group, still in the `docker`, `libvirt` and `kvm` groups | |
| The update script's backups | `/var/backups/sherpa` |
| Stopped labs' VMs, containers and networks, and the storage pool | libvirt and Docker |

The `sherpa` account is kept because it owns the kept files. Install again and start `sherpad`,
and the same users log in.

### `--remove-data`

Also empties `/opt/sherpa/db`: the database and its backups. It keeps the rest, the database
key among it. Install again and run `sherpad init` to make a new database.

### `--remove-all`

Also removes:

- `/opt/sherpa`, with the database, the database key, the configuration, the certificates, the
  lab folders, the images and the VM disks
- the link `/usr/local/bin/sherpa`
- `/run/sherpa`
- the `sherpa` account, which leaves the `docker`, `libvirt` and `kvm` groups. Its `sherpa`
  group goes too, unless it is another account's primary group. Accounts you added to the
  `sherpa` group lose that membership. A `sherpa` account that is not a system account (UID
  1000 or more) is kept.

It keeps the update script's backups in `/var/backups/sherpa`, which hold copies of the database
and its key. Remove them with `sudo rm -rf /var/backups/sherpa`. It also keeps any stopped
lab's leftovers and the storage pool, which it lists.

Run on a host where nothing is left, the script exits 0.
