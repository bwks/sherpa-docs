## Domain

### List Domains (VM's)

```
virsh list --all
```

### Show Domain XML

```
virsh dumpxml <domain_name>
```

## Networking

### List Networks

```
virsh net-list --all
```

### Show Network XML

```
virsh net-dumpxml <network_name>
```

## Storage

```
virsh pool-list --all --detailed
```

```
virsh pool-info <pool_name>
```

```
virsh pool-dumpxml <pool_name>
```
