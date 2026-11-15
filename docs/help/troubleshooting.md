## QCOW2 Image is Corrupt

### Error

```
qcow2: Image is corrupt; cannot be opened read/write
```

### Fix

```
qemu-img check -r all  /opt/sherpa/images/<device_model>/<version>/virtioa.qcow2
```

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
