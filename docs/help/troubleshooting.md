## QCOW2 Image is Corrupt

### Error

```
qcow2: Image is corrupt; cannot be opened read/write
```

### Fix

```
qemu-img check -r all  /opt/sherpa/images/<device_model>/<version>/virtioa.qcow2
```

## Login refused with the right password

### Error

```
Invalid username or password
```

### Fix

`sherpad` limits failed logins. Each failure counts for 15 minutes after it was made, and a login
is refused while the failures of the last 15 minutes reach a limit:

- a username from one address: 5 failed logins for it from that address refuse that username
  from that address only. The same user can still log in from another address, so someone who
  knows a username cannot lock its user out by failing from their own address.
- an address: 20 failed logins from it, for any usernames, refuse every login from it.
- a username from any address: 50 failed logins for it, from all addresses together, refuse it
  from every address.

Every IPv6 address in one /64 prefix counts as one address. The address is the address the
connection to `sherpad` comes from, so users behind one NAT or proxy share it.

The limits are the same for `sherpa login`, the REST API and the web UI login form, and they
apply to the built-in `admin` account too. A refused login gets the same answer as a wrong
password, the password is not checked, and it is not counted as a failure.

A lock lasts until enough of its failures are 15 minutes old to bring the count under the limit.
That is at most 15 minutes after the failure that reached the limit, and less when the earlier
failures were spread out: 4 failures, then a fifth 10 minutes later, lock the username from that
address for 5 minutes. Trying again while locked does not lengthen the lock. Wait up to 15
minutes, then log in again.

A successful login clears only the failures of that username from that address: a lock from
another address stays, and failures from every other address still count toward the limit of 50.

The failures are kept in the database, so they survive a restart of `sherpad`: restarting it does
not lift a lock. `sherpad` deletes failures older than 15 minutes when it starts and every 15
minutes. It keeps at most 100,000; when that many still count, new failures are not counted until
old ones expire, which `sherpad` logs once at `warn`. A full table never refuses a login.

`sherpad` logs each lockout once, at `warn`, with the username and the address.

## sherpad does not start: the JWT secret is the wrong length

### Error

```
The JWT secret /opt/sherpa/.secret/jwt.secret is 12 bytes long, not 32. Restore it from a
backup, or delete it to generate a new one, which logs every user out
```

### Fix

`sherpad` signs login tokens with this file. It is 32 random bytes, so a different length means
it was damaged or replaced. Restore it from a backup if you have one, then start `sherpad`.
Otherwise delete it; `sherpad` generates a new one when it starts, and every user must then log
in again:

```
sudo rm /opt/sherpa/.secret/jwt.secret
sudo systemctl restart sherpad
```

## sherpad does not start: the database key is missing or does not match

### Error

One of:

```
The database key /opt/sherpa/.secret/db.key is missing, and the database's secret values are
sealed with it. Restore the key file that was backed up with this database; a new key cannot
open them
```

```
The database key does not match the key this database's secret values are sealed with. Restore
the key file that was backed up with this database
```

```
The database key /opt/sherpa/.secret/db.key is damaged
```

### Fix

`sherpad` encrypts secret values in its database, such as a lab's `ztp_server.password`, with
the key in `/opt/sherpa/.secret/db.key`; see [Database key](../architecture/database.md#database-key).
The key is not in the database or its backups, so a restored database needs the key it was
backed up with. Copy that key back, owned by `sherpa` with mode `600`, then start `sherpad`:

```
sudo install -o sherpa -g sherpa -m 600 /path/to/backed-up/db.key /opt/sherpa/.secret/db.key
sudo systemctl restart sherpad
```

`sherpad` never makes a new key for a database that already has encrypted values, because the
new key could not read them. Without the right key, restore a database backup taken together
with a key you have.
