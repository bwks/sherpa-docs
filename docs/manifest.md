A `Manifest` describes the lab configuration parameters.
Manifests are defined in the `toml` format in a file named `manifest.toml`
in the current directory.

```toml
# manifest.toml
name = "sexy-salamander"

devices = [
  { name = "dev01", model = "cisco_cat8000v" },
  { name = "dev02", model = "cisco_cat8000v" },
]

links = [
  { src = "dev01::gig4", dst = "dev02::gig4" },
]
```

## Name

[Required] - The name of the lab.

To avoid naming collisions, the `lab name` is hashed with the users, `username`
to create a `lab-id`. Resources are suffixed with the `lab-id` to create unique resource names.

## Devices

[Required] - The devices that will be managed as part of this lab.

- **name**: The name of the device.
- **model**: The model of the device.

## Links

[Optional] - Links define the connectivity relationship between devices in the topology.

Each device is defined with it's `name` and `interface` separated by a double colon `(::)`

- **src**: Source `<device>::<interface>` mapping.
- **dst**: Destination `<device>::<interface>` mapping.
