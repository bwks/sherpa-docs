# Aruba AOS-CX

## Base Image

The base image can be downloaded from the [HPE Support Portal](https://networkingsupport.hpe.com/globalsearch#q=aos-cx%20switch%20simulator&tab=all). Search for `aos-cx switch simulator`.

!!! Note

    An account is required to download the image.

## Import Image

### Extract

The image is compressed in a `.zip` file so extract it.

```
unzip AOS-CX_Switch_Simulator_10_16_1010_ova.zip
```

### Convert

The extracted file is in `ova` format and needs to be converted to `qcow2`.

```
mkdir aos-ova && \
  tar -xvf AOS-CX_10_16_1010.ova -C aos-ova && \
  cd aos-ova && \
  qemu-img convert -p -f vmdk -O qcow2 arubaoscx-disk-image-genericx86-p4-20251110170622.vmdk /some/path/<image_name>.qcow2
```

### Import

```
sherpa server image import \
  --src /some/path/<image_name>.qcow2 \
  --version 10.16 \
  --model aruba_aoscx \
  --default
```

## Default Node Parameters

| Property             | Value           |
| -------------------- | --------------- |
| Kind                 | Virtual Machine |
| Tested Version       | 10.16           |
| CPU                  | 2               |
| RAM                  | 4GB             |
| CDROM Driver         | SATA            |
| DISK                 | virtioa.qcow2   |
| DISK Driver          | virtio          |
| ZTP                  | `tftp`          |
| Management Interface | mgmt            |
| Data Interfaces      | 1/1/1-52        |
| Interface Driver     | virtio          |

## Example Manifest

```toml
name = "aruba-aoscx"

[[nodes]]
name = "dev01"
model = "aruba_aoscx"
```


## Logins

You log in by SSH key only. The configuration Sherpa serves over TFTP carries no password:

- your account has your SSH keys, and its password is locked;
- `admin`, which AOS-CX ships with an empty password and does not let you delete, is locked
  too;
- SSH password authentication is off (`no ssh password-authentication`).

Neither account can log in with a password, over SSH, on the console or on the HTTPS REST API.
Your device password is not used on AOS-CX. For console access, log in by SSH and set a password
on your account first. See [Your Login on Nodes](../../architecture/personal-accounts.md#aruba-aos-cx).

USB ZTP, which would keep the configuration off the lab network, needs a patched image and is
tracked in [#690](https://github.com/bwks/sherpa/issues/690).

## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Console"

    ```
    sherpa console <node-name>
    ```

## Notes

- Approximate time for the system to be ready: `1 minute`
