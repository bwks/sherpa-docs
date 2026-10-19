# Basic

![dev01, a Cisco IOSv VM, linked from gig0/1 to eth-1/1 on dev02, a Nokia SR Linux container](basic.svg)

```toml
name = "sherpa-basic"

[[nodes]]
name = "dev01"
model = "cisco_iosv"

[[nodes]]
name = "dev02"
model = "nokia_srlinux"

[[links]]
src = "dev01::gig0/1"
dst = "dev02::eth-1/1"
```
