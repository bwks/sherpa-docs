## QCOW2 Image is Corrupt

### Error

```
qcow2: Image is corrupt; cannot be opened read/write
```

### Fix

```
qemu-img check -r all  /opt/sherpa/images/<device_model>/<version>/virtioa.qcow2
```


## Tailscale Management Access

If lab creation rejects enrollment, check the client auth-key environment variable,
server TLS, WSS certificate validation, device approval, and Docker/TUN availability.
Pending subnet-route approval is a warning and does not fail lab creation.

If routes are approved but node management addresses are unreachable, check tailnet
access policy, client route acceptance, node state, and management-prefix conflicts.

If gateway or identity-volume cleanup fails, resolve the Docker error or volume
attachment and retry `sherpa destroy` as the owner, or
`sherpa server clean <lab_id>` as an administrator. Sherpa retains database ownership
and saved server-side lab configuration after a Tailscale cleanup failure; other
lab resources may already have been removed.

See [Tailscale recovery](../architecture/networking/tailscale.md#recovery) for
reauthentication, address conflicts, and stale device records.
