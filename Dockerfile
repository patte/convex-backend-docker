FROM debian:stable-slim AS base

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    git \
    libssl-dev \
    pkg-config \
    ca-certificates \
    xz-utils \
    python3 \
    libclang-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone the repository
ARG RELEASE_TAG
RUN if [ -z ${RELEASE_TAG+x} ]; then echo "set RELEASE_TAG to the desired tag of convex-backend" && exit 1; fi
RUN git clone --depth 1 --branch $RELEASE_TAG https://github.com/get-convex/convex-backend.git /app

WORKDIR /app

# Download and install Node.js directly from the official source
RUN set -ex && \
    NODE_VERSION=$(cat .nvmrc) && \
    case "$(uname -m)" in \
    x86_64) ARCH="x64" ;; \
    aarch64 | arm64) ARCH="arm64" ;; \
    armv7l | armv6l) ARCH="armv7l" ;; \
    *) echo "Unsupported architecture"; exit 1 ;; \
    esac && \
    NODE_URL="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-${ARCH}.tar.xz" && \
    if curl --head --fail --silent $NODE_URL > /dev/null; then \
    curl -fsSL $NODE_URL -o node.tar.xz && \
    tar -xJf node.tar.xz -C /usr/local --strip-components=1 --no-same-owner && \
    rm node.tar.xz; \
    else \
    echo "Error: Node.js version $NODE_VERSION or architecture $ARCH not found at $NODE_URL"; \
    exit 1; \
    fi

# Install Rust using rustup and ensure the version matches the one in rust-toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup show

# Verify Node.js installation
RUN node -v && npm -v

# Install Just
RUN cargo install just

# Install Node.js dependencies and build the project
RUN npm ci --prefix scripts
RUN just rush install
RUN just rush build

# Build the Convex backend
RUN cargo fetch
RUN cargo build --release -p local_backend --bin convex-local-backend
RUN cargo build --release -p keybroker --bin generate_secret
RUN cargo build --release -p keybroker --bin generate_key

# Final stage
FROM debian:stable-slim

# Install necessary runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy necessary files from the builder stage
COPY --from=base /app/target/release/convex-local-backend /usr/local/bin/convex-local-backend
COPY --from=base /app/target/release/generate_secret /usr/local/bin/generate_secret
COPY --from=base /app/target/release/generate_key /usr/local/bin/generate_key
COPY --from=base /usr/local/bin/node /usr/local/bin/node
COPY --from=base /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=base /usr/local/bin/npm /usr/local/bin/npm

# Expose necessary ports
EXPOSE 3210
EXPOSE 3211

WORKDIR /app

# Run
CMD convex-local-backend --instance-name $INSTANCE_NAME --instance-secret $INSTANCE_SECRET
