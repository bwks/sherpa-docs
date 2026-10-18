# CLOS

```toml
name = "sherpa-clos"

[[nodes]]
name = "spine01"
model = "sonic_linux"

[[nodes]]
name = "spine02"
model = "sonic_linux"

[[nodes]]
name = "leaf01"
model = "sonic_linux"

[[nodes]]
name = "leaf02"
model = "sonic_linux"

[[nodes]]
name = "leaf03"
model = "sonic_linux"

[[nodes]]
name = "leaf04"
model = "sonic_linux"

[[links]]
src = "spine01::eth1"
dst = "leaf01::eth51"

[[links]]
src = "spine01::eth2"
dst = "leaf02::eth51"

[[links]]
src = "spine01::eth3"
dst = "leaf03::eth51"

[[links]]
src = "spine01::eth4"
dst = "leaf04::eth51"

[[links]]
src = "spine02::eth1"
dst = "leaf01::eth52"

[[links]]
src = "spine02::eth2"
dst = "leaf02::eth52"

[[links]]
src = "spine02::eth3"
dst = "leaf03::eth52"

[[links]]
src = "spine02::eth4"
dst = "leaf04::eth52"
```
