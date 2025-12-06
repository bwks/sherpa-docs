## Initialise Sherpa

Setup Sherpa configurations, boxes directory structure and required Libvirt parameters.

```
sherpa init
```

## Build Environment

Bring up the environment.

```
sherpa up
```

This will bring up the virtual devices and stitch the interfaces together.

## Kill Environment

When done, tear down the environment.

```
sherpa destroy
```

## Import Image

```
sherpa import -s flatcar_production_qemu_image.img -v 4230.2.3 -m flatcar_linux --latest
```
