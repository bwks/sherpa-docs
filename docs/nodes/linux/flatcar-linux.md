# Flatcar Linux

## AppArmour

```
sudo mkdir /var/lib/libvirt/sherpa/
sudo sh -c 'echo "  # For ignition files" >> /etc/apparmor.d/abstractions/libvirt-qemu'
sudo sh -c 'echo "  /var/lib/libvirt/sherpa/** r," >> /etc/apparmor.d/abstractions/libvirt-qemu'
sudo systemctl restart libvirtd.service
```

## SELINUX

```
sudo mkdir /var/lib/libvirt/flatcar-linux/
sudo semanage fcontext -a -t virt_content_t "/var/lib/libvirt/flatcar-linux/flatcar-linux1"
sudo restorecon -R "/var/lib/libvirt/flatcar-linux/flatcar-linux1"
sudo systemctl restart libvirtd.service
```
