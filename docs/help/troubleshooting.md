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

`sherpad` encrypts secret values in its database, such as each user's device password, with
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

## A user cannot log in: the account is locked

### Error

```
username and/or password is incorrect
```

The same message is given for a wrong password and an unknown username, so it does not say the
account is locked.

### Fix

Three failed logins in a row lock an account, and it stays locked, even for the right password,
until an admin unlocks it. Unlock it with:

```
sherpa server user unlock <username>
```

or with the **Unlock** button in the **Locked** column of the **Users** admin page in the web UI.
The user can then log in with their password. Resetting the password does not unlock the account.

## The built-in sherpa-admin account is locked

### Error

Logging in as `sherpa-admin` gives `username and/or password is incorrect` even with the right password.

### Fix

If another admin can log in, they unlock it with `sherpa server user unlock sherpa-admin`. Otherwise,
root unlocks it on the Sherpa server with [`sherpad user unlock`](../command-reference.md#sherpad-user-unlock).
`sherpad` holds the database file open, so stop it first, unlock `sherpa-admin` as the `sherpa` user,
then start it again:

```
sudo systemctl stop sherpad
sudo -u sherpa sherpad user unlock sherpa-admin
sudo systemctl start sherpad
```

`sherpad user unlock` changes only whether `sherpa-admin` is locked and its count of failed
logins; `sherpa-admin` then logs in with its password. It works the same for any other account.
