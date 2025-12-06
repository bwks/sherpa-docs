## QCOW2 Image is Corrupt

### Error

```
qcow2: Image is corrupt; cannot be opened read/write
```

### Fix

```
qemu-img check -r all  ~/.sherpa/boxes/<device_model>/<version>/virtioa.qcow2
```
