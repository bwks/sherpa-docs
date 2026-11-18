# Build the SONiC Container Image

The `sonic_linux` container runs upstream's `docker-sonic-vs` image. No registry publishes a
current one, so it is built from the archive SONiC's build pipeline publishes for each branch,
with one change: `sudo`, which the image lacks and the SONiC CLI needs.

Tested with the `202511` branch, build `1278069`, on a Sherpa server with Docker.

## Download

The build id pins the archive. Upstream expires old builds, so a pinned id stops working at some
point; then pick a newer build of the branch.

```
mkdir -p /var/tmp/sonic-build && cd /var/tmp/sonic-build
curl -sSL -o docker-sonic-vs.gz \
  "https://sonic-build.azurewebsites.net/api/sonic/artifacts?branchName=202511&platform=vs&target=target/docker-sonic-vs.gz&buildId=1278069"
sha256sum docker-sonic-vs.gz
```

Build `1278069` has the SHA-256 checksum
`8103c170ac1ab180ce7c63994b6b65a7402672f65be484c0f282f5d5d91d805c`.

## Add `sudo`

The archive is a `docker save` archive tagged `docker-sonic-vs:latest`. Load it, add `sudo` in
one build step, and tag the result with the version:

```
docker load -i docker-sonic-vs.gz
printf 'FROM docker-sonic-vs:latest\nRUN apt-get update -qq && apt-get install -y -qq --no-install-recommends sudo && rm -rf /var/lib/apt/lists/*\n' \
  | docker build -t docker-sonic-vs:202511 -
docker rmi docker-sonic-vs:latest
```

The step needs internet access and adds about 4 MB. Without it, your login on the node has no
root access, and `config …` commands do not work.

## Import

Save the image to an archive the Sherpa server can read, and import it:

```
docker save docker-sonic-vs:202511 -o /var/tmp/sonic-build/docker-sonic-vs-202511.tar
chmod 755 /var/tmp/sonic-build && chmod 644 /var/tmp/sonic-build/docker-sonic-vs-202511.tar
sherpa server image import \
  --src /var/tmp/sonic-build/docker-sonic-vs-202511.tar \
  --model sonic_linux \
  --kind container \
  --version 202511 \
  --default
```

The archive and `docker-sonic-vs.gz` can be deleted afterwards. The image is about 1.8 GB in
Docker.

## Build From Source

The image is also a target of a SONiC source build (`make target/docker-sonic-vs.gz`). That
build needs about 300 GB of free disk; it is not tested with Sherpa. Add `sudo` to its result as
above.
