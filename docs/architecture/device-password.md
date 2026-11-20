# Device Password

Your device password is your password on lab nodes. It is the password of
your login on every node Sherpa provisions for you, and of the fixed vendor accounts some devices
have, such as `admin`. Aruba AOS-CX is the one exception: you log in there by key only (see
[Your Login on Nodes](personal-accounts.md#aruba-aos-cx)). It is yours alone: it is not your Sherpa login password, and nobody else,
administrators included, can set, read or clear it.

!!! Warning "Set it before your first lab"

    `sherpa up` and node redeploys need a device password. Every user sets one before their
    first lab.

## Set It

You need your Sherpa login password to set it. The device password must differ from your login
password.

=== "CLI"

    ```
    sherpa server user device-password
    ```

    The command asks for your Sherpa login password, then the new device password twice. It
    takes no arguments or flags: passwords are always typed at the prompt, as for
    `sherpa server user passwd`, and `SHERPA_USER_PASSWORD` is not used.

=== "Web UI"

    Open the **Profile** page. Under **Device Password**, enter your Sherpa login password and
    the new device password twice, then select **Set Device Password**.

Setting it again replaces it. A new device password applies to nodes you create or redeploy
afterwards; running nodes keep the one they started with. Sherpa never shows the device password
again, so a forgotten one is replaced, not recovered.

The built-in `admin` account cannot start labs, so it has no device password.

## Check It

`sherpa server user info` shows `Device password: set` or `not set`, and so does the **Profile**
page. Administrators see each user's state in `sherpa server user list`. The API returns only
`device_password_set`, never the password.

## Rules

One rule applies to every node model, so a device password that is accepted works on whatever
you start next:

- 12 to 20 characters.
- Letters, digits and `! @ _ - + .` only, starting with a letter or a digit. No spaces, quotes,
  backslashes or other symbols.
- At least one lowercase letter, one uppercase letter, one digit and one of `! @ _ - + .`.
- It does not contain your username or `cisco`, in any case.
- No character three times in a row.

A password that breaks a rule is refused with a message naming the rule. The rule is what the
strictest devices accept: Windows takes at most 20 characters; Cisco Firepower Threat Defense,
PAN-OS, ISE, Windows and NX-OS check its strength; Firepower Threat Defense refuses a character
three times in a row, and Cisco devices refuse `cisco`.

## Storage

The server stores the device password encrypted with the database key, bound to your user
record, so a database backup holds only ciphertext. See [Database](database.md).
