# Supported Devices

## Device Support Matrix

- ✅ - Working
- 🚧 - Planned
- ⚠️ - Partially Working

| Vendor    | Model          | Device Type      | Kind      | Minimum Tested Version | Status | ZTP Method     |
| --------- | -------------- | ---------------- | --------- | ---------------------- | ------ | -------------- |
| Arista    | vEOS           | arista_veos      | VM        | 4.32.2f                | ✅     | TFTP           |
| Arista    | cEOS           | arista_ceos      | Container | 4.32.2f                | 🚧     | TBA            |
| Aruba     | AOS-CX         | aruba_aoscx      | VM        | 10.07                  | ✅     | TFTP           |
| Cisco     | ASAv           | cisco_asav       | VM        | 9.20.2                 | ✅     | CDROM          |
| Cisco     | CSR 1000v      | cisco_csr1000v   | VM        | 17.03.08a              | ✅     | CDROM          |
| Cisco     | Catalyst 8000v | cisco_cat8000v   | VM        | 17.13.01a              | ✅     | CDROM          |
| Cisco     | Catalyst 9000v | cisco_cat9000v   | VM        | 17.12.01               | ✅     | CDROM          |
| Cisco     | XRv 9000       | cisco_iosxrv9000 | VM        | 7.11.1                 | ✅     | CDROM          |
| Cisco     | Nexus 9300v    | cisco_nexus9300v | VM        | 10.4.2.f               | ✅     | CDROM          |
| Cisco     | IOSv           | cisco_iosv       | VM        | 159-3.m8               | ✅     | Disk           |
| Cisco     | IOSv L2        | cisco_iosvl2     | VM        | 20200920               | ✅     | Disk           |
| Juniper   | vRouter        | juniper_vrouter  | VM        | 23.4R2-S2.1            | ✅     | CDROM          |
| Juniper   | vSwitch        | juniper_vswitch  | VM        | 23.4R2-S2.1            | ✅     | CDROM          |
| Juniper   | vSRXv3         | juniper_vsrxv3   | VM        | 23.2R2.21              | ✅     | CDROM          |
| Juniper   | vEvolved       | juniper_vevolved | VM        | 23.4R2-S2.1            | ✅     | TFTP           |
| Nokia     | SR Linux       | nokia_srlinux    | Container | 24.10.1                | 🚧     | TBA            |
| SONiC     | Sonic Linux    | sonic_linux      | VM        | 25051122               | ✅     | TFTP           |
| Nvidia    | Cumulus Linux  | cumulus_linux    | VM        | 5.9.2                  | ✅     | USB            |
| Microsoft | FlatCar Linux  | flatcar_linux    | VM        | 3975.2.2               | ✅     | Ignition       |
| Microsoft | Windows Server | windows_server   | VM        | 2024                   | ✅     | CloudBase-Init |
| Alpine    | Alpine Linux   | alpine_linuxv    | VM        | 3.22.2                 | ✅     | Cloud-Init     |
| Alpine    | Alpine Linux   | alpine_linuxc    | Container | 3.22.2                 | 🚧     | TBA            |
| Canonical | Ubuntu Linux   | ubuntu_linux     | VM        | 24.04                  | ✅     | Cloud-Init     |
| Debian    | Debian Linux   | debian_linux     | VM        | 10.0                   | 🚧     | Cloud-Init     |
| RedHat    | Fedora Linux   | fedora_linux     | VM        | 40-1.14                | ✅     | Cloud-Init     |
| RedHat    | RedHat Linux   | redhat_linux     | VM        | 9.0.0                  | 🚧     | Cloud-Init     |
| Centos    | Centos Linux   | centos_linux     | VM        | 9.0.0                  | 🚧     | Cloud-Init     |
| Rocky     | Rocky Linux    | rocky_linux      | VM        | 9.0.0                  | 🚧     | Cloud-Init     |
| Alma      | Alma Linux     | alma_linux       | VM        | 9.0.0                  | 🚧     | Cloud-Init     |
| Suse      | OpenSuse Linux | opensuse_linux   | VM        | 9.0.0                  | 🚧     | Cloud-Init     |
| Suse      | Suse Linux     | suse_linux       | VM        | 9.0.0                  | 🚧     | Cloud-Init     |
| BSD       | Free BSD       | free_bsd         | VM        | 14.2                   | 🚧     | Cloud-Init     |
| BSD       | Open BSD       | open_bsd         | VM        | 10.8                   | 🚧     | Cloud-Init     |
| BSD       | Net BSD        | net_bsd          | VM        | 10.1                   | 🚧     | Cloud-Init     |
| BSD       | DragonFly BSD  | dragonfly_bsd    | VM        | 6.4.0                  | 🚧     | Cloud-Init     |
