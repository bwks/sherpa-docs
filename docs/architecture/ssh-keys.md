# SSH Keys

You need at least one SSH public key registered with your Sherpa user account to start labs.
`sherpa up` and node redeploys stop with an error until you add one. Lab nodes use your keys
for your [personal account](personal-accounts.md).

Only the public key is sent to the server. Keep the private key on your workstation or in your
SSH agent.

## Generate a Key

Ed25519 keys are short and widely supported. Use RSA (`-t rsa -b 4096`) only if a device in
your labs cannot use Ed25519.

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

Administrators can manage another user's keys with `--user <username>`, and can add keys when
creating a user with `sherpa server user create --ssh-key`.

`sherpad init` also asks for a key when it creates the first user account, or takes it from
`SHERPA_USER_SSH_KEY`.

## Supported Keys

Keys must be in OpenSSH format, `<type> <key data> [comment]`, with one of these types:
`ssh-ed25519`, `ssh-rsa`, `ecdsa-sha2-nistp256`, `ecdsa-sha2-nistp384`, `ecdsa-sha2-nistp521`
or `ssh-dss`. Adding the same key twice is refused, even with a different comment.
