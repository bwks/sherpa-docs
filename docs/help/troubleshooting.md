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
