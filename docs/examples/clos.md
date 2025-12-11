# CLOS

```toml
name = "sherpa-clos"

nodes = [
  { name = "spine01", model = "sonic_linux" },
  { name = "spine02", model = "sonic_linux" },
  { name = "leaf01", model = "sonic_linux" },
  { name = "leaf02", model = "sonic_linux" },
  { name = "leaf03", model = "sonic_linux" },
  { name = "leaf04", model = "sonic_linux" },
]

links = [
  { src = "spine01::eth1", dst = "leaf01::eth51" },
  { src = "spine01::eth2", dst = "leaf02::eth51" },
  { src = "spine01::eth3", dst = "leaf03::eth51" },
  { src = "spine01::eth4", dst = "leaf04::eth51" },
  { src = "spine02::eth1", dst = "leaf01::eth52" },
  { src = "spine02::eth2", dst = "leaf02::eth52" },
  { src = "spine02::eth3", dst = "leaf03::eth52" },
  { src = "spine02::eth4", dst = "leaf04::eth52" },
]
```
