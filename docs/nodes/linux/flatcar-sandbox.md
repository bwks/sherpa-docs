# Flatcar Sandbox

`flatcar_sandbox` is the base image of [sandboxes](../../architecture/sandboxes.md): the
Flatcar Container Linux VMs that the
[`arista_eos` container](../arista/arista-eos.md#sandbox),
[`nokia_srlinux`](../nokia/nokia-srlinux.md#sandbox) and the
[`sonic_linux` container](../sonic/sonic-linux.md#sandbox) run in. It is no node of its own: a
manifest node with `model = "flatcar_sandbox"` is refused. For a Flatcar VM, use
[Flatcar Linux](flatcar-linux.md).

Without a `flatcar_sandbox` image, `sherpa up` and `sherpa redeploy` refuse a lab with one of
those nodes, before they create anything, and say how to import it.

## Base Image

Sandboxes boot Flatcar's OpenStack image, `flatcar_production_openstack_image.img.bz2`, from the
`stable` channel of the [Flatcar releases](https://www.flatcar.org/releases). Download it to the
Sherpa server and unpack it with `bunzip2`, which the install and update scripts install:

```
curl -fsSLO https://stable.release.flatcar-linux.net/amd64-usr/4757.2.4/flatcar_production_openstack_image.img.bz2
bunzip2 flatcar_production_openstack_image.img.bz2
```

## Import Image

Import the unpacked file, a path on the Sherpa server, with the Flatcar release as its version:

```
sherpa server image import \
  --src /some/path/flatcar_production_openstack_image.img \
  --model flatcar_sandbox \
  --version 4757.2.4 \
  --default
```

Sandboxes boot the default version. A lab's sandboxes keep the version they were made with until
they are redeployed.

## Default Parameters

| Property       | Value                                    |
| -------------- | ---------------------------------------- |
| Tested Version | 4757.2.4                                 |
| Kind           | Virtual Machine                          |
| File           | `flatcar_production_openstack_image.img` |
| Boot           | SeaBIOS, Flatcar's own bootloader        |
| ZTP            | Ignition, from a config drive Sherpa makes |
