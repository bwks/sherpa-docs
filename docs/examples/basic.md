# Basic

```toml
name = "sherpa-basic"

nodes = [
  { name = "dev01", model = "cisco_iosv" },
  { name = "dev02", model = "nokia_srlinux" },
]

links = [
  { src = "dev01::gig0/1", dst = "dev02::eth-1/1" }
]
```
