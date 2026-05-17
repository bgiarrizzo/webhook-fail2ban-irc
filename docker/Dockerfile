# syntax=docker/dockerfile:1.7

# ================================
# Build image
# ================================
FROM swift:6.3-bookworm AS build

# Install only build dependencies (no dist-upgrade for faster, reproducible builds)
ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache-build \
    apt-get -q update \
    && apt-get install -y --no-install-recommends libjemalloc-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN --mount=type=cache,target=/root/.cache/org.swift.swiftpm \
    --mount=type=cache,target=/build/.swiftpm \
    swift package resolve \
    $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

# Copy only sources required for compilation to avoid cache invalidation on docs/tests changes
COPY ./src .

RUN mkdir /staging

# Build the application, with optimizations, with static linking, and using jemalloc
# N.B.: The static version of jemalloc is incompatible with the static Swift runtime.
RUN --mount=type=cache,target=/build/.build \
    --mount=type=cache,target=/root/.cache/org.swift.swiftpm \
    --mount=type=cache,target=/build/.swiftpm \
    swift build -c release \
    --product webhooks2irc \
    --static-swift-stdlib \
    -Xlinker -ljemalloc && \
    cp "$(swift build -c release --show-bin-path)/webhooks2irc" /staging && \
    # Copy resources bundled by SPM to staging area
    find -L "$(swift build -c release --show-bin-path)" -regex '.*\.resources$' -exec cp -Ra {} /staging \;

# Switch to the staging area
WORKDIR /staging

# Copy static swift backtracer binary to staging area
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./

# Copy any resources from the public directory and views directory if the directories exist
# Ensure that by default, neither the directory nor any of its contents are writable.
RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Resources ] && { mv /build/Resources ./Resources && chmod -R a-w ./Resources; } || true

# ================================
# Run image
# ================================
FROM debian:bookworm-slim

# Install only runtime dependencies (no dist-upgrade for smaller layers)
ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache-run \
    apt-get -q update \
    && apt-get -q install -y --no-install-recommends libjemalloc2 ca-certificates tzdata \
    # If FoundationNetworking, also install `libcurl4`.
    # libcurl4 \
    # If FoundationXML, also install `libxml2`.
    # libxml2 \
    && rm -r /var/lib/apt/lists/*

# Create a vapor user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=vapor:vapor /staging /app

# Provide configuration needed by the built-in crash reporter and some sensible default behaviors.
ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

# Ensure all further commands run as the vapor user
USER vapor:vapor

# Let Docker bind to port 8080
EXPOSE 8080

# Start the Vapor service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./webhooks2irc"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
