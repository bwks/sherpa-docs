# Automated

Sherpa can be installed via a convenience installation script.

!!! danger

    Piping to sudo can be dangerous. You are strongly encouraged to review the below script
    before executing the below command.

`sudo` privileges are requried. Run the following command to start the installation.

```
curl https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_install.sh | sudo bash
```

No database server is installed: `sherpad` keeps its data in an embedded database,
`/opt/sherpa/db/sherpa.sqlite`, which `sherpad init` creates. See [Database](../../architecture/database.md).

To upgrade a server older than 0.5.0, use the [update script](../update/sherpa.md#updating-to-050)
instead. The install script refuses to run while the old `sherpa-db` SurrealDB container exists,
because the update script has to move its data first.

## Transparent Hugepages

The script sets the host's transparent hugepages to `madvise`, so QEMU can back VM memory with
2 MiB pages. It sets it for the running system and adds a boot rule,
`/etc/tmpfiles.d/sherpa-thp.conf`, so it stays set after a reboot. A host already set to `always`
is left as it is, and a kernel without transparent hugepages is skipped with a warning.

`madvise` gives huge pages only to programs that ask for them, such as QEMU. To go back to the
kernel's default, delete `/etc/tmpfiles.d/sherpa-thp.conf` and reboot. The uninstall script
deletes it too.
