# Client

The `sherpa` CLI runs on the machines you work from and talks to a Sherpa server. Builds are
published for these platforms on each [release](https://github.com/bwks/sherpa/releases):

| Platform | Release asset |
| -------- | ------------- |
| Windows, x86_64 | `sherpa-x86_64-pc-windows-msvc.zip` |
| Linux, x86_64 | `sherpa-x86_64-unknown-linux-gnu.tar.gz` |
| macOS, Intel | `sherpa-x86_64-apple-darwin.tar.gz` |
| macOS, Apple silicon | `sherpa-aarch64-apple-darwin.tar.gz` |

Install the same version as the server. The [server install script](automated.md) installs the
CLI on the server itself; other machines need it installed as shown below. To update an existing
install, see [Updating the client](../update/client.md).

## Windows

The install script, `sherpa_client_install.ps1`, downloads the release's Windows build and
installs `sherpa.exe` to `$HOME\.sherpa\bin\`. It needs no administrator rights and PowerShell 5.1
or later.

Download the script and run it from PowerShell:

```
Invoke-WebRequest -UseBasicParsing -OutFile sherpa_client_install.ps1 `
  -Uri https://raw.githubusercontent.com/bwks/sherpa/refs/heads/main/scripts/sherpa_client_install.ps1
powershell -ExecutionPolicy Bypass -File .\sherpa_client_install.ps1
```

With no options the script installs the latest release, which it looks up with the GitHub API
(`releases/latest`, so it never picks a pre-release). To install a given release, which should
be the server's, add `-Version`:

```
powershell -ExecutionPolicy Bypass -File .\sherpa_client_install.ps1 -Version v0.6.0
```

To use the script as it was at a release rather than the one on `main`, download it from the
release's tag. It still installs the latest release unless `-Version` is given:

```
Invoke-WebRequest -UseBasicParsing -OutFile sherpa_client_install.ps1 `
  -Uri https://raw.githubusercontent.com/bwks/sherpa/v0.6.0/scripts/sherpa_client_install.ps1
powershell -ExecutionPolicy Bypass -File .\sherpa_client_install.ps1 -Version v0.6.0
```

### Execution policy

Windows refuses to run `.ps1` files under its default execution policy on desktop editions, so
`.\sherpa_client_install.ps1` on its own fails with "running scripts is disabled on this
system". `powershell -ExecutionPolicy Bypass -File ...` lifts the policy for that one PowerShell
process only, and changes no setting on the machine. Where the policy is set by Group Policy,
`-ExecutionPolicy` cannot override it; ask your administrator. From PowerShell 7, `pwsh` takes the
same options as `powershell`.

### What the script does

1. Finds the version to install: `-Version`, or the latest release. A version without the
   leading `v`, such as `0.6.0`, is accepted.
2. If `sherpa.exe` is already installed, asks `Replace with <version>? [Y/n]`. Answering anything
   but `Y`, `y`, `yes`, `Yes` or Enter stops it. A first install asks nothing.
3. Downloads `sherpa-x86_64-pc-windows-msvc.zip` from the release and copies `sherpa.exe` to
   `$HOME\.sherpa\bin\sherpa.exe`, replacing an existing one.
4. Adds `$HOME\.sherpa\bin` to your user `PATH` if it is not there already. The machine `PATH`
   is not touched.
5. Runs `sherpa.exe --version` to check the install.

`$HOME\.sherpa` is also where the CLI keeps its configuration, login token and trusted
certificates.

### Check the install

The `PATH` change applies to terminals opened after the install. Open a new terminal and run:

```
sherpa --version
```

It prints the version, such as `sherpa 0.6.0`.

## Linux and macOS

There is no install script for the client on Linux and macOS. Download the archive for your
platform from the release, extract `sherpa` and install it into a folder on your `PATH`. Set
`TARGET` to the platform's name from the table above: `x86_64-unknown-linux-gnu`,
`x86_64-apple-darwin` or `aarch64-apple-darwin`.

Install the latest release:

```
TARGET=x86_64-unknown-linux-gnu
cd "$(mktemp -d)"
curl -fsSLO "https://github.com/bwks/sherpa/releases/latest/download/sherpa-$TARGET.tar.gz"
tar -xzf "sherpa-$TARGET.tar.gz"
sudo mkdir -p /usr/local/bin
sudo install -m 755 sherpa /usr/local/bin/sherpa
```

Install a given release, which should be the server's, by naming it in the download URL:

```
curl -fsSLO "https://github.com/bwks/sherpa/releases/download/v0.6.0/sherpa-$TARGET.tar.gz"
```

The archive holds the one file, `sherpa`. To install without `sudo`, put it in a folder of your
own that is on your `PATH` instead, such as `~/.local/bin`.

Check the install:

```
sherpa --version
```

## Connect to a server

1. Run [`sherpa init`](../../command-reference.md#sherpa-init) and give it the server's address
   and port (`3030` by default). It writes the
   [client configuration](../../configuration/sherpa.md#client-configuration),
   `~/.sherpa/config/sherpa.toml`. The `--server-url` flag or `SHERPA_SERVER_URL` overrides the
   address for one command; see [Global Flags](../../command-reference.md#global-flags).
2. Run [`sherpa login`](../../command-reference.md#sherpa-login) with the account the server's
   administrator gave you.
3. The first time the CLI connects to a server with Sherpa's self-signed certificate, it shows
   the certificate's SHA-256 fingerprint and asks whether to trust it. Compare it with the
   server's [certificate fingerprint](automated.md#certificate-fingerprint) before you answer;
   see [Certificate Commands](../../command-reference.md#certificate-commands).
