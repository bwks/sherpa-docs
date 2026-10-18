# Kubernetes

!!! tip

    For a Kubernetes cluster that Sherpa builds and bootstraps for you, see
    [Talos Linux](../nodes/linux/talos-linux.md#sherpa-built-clusters). The example below builds
    the nodes only, on Flatcar Linux.

```toml
name = "sherpa-kubernetes"

[[nodes]]
name = "utl01"
model = "flatcar_linux"

[[nodes]]
name = "ctl01"
model = "flatcar_linux"

[[nodes]]
name = "wrk01"
model = "flatcar_linux"

[[nodes]]
name = "wrk01"
model = "flatcar_linux"

[[nodes]]
name = "wrk01"
model = "flatcar_linux"
```
