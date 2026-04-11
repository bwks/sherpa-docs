# Docker

## Check Docker is Running

```bash
sudo systemctl status docker
```

## Start Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Permission Denied

If you get permission errors when running Docker commands, ensure your user is in the `docker` group.

```bash
sudo usermod -aG docker $USER
```

Log out and back in for the group change to take effect.

## Image Pull Failures

If container image pulls fail, check network connectivity and Docker Hub access.

```bash
docker pull hello-world
```

If behind a proxy, configure Docker's proxy settings in `/etc/docker/daemon.json` or via systemd drop-in.

## Container Not Starting

Check container logs for errors.

```bash
docker logs <container_name>
```

## Prune Unused Resources

To reclaim disk space from unused containers, images, and volumes:

```bash
docker system prune -a
```

!!! warning

    This removes all stopped containers, unused networks, dangling images, and build cache.
