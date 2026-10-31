# Container

A generic container allows for the use of container models that are not natively defined within Sherpa.

### Import

Pull the image through Sherpa, giving the full image reference:

```
sherpa server image pull --model generic_container --repo nginx:1.29.4-perl
```

Sherpa records the version (`1.29.4-perl`) and the repo it was pulled from (`nginx`). A node with
that version runs that repo, unless it sets `image` in the manifest. An image pulled only with
the `docker` CLI is not known to Sherpa, so a lab cannot use it.

Sherpa tells generic images apart by version, so two images with the same tag (such as
`nginx:latest` and `redis:latest`) share one entry, holding the repo pulled last. Set `image` on
each node to pick between them.

## Default Node Parameters

| Property             | Value     |
| -------------------- | --------- |
| Kind                 | Container |
| CPU                  | 1         |
| RAM                  | 1GB       |
| ZTP Method           | Volume    |
| Management Interface | eth0      |
| Interface Driver     | macvlan   |

## Example Manifest

```toml
name = "generic-container"

[[nodes]]
name = "dev01"
model = "generic_container"
image = "nginx"
version = "1.29.4-perl"
```


## Node Access

=== "SSH"

    ```
    sherpa ssh <node-name>
    ```

=== "Docker"

    ```
    docker exec -it <node-name>-<lab-id> sh
    ```

## Notes
