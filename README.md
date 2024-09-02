# convex-backend-docker

This is an inofficial docker image for [convex-backend](https://github.com/get-convex/convex-backend).

The Dockerfile clones the repo from github at the specified release tag. A github action builds the image and pushes it to ghcr.io.

> [!WARNING] Sporadic updates
> Building the `linux/arm64` image does exceed the timeout of the free github runner (6h). A local runner is used to build the image (~16min on MacBook Air M2, with bad internet). Until a better solution is found, there will only be sporadic updates of the image, as keeping the local runner running is obviously not an option.
> `amd64` builds are done on the default runner.

## Build

```bash
export LATEST_RELEASE_TAG=$(curl -s https://api.github.com/repos/get-convex/convex-backend/releases/latest | grep "tag_name" | cut -d\" -f4) && echo $LATEST_RELEASE_TAG

docker build -t convex-backend . --build-arg RELEASE_TAG=$LATEST_RELEASE_TAG
```

## Generate keys
    
```bash
# INSTANCE_SECRET
docker run --rm convex-backend generate_secret
# 4fd28a3d07b61dcfc71518f8fae8c036e4110e47fef40195ce805c110408cf21

# ADMIN_KEY
docker run --rm convex-backend generate_key your_instance_name your_instance_secret
# flying-fox-123|01b832d9fd0604d997b78fcbe469d7b5ecca67edd02edd1f037f42a58275b556c74ad32fb72af4a17d5bbd01dcd86c3bc5
```

## Run

```bash
docker run -e INSTANCE_NAME=your_instance_name -e INSTANCE_SECRET=your_instance_secret convex-local-backend
# docker run --rm convex-backend convex-local-backend --instance-name flying-fox-123 --instance-secret 4fd28a3d07b61dcfc71518f8fae8c036e4110e47fef40195ce805c110408cf21
```


### Docker Compose
docker-compose.yml
```yaml
services:
  convex-backend:
    image: ghcr.io/patte/convex-backend-docker:latest
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
CONVEX_INSTANCE_NAME=flying-fox-123
CONVEX_INSTANCE_SECRET=4fd28a3d07b61dcfc71518f8fae8c036e4110e47fef40195ce805c110408cf21
```

## GitHub Actions
The [docker-build](.github/workflows/docker-build.yml) action builds the image and pushes it to ghcr.io.
The following architectures are built:
- `linux/amd64`
- `linux/arm64`

### Local runner
For `linux/arm64` the build takes longer than the timeout of 6 hours on the default action runner at the time of writing. `docker-compose.yml` is used to start a local github action runner to help speed up the build.

The github action is [set to use](.github/workflows/docker-build.ymlL24) the local runner for `linux/arm64` and the default runner for `linux/amd64`.

```bash
cp .env.example .env # adapt .env
docker compose up -d
docker compose logs -f
```