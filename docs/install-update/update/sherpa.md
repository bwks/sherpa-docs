# Sherpa

The update script replaces the Sherpa binaries with a release from GitHub and restarts `sherpad`.
It does not reinstall system packages or change users.

!!! danger

    Piping to sudo can be dangerous. You are strongly encouraged to review the below script
    before executing the below command.

Update to the latest release:

```
curl https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_update.sh | sudo bash
```

Update to a specific release, or reinstall the current one:

```
sudo bash sherpa_update.sh --version v0.5.0
sudo bash sherpa_update.sh --force
```

Take a [database backup](../../architecture/database.md#backups) before updating.

## Updating to 0.5.0

Releases before 0.5.0 kept Sherpa's data in a SurrealDB container named `sherpa-db`. From 0.5.0,
`sherpad` keeps it in an embedded database file, `/opt/sherpa/db/sherpa.sqlite`. The first update
to 0.5.0 or later moves the data across. Use the update script for this, not the install script:
the install script refuses to run on a server that still has the `sherpa-db` container.

The update:

1. stops `sherpad`, keeping a copy of the old binary as `/opt/sherpa/bin/sherpad.previous`;
2. installs the new binaries;
3. starts the `sherpa-db` container if it is stopped, and runs `sherpad migrate-db`, which copies
   every user, image, lab, node, link and bridge into the new database file and checks the counts;
4. stops the `sherpa-db` container and turns off its automatic restart;
5. starts `sherpad`.

The move happens in one step: if it fails, nothing is written, the new database file is removed,
the previous `sherpad` is put back and started on the old database, and the script exits with an
error. The SurrealDB data is never changed.

### Rolling back

The update leaves the `sherpa-db` container and its data, `/opt/sherpa/db/sherpa.db`, in place.
To go back to the release you had before:

1. `sudo systemctl stop sherpad`
2. `sudo cp -p /opt/sherpa/bin/sherpad.previous /opt/sherpa/bin/sherpad`
3. `sudo docker update --restart=unless-stopped sherpa-db && sudo docker start sherpa-db`
4. `sudo systemctl start sherpad`

Changes made after the update, such as new labs or users, exist only in the new database and are
not in the old one.

To try the move again later, also remove the new database file before updating:
`sudo rm /opt/sherpa/db/sherpa.sqlite*`.

### Removing the old database

Once the server works on 0.5.0, remove the old container and its data:

```
sudo docker rm sherpa-db
sudo rm -rf /opt/sherpa/db/sherpa.db
sudo docker image rm surrealdb/surrealdb:v3.0.0
```

`/opt/sherpa/db/sherpa.db` is the old SurrealDB data directory. Do not confuse it with the new
database, `/opt/sherpa/db/sherpa.sqlite`.

The `SHERPA_DB_PASSWORD` and `SHERPA_DB_PORT` entries in `/opt/sherpa/env/sherpa.env` are only read
by `sherpad migrate-db`, and can be removed afterwards.

### Moving the data by hand

`sherpad migrate-db` can also run by hand, for example after installing a binary yourself. Run
it as the `sherpa` user, with `sherpad` stopped and the `sherpa-db` container running:

```
sudo systemctl stop sherpad
sudo -u sherpa -H sherpad migrate-db
sudo systemctl start sherpad
```

It reads the SurrealDB password and port from `--db-pass` and `--db-port`, the
`SHERPA_DB_PASSWORD` and `SHERPA_DB_PORT` environment variables, or `/opt/sherpa/env/sherpa.env`.
It refuses to import into a database that already has users or labs. Run it before `sherpad`
first starts on the new release: with `SHERPA_ADMIN_PASSWORD` set, starting creates the `admin`
account in the new database, and the import then refuses it.
