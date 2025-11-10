### STAGE 1: Clone and build kagent CLI
ARG BASE_IMAGE_REGISTRY=cgr.dev
ARG BUILDPLATFORM
FROM --platform=$BUILDPLATFORM $BASE_IMAGE_REGISTRY/chainguard/go:latest AS builder
ARG TARGETARCH
ARG KAGENT_VERSION=main
ARG KAGENT_REPO=https://github.com/kagent-dev/kagent.git

WORKDIR /workspace

# Clone the kagent repository
RUN git clone --depth 1 --branch ${KAGENT_VERSION} ${KAGENT_REPO} kagent

WORKDIR /workspace/kagent/go

# Download dependencies
RUN --mount=type=cache,target=/root/go/pkg/mod,rw      \
    --mount=type=cache,target=/root/.cache/go-build,rw \
    go mod download

# Build the CLI binary
ARG LDFLAGS
RUN --mount=type=cache,target=/root/go/pkg/mod,rw             \
    --mount=type=cache,target=/root/.cache/go-build,rw        \
    CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} \
    go build -a -ldflags "$LDFLAGS" -o kagent cli/cmd/kagent/main.go

### STAGE 2: kubectl stage
FROM cgr.dev/chainguard/kubectl:latest-dev AS kubectl

### STAGE 3: Final minimal image
FROM cgr.dev/chainguard/wolfi-base:latest
ARG VERSION

WORKDIR /app

# Install jq for JSON processing
RUN apk add --no-cache jq

# Copy binaries
COPY --from=builder /workspace/kagent/go/kagent /usr/local/bin/kagent
COPY --from=kubectl /usr/bin/kubectl /usr/local/bin/kubectl

# Setup non-root user
RUN mkdir -p /home/nonroot/.kagent && \
    chown -R nonroot:nonroot /home/nonroot

USER nonroot:nonroot
ENV HOME=/home/nonroot

# Labels
LABEL org.opencontainers.image.source=https://github.com/kagent-dev/kagent-cli-docker
LABEL org.opencontainers.image.description="Kagent CLI Docker image for invoking agents"
LABEL org.opencontainers.image.version="$VERSION"
LABEL kagent.version="$KAGENT_VERSION"

ENTRYPOINT ["/usr/local/bin/kagent"]
CMD ["--help"]