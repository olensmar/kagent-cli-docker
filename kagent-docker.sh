#!/bin/bash
#
# Convenience wrapper script for running kagent CLI in Docker
# 
# Usage:
#   ./kagent-docker.sh invoke --agent k8s-agent --task "Get all pods"
#   ./kagent-docker.sh get agent
#   ./kagent-docker.sh version
#

set -e

# Configuration
IMAGE_NAME="${KAGENT_CLI_IMAGE:-kagent-cli:latest}"
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"
KAGENT_CONFIG_VOLUME="${KAGENT_CONFIG_VOLUME:-kagent-config}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if the image exists, if not try to build it
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    print_warn "Image $IMAGE_NAME not found locally"
    
    # Check if we're in the correct directory to build
    if [ -f "Dockerfile.cli" ] && [ -f "Makefile" ]; then
        print_info "Building kagent CLI Docker image..."
        make docker-build-cli
    else
        print_error "Image not found and cannot build (not in correct directory)"
        print_info "Please run: cd go && make docker-build-cli"
        exit 1
    fi
fi

# Build docker run command
DOCKER_ARGS=(
    "run"
    "--rm"
    "-i"
)

# Mount kubeconfig if it exists
if [ -f "$KUBECONFIG_PATH" ]; then
    DOCKER_ARGS+=("-v" "$KUBECONFIG_PATH:/home/nonroot/.kube/config:ro")
    DOCKER_ARGS+=("-e" "KUBECONFIG=/home/nonroot/.kube/config")
else
    print_warn "Kubeconfig not found at $KUBECONFIG_PATH"
    print_info "Some commands may not work without Kubernetes access"
fi

# Use host network for port-forwarding support
DOCKER_ARGS+=("--network" "host")

# Mount persistent config volume
DOCKER_ARGS+=("-v" "$KAGENT_CONFIG_VOLUME:/home/nonroot/.kagent")

# If stdin is a terminal, allocate a pseudo-TTY
if [ -t 0 ]; then
    DOCKER_ARGS+=("-t")
fi

# Add the image name
DOCKER_ARGS+=("$IMAGE_NAME")

# Add all arguments passed to this script
DOCKER_ARGS+=("$@")

# Run the container
print_info "Running: docker ${DOCKER_ARGS[*]}"
exec docker "${DOCKER_ARGS[@]}"

