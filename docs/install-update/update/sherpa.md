# Sherpa

The update script replaces the Sherpa binaries with a release from GitHub and restarts `sherpad`.
It does not reinstall system packages or change users.

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

Take a [database backup](../../architecture/database.md#backups) before updating.

## Updating to 0.5.27

`sherpa up` exits with an error when the lab is only partly created: a container exited right
after it started, or a Kubernetes cluster, Vault or Keycloak did not come up. Before 0.5.27 these
were warnings and `sherpa up` exited with status 0. Scripts that run `sherpa up` now see a
non-zero status for such a lab; the lab is still created, so it can be used as it is or
destroyed. A node that is only slow to become ready is still a warning.

Labs have a [phase](../../command-reference.md#lab-phases) besides their status: `creating`,
`ready`, `destroying`, `destroy failed` or `interrupted`. The update makes every existing lab
`ready`. Only a `ready` lab can be stopped, resumed or redeployed; the others can only be
destroyed. A second `sherpa up` of a lab that exists, or that is being created, is refused
before it does anything, and no longer removes the other lab.

When the server starts, a lab it was creating when it stopped becomes `interrupted`, a lab it
was destroying becomes `destroy failed`, and a node it was building becomes `failed`. Nothing
is removed; destroy or redeploy them.

The CLI and the server can be updated separately: an older CLI does not show the phase, and an
older server's labs are shown as `ready`.

## Updating to 0.5.25

Node states change. A node being created is now `building` rather than `stopped`, a node whose
virtual machine or container no longer exists is `missing`, and the `created` state is gone:
nodes recorded `created` become `stopped`. See [node states](../../command-reference.md#node-states).

Update the `sherpa` CLI on every client together with the server. The server does not refuse an
older client, which only warns that the versions differ, but a CLI older than 0.5.25 cannot read
the new states: `sherpa inspect`, `sherpa destroy` and the other commands that read a lab's
details from the server fail with a decode error for a lab that has a `building` or `missing`
node. From 0.5.25 the CLI shows any state it does not know as `unknown`, so later new states do
not break it. The web UI is part of the server and needs no update.

## Updating to 0.5.23

Logins become server-side sessions, so that logging out, changing a password and deleting a user
end them at once. Tokens issued before 0.5.23 name no session, so after the update every user
must log in again: run `sherpa login` on each client, and log in again in the web UI.

From 0.5.23, `sherpad` refuses to start when its JWT secret file is damaged, instead of replacing
it; see
[Troubleshooting](../../help/troubleshooting.md#sherpad-does-not-start-the-jwt-secret-is-the-wrong-length).

## Updating to 0.5.0

Releases before 0.5.0 kept Sherpa's data in a SurrealDB container named `sherpa-db`. From 0.5.0,
`sherpad` keeps it in an embedded database file, `/opt/sherpa/db/sherpa.sqlite`. An update to a
release from 0.5.0 to 0.5.12 moves the data across. Use the update script for this, not the install
script: the install script refuses to run on a server that still has the `sherpa-db` container.

Releases after 0.5.12 cannot move the data. To update a server older than 0.5.0 to one of them,
update to 0.5.12 first, which moves the data, then to the release you want:

```
sudo bash sherpa_update.sh --version v0.5.12
sudo bash sherpa_update.sh
```

The update script refuses to go straight to a later release, and changes nothing when it does.

The update:

1. stops `sherpad`, keeping a copy of the old binary as `/opt/sherpa/bin/sherpad.previous`;
2. installs the new binaries;
3. starts the `sherpa-db` container if it is stopped, and runs `sherpad migrate-db`, which copies
   every user, image, lab, node, link and bridge into the new database file and checks the counts.
   It runs through systemd with `/opt/sherpa/env/sherpa.env`, as the `sherpad` service does, so
   it reads the SurrealDB password exactly as the old release did, quotes included, and it
   connects on the port Docker publishes `sherpa-db` on;
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

The `SHERPA_DB_PASSWORD` and `SHERPA_DB_PORT` entries in `/opt/sherpa/env/sherpa.env` are only used
to move the data, and can be removed afterwards.

### Moving the data by hand

`sherpad migrate-db` can also run by hand, for example after installing a binary yourself. Run
it with `sherpad` stopped and the `sherpa-db` container running. This runs it the way the update
script does, as the `sherpa` user with the variables from `/opt/sherpa/env/sherpa.env`:

```
sudo systemctl stop sherpad
sudo systemd-run --quiet --wait --pipe --collect --uid=sherpa \
  --property=EnvironmentFile=-/opt/sherpa/env/sherpa.env \
  /opt/sherpa/bin/sherpad migrate-db
sudo systemctl start sherpad
```

It takes the SurrealDB password and port from `--db-pass` and `--db-port`, or the
`SHERPA_DB_PASSWORD` and `SHERPA_DB_PORT` environment variables; it does not read the env file
itself. With the command above, systemd sets both variables from the env file.
It refuses to import into a database that already has users or labs. Run it before `sherpad`
first starts on the new release: with `SHERPA_ADMIN_PASSWORD` set, starting creates the `admin`
account in the new database, and the import then refuses it.
