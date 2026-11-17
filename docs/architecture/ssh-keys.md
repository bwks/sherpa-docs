# SSH Keys

You need at least one SSH public key registered with your Sherpa user account to start labs.
`sherpa up` and node redeploys stop with an error until you add one. Lab nodes use your keys
for [your login](personal-accounts.md).

Only the public key is sent to the server. Keep the private key on your workstation or in your
SSH agent.

Your registered keys are the only keys a node built by Sherpa trusts. Sherpa has no key of its
own, and writes no key to your lab folder: `ssh`, `sherpa ssh` and provisioners use the keys in
your SSH agent or your default key files (see [SSH](ssh.md#logging-in-to-nodes)).

## Generate a Key

Ed25519 keys are short and widely supported. If your labs have network devices that take RSA
only, register an RSA key as well; see [Which Key Type](#which-key-type).

=== "Linux and macOS"

    ```
    ssh-keygen -t ed25519 -C "you@example.com"
    ```

    Accept the default location, `~/.ssh/id_ed25519`, and choose a passphrase. The public key
    is written to `~/.ssh/id_ed25519.pub`.

=== "Windows"

    In PowerShell, with the OpenSSH client that ships with Windows 10 and later:

    ```
    ssh-keygen -t ed25519 -C "you@example.com"
    ```

    Accept the default location, `C:\Users\<you>\.ssh\id_ed25519`, and choose a passphrase.
    The public key is written to `C:\Users\<you>\.ssh\id_ed25519.pub`.

If you already have a key pair, use its existing `.pub` file.

## Which Key Type

Linux, BSD and Windows nodes take every key you register. Many network devices take only some
types, so a lab needs a key each device takes:

- Cisco IOS, IOS XE, IOS XR and ISE take RSA only.
- Cisco NX-OS takes ECDSA or RSA, not Ed25519.
- PAN-OS and MikroTik take Ed25519 or RSA, not ECDSA.

RSA is the only type every device takes. To cover all of them, keep an Ed25519 key and add an
RSA key:

```
ssh-keygen -t rsa -b 4096 -C "you@example.com"
sherpa server user ssh-key add ~/.ssh/id_rsa.pub
```

Your SSH client offers each of your keys in turn, so both work without extra settings.
[Your Login on Nodes](personal-accounts.md#network-devices) lists the key types and number of keys
each device takes.

## Register a Key

=== "CLI"

    Pass the public key file, or the key itself in quotes:

    ```
    sherpa server user ssh-key add ~/.ssh/id_ed25519.pub
    ```

    List your keys and their fingerprints:

    ```
    sherpa server user ssh-key list
    ```

    Remove a key by its file, the key itself, or its `SHA256:` fingerprint:

    ```
    sherpa server user ssh-key remove SHA256:/UpBoWzMiq6/+/wzQIGDT2VxOLzg/LUTfKhc0x+ktEs
    ```

=== "Web UI"

    Open the **Profile** page, paste the contents of the `.pub` file into **Add SSH Public
    Key** and save.

Only you can add a key to your account, administrators included. `sherpa server user create`
takes no keys, so a new user adds their own after their first login, and cannot start a lab
until they have. Administrators can still list and remove another user's keys, with
`--user <username>` or the delete button on the user's page in the web UI. The web page has no
form to add a key for someone else.

Your password on lab nodes is your [device password](device-password.md), set on the same
**Profile** page or with `sherpa server user device-password`.

`sherpad init` also asks for a key when it creates the first user account, or takes it from
`SHERPA_USER_SSH_KEY`.

## Supported Keys

Keys must be in OpenSSH format, `<type> <key data> [comment]`, on one line, with one of these
types: `ssh-ed25519`, `ssh-rsa`, `ecdsa-sha2-nistp256`, `ecdsa-sha2-nistp384`,
`ecdsa-sha2-nistp521`, or the security key types `sk-ssh-ed25519@openssh.com` and
`sk-ecdsa-sha2-nistp256@openssh.com`. The key data must decode as a key of that type. DSA keys
(`ssh-dss`), which OpenSSH no longer supports, are refused. Adding the same key twice is
refused, even with a different comment.
