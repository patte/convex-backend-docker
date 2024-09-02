# convex-backend-docker

This is an inofficial docker image for [convex-backend](https://github.com/get-convex/convex-backend).

The Dockerfile clones the repo from github at the specified release tag. A github action builds the image and pushes it to [ghcr.io](https://github.com/patte/convex-backend-docker/pkgs/container/convex-backend-docker).


```bash
docker pull ghcr.io/patte/convex-backend-docker:latest # or tag :precompiled-2024-09-02-64b5093
```

> [!WARNING]
> Sporadic updates only
> 
> Building the `linux/arm64` image does exceed the timeout of the free github runner (6h). A local runner is used to build the image (~16min on MacBook Air M2, with bad internet). Until a better solution is found, there will only be sporadic updates of the image, as keeping the local runner running is obviously not an option.
> `amd64` builds are done on the default runner.


## Usage

### Generate keys
    
```bash
export INSTANCE_SECRET=$(docker run --rm ghcr.io/patte/convex-backend-docker generate_secret) && \
export ADMIN_KEY=$(docker run --rm ghcr.io/patte/convex-backend-docker generate_key $INSTANCE_NAME $INSTANCE_SECRET | awk '/Admin Key:/{getline; print}') &&  \
export INSTANCE_NAME=flying-fox-123
```

### Run
```bash
docker run -e INSTANCE_NAME=$INSTANCE_NAME -e INSTANCE_SECRET=$INSTANCE_SECRET ghcr.io/patte/convex-backend-docker
```

### Docker Compose
docker-compose.yml
```yaml
services:
  convex-backend:
    image: ghcr.io/patte/convex-backend-docker:latest
    # image: convex-backend
    env_file:
      - .env
    ports:
      - "3210:3210"
      - "3211:3211"
    volumes:
      - ./local/convex-backend/:/app
    command: [ "convex-local-backend", "--instance-name", "$CONVEX_INSTANCE_NAME", "--instance-secret", "$CONVEX_INSTANCE_SECRET" ]
```

.env
```bash
echo "CONVEX_INSTANCE_NAME=$INSTANCE_NAME"
echo "CONVEX_INSTANCE_SECRET=$INSTANCE_SECRET"
echo "CONVEX_ADMIN_KEY=$ADMIN_KEY"

CONVEX_INSTANCE_NAME=flying-fox-123
CONVEX_INSTANCE_SECRET=4fd28a3d07b61dcfc71518f8fae8c036e4110e47fef40195ce805c110408cf21
CONVEX_ADMIN_KEY=flying-fox-123|01b832d9fd0604d997b78fcbe469d7b5ecca67edd02edd1f037f42a58275b556c74ad32fb72af4a17d5bbd01dcd86c3bc5
```

## Build

```bash
export LATEST_RELEASE_TAG=$(curl -s https://api.github.com/repos/get-convex/convex-backend/releases/latest | grep "tag_name" | cut -d\" -f4) && echo $LATEST_RELEASE_TAG

docker build -t convex-backend . --build-arg RELEASE_TAG=$LATEST_RELEASE_TAG
```


### GitHub Actions
The [docker-build](.github/workflows/docker-build.yml) action builds the image and pushes it to ghcr.io.
The following architectures are built: `linux/amd64`, `linux/arm64`

#### Local runner
For `linux/arm64` the build takes longer than the timeout of 6 hours on the default action runner at the time of writing. `docker-compose.yml` is used to start a local github action runner to help speed up the build.

The github action is [set to use](.github/workflows/docker-build.ymlL24) the local runner for `linux/arm64` and the default runner for `linux/amd64`. Get a runner key from: github.com/your/repo/settings/actions/runners/new.

```bash
cp .env.example .env # adapt .env
docker compose up -d
docker compose logs -f
```