# convex-backend-docker

This is an inofficial docker image for [convex-backend](https://github.com/get-convex/convex-backend).

The Dockerfile clones the repo from github at the specified release tag. A github action builds the image and pushes it to [ghcr.io](https://github.com/patte/convex-backend-docker/pkgs/container/convex-backend).


```bash
docker pull ghcr.io/patte/convex-backend:latest # or tag :precompiled-2024-09-02-64b5093
```

> [!WARNING]
> Sporadic updates only
> 
> Building the `linux/arm64` image does exceed the timeout of the free github runner (6h). A local runner is used to build the image for `linux/arm64` (~16min - MacBook Air M2, bad internet). Until a better solution is found, there will only be irregular updates, as keeping the local runner up is obviously not an option.
> `amd64` builds are done on the default runner `ubuntu-latest`.


## Usage
See: [self-hosting](https://github.com/get-convex/convex-backend/blob/main/SELFHOSTING.md)

### bin
```bash
generate_secret
generate_key KEY_NAME SECRET
convex-local-backend --instance-name INSTANCE_NAME --instance-secret INSTANCE_SECRET
```

### Generate keys
    
```bash
export INSTANCE_SECRET=$(docker run --rm ghcr.io/patte/convex-backend generate_secret) && \
export ADMIN_KEY=$(docker run --rm ghcr.io/patte/convex-backend generate_key $INSTANCE_NAME $INSTANCE_SECRET | awk '/Admin Key:/{getline; print}') &&  \
export INSTANCE_NAME=flying-fox-123
```

### Run
```bash
docker run \
  -v ./local:/app \
  -p 3210:3210 -p 3211:3211 \
  ghcr.io/patte/convex-backend convex-local-backend \
  --instance-name $INSTANCE_NAME --instance-secret $INSTANCE_SECRET
```

### Docker Compose
docker-compose.yml
```yaml
services:
  convex-backend:
    image: ghcr.io/patte/convex-backend:latest
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
echo "CONVEX_ADMIN_KEY=\"$ADMIN_KEY\""

CONVEX_URL=http://127.0.0.1/3210
CONVEX_INSTANCE_NAME=flying-fox-123
CONVEX_INSTANCE_SECRET=bfec6e5e65f70852f9276720310675cb50c1e1a238a160b4005a32d42f9a69af
CONVEX_ADMIN_KEY="flying-fox-123|012e37a0303910b9375cabf2859920666e24917de9f614ec936cfbb9d584861c8970d7e06c57b7a2333d5d085270400c06"
```

### TypeScript
```bash
source .env
cd your_project
bun install
bun convex dev --url $CONVEX_URL --admin-key $CONVEX_ADMIN_KEY
```

package.json
```json
{
  "scripts": {
    "dev:backend": "source .env && convex dev --url $CONVEX_URL --admin-key $CONVEX_ADMIN_KEY"
  }
}
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
For `linux/arm64` the build takes longer than the timeout of 6 hours on the free github action runner (at the time of writing). `docker-compose.yml` is used to start a local github action runner to speed up the build.

The github action is [set to use](.github/workflows/docker-build.ymlL24) the local runner for `linux/arm64` and the default runner for `linux/amd64`. Get a runner key from: github.com/your/repo/settings/actions/runners/new

```bash
cp .env.example .env # adapt .env
docker compose up -d
docker compose logs -f
```