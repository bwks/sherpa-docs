#!/usr/bin/env bash
# Install the tools for the Kubernetes example on the util node: kubectl, talosctl, the
# kubelogin plugin (kubectl oidc-login), the Vault CLI and the Cilium CLI. Each download is
# pinned and checked against its published SHA-256.
# Sherpa runs this as root on the node's first boot (manifest startup_scripts).
set -euo pipefail

# Talos 1.14 deploys Kubernetes 1.37.1; kubectl matches it.
KUBECTL_VERSION="v1.37.1"
KUBECTL_SHA256="65691ff77eb6fa44c908b77a1082c9f092c3b9733b5cefabec0d1104890e21a8"
TALOSCTL_VERSION="v1.14.4"
TALOSCTL_SHA256="0a69e3f9b682c5cd844b78dae305f6056ceb86c5fcc6913dcea78c527ed97cee"
KUBELOGIN_VERSION="v1.36.4"
KUBELOGIN_SHA256="9e8baeb4905d35a301304af2548324997add512fe94ab20e65993d167212bf85"
VAULT_VERSION="1.21.4"
VAULT_SHA256="889b681990fe221b884b7932fa9c9dd0ee9811b9349554f1aa287ab63c9f3dae"
CILIUM_CLI_VERSION="v0.20.2"
CILIUM_CLI_SHA256="b7224a62bfed0e84f1a84567d274fefc5017df76a936e067c42012bb7fc30856"

# On disk: /tmp is in memory, and the Vault binary alone is several hundred MB.
WORK_DIR="$(mktemp -d -p /var/tmp)"
trap 'rm -rf "${WORK_DIR}"' EXIT

# Download a URL into the work directory and check its SHA-256; print the file's path.
download() {
    local url="$1" sha256="$2"
    local file="${WORK_DIR}/${url##*/}"
    curl -fsSL --retry 5 --retry-connrefused --connect-timeout 20 -o "${file}" "${url}"
    echo "${sha256}  ${file}" | sha256sum --check --status
    echo "${file}"
}

file="$(download "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" "${KUBECTL_SHA256}")"
install -m 0755 "${file}" /usr/local/bin/kubectl

file="$(download "https://github.com/siderolabs/talos/releases/download/${TALOSCTL_VERSION}/talosctl-linux-amd64" "${TALOSCTL_SHA256}")"
install -m 0755 "${file}" /usr/local/bin/talosctl

file="$(download "https://github.com/int128/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin_linux_amd64.zip" "${KUBELOGIN_SHA256}")"
python3 -m zipfile -e "${file}" "${WORK_DIR}/kubelogin"
install -m 0755 "${WORK_DIR}/kubelogin/kubelogin" /usr/local/bin/kubectl-oidc_login

file="$(download "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" "${VAULT_SHA256}")"
python3 -m zipfile -e "${file}" "${WORK_DIR}/vault"
install -m 0755 "${WORK_DIR}/vault/vault" /usr/local/bin/vault

file="$(download "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz" "${CILIUM_CLI_SHA256}")"
tar -xzf "${file}" -C "${WORK_DIR}"
install -m 0755 "${WORK_DIR}/cilium" /usr/local/bin/cilium

kubectl version --client
talosctl version --client
kubectl oidc-login --version
vault version
cilium version --client
