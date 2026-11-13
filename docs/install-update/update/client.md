# Client

Update the `sherpa` CLI on every client whenever you update the server, to the server's version.
A CLI whose version differs from the server's prints a warning when it connects:

```
WARNING: Version mismatch - client: 0.5.30, server: 0.6.0
```

The CLI still runs, but a release that changes what the server sends breaks an older CLI. 0.6.0
is such a release; see [Updating to 0.6.0](sherpa.md#updating-to-060). Check the server's
version with `sherpad --version` on the server, and the client's with `sherpa --version`.

Installing for the first time is described in [Client](../install/client.md).

## Windows

Run the [install script](../install/client.md#windows) with `-Update`. Download it again first, so
that you run the current one:

```
Invoke-WebRequest -UseBasicParsing -OutFile sherpa_client_install.ps1 `
  -Uri https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_client_install.ps1
powershell -ExecutionPolicy Bypass -File .\sherpa_client_install.ps1 -Update -Version v0.6.0
```

Name the server's version with `-Version`. Without it, `-Update` installs the latest release,
which is newer than the server if the server has not been updated to it.

With `-Update` the script:

- stops with `No existing installation found` if there is no `$HOME\.sherpa\bin\sherpa.exe`; run
  it without `-Update` to install;
- does nothing if the installed version is already the one asked for;
- otherwise replaces `sherpa.exe` without asking, and leaves `PATH` as it is.

Running the script without `-Update` also replaces an existing install, after asking
`Replace with <version>? [Y/n]`.

Close every running `sherpa` command first, such as a `sherpa ssh` or `sherpa console` session.
Windows does not let a running program's file be replaced, so the copy fails, the script stops
with an `Extraction failed` error and the installed version stays as it was. Run it again once
`sherpa` has exited.

## Linux and macOS

Replace the `sherpa` binary with the new release's, as in
[Linux and macOS](../install/client.md#linux-and-macos), naming the server's version in the
download URL:

```
TARGET=x86_64-unknown-linux-gnu
cd "$(mktemp -d)"
curl -fsSLO "https://github.com/bwks/sherpa/releases/download/v0.6.0/sherpa-$TARGET.tar.gz"
tar -xzf "sherpa-$TARGET.tar.gz"
sudo install -m 755 sherpa /usr/local/bin/sherpa
sherpa --version
```

Install it to the folder the old one is in; `command -v sherpa` shows where that is. A running
`sherpa` command keeps running the old version until it exits.

The CLI's configuration, login and trusted certificates, in `~/.sherpa` (`$HOME\.sherpa` on
Windows), are kept across updates. A release that ends existing logins says so in its update
notes, such as [Updating to 0.5.23](sherpa.md#updating-to-0523).
