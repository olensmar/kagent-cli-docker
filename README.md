# Kagent CLI Docker Image

This directory contains a Dockerfile for building a containerized version of the kagent CLI that can be used to invoke agents from CI/CD/testing pipelines and workflows.

## Features

- **Minimal Image**: Built on Chainguard's minimal base images for security and size
- **kubectl Included**: Includes kubectl for port-forwarding to Kubernetes clusters
- **Multi-arch Support**: Supports both AMD64 and ARM64 architectures
- **Non-root User**: Runs as non-root user for enhanced security

## Building the Image

### Build for Local Architecture

```bash
cd go
make docker-build-cli
```

This will build the image tagged as `kagent-cli:latest` and `kagent-cli:<version>` for your local architecture.

### Build for Multiple Architectures

To build for both AMD64 and ARM64:

```bash
cd go
make docker-build-cli-multiarch
```

Note: This requires Docker Buildx to be set up.

### Automated Builds with GitHub Actions

Pre-built images are available on Docker Hub at `olensmar/kagent-cli`.

To trigger a new build and push to Docker Hub:

1. **Set up Docker Hub credentials** (one-time setup):
   - Create a Docker Hub access token at https://hub.docker.com/settings/security
   - Add it as a GitHub secret named `DOCKERHUB_TOKEN` in your repository settings

2. **Trigger the workflow**:
   - Go to the **Actions** tab in GitHub
   - Select **"Build and Push Docker Image"**
   - Click **"Run workflow"**
   - Specify the version tag and kagent version to build

See [.github/workflows/README.md](.github/workflows/README.md) for detailed instructions.

## Using the Image

### Prerequisites

- Docker installed
- Access to a Kubernetes cluster (optional, if using port-forward)
- Kubeconfig file mounted into the container (if accessing k8s clusters)

### Basic Usage

Show help:
```bash
# Using Docker Hub image
docker run --rm olensmar/kagent-cli:latest

# Or using locally built image
docker run --rm kagent-cli:latest
```

### Invoking an Agent

#### Option 1: Direct Connection (when kagent is accessible via URL)

```bash
docker run --rm \
  kagent-cli:latest invoke \
  --kagent-url "http://kagent-controller.kagent.svc.cluster.local:8083" \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "Get all the pods in the kagent namespace"
```

#### Option 2: Using Kubernetes Port-Forward

When you need to access kagent through a Kubernetes cluster:

```bash
docker run --rm \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  --network host \
  kagent-cli:latest invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "Get all the pods in the kagent namespace"
```

Explanation:
- `-v ~/.kube/config:/home/nonroot/.kube/config:ro`: Mounts your kubeconfig (read-only)
- `--network host`: Allows the container to access localhost for port-forwarding

#### Option 3: Using Streaming Response

For real-time streaming of agent responses:

```bash
docker run --rm \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  --network host \
  kagent-cli:latest invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "Get all the pods in the kagent namespace" \
  --stream
```

### Reading Task from File

You can pass a task from a file:

```bash
docker run --rm \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  -v $(pwd)/task.txt:/tmp/task.txt:ro \
  --network host \
  kagent-cli:latest invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --file /tmp/task.txt
```

### Reading Task from stdin

```bash
echo "List all pods in the kagent namespace" | docker run --rm -i \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  --network host \
  kagent-cli:latest invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --file -
```

### Other Commands

Get agents:
```bash
docker run --rm \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  --network host \
  kagent-cli:latest get agent
```

Get sessions:
```bash
docker run --rm \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  --network host \
  kagent-cli:latest get session
```

Version information:
```bash
docker run --rm \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  --network host \
  kagent-cli:latest version
```

## Environment Variables

The following environment variables can be set:

- `KUBECONFIG`: Path to kubeconfig file (default: `/home/nonroot/.kube/config`)

## Docker Compose Example

Create a `docker-compose.yml` file for easier usage:

```yaml
version: '3.8'
services:
  kagent-cli:
    image: kagent-cli:latest
    volumes:
      - ~/.kube/config:/home/nonroot/.kube/config:ro
    network_mode: host
    environment:
      - KUBECONFIG=/home/nonroot/.kube/config
```

Then run:
```bash
docker-compose run --rm kagent-cli invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "Get all the pods"
```

## Persistent Configuration

To persist kagent CLI configuration between runs:

```bash
docker run --rm \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  -v kagent-config:/home/nonroot/.kagent \
  --network host \
  kagent-cli:latest <command>
```

This creates a Docker volume named `kagent-config` that persists the CLI configuration.

## Shell Alias for Convenience

Add this to your shell profile for easy access:

```bash
alias kagent-docker='docker run --rm -v ~/.kube/config:/home/nonroot/.kube/config:ro --network host kagent-cli:latest'
```

Then use it like:
```bash
kagent-docker invoke --agent "k8s-agent" --task "List pods"
```

## Troubleshooting

### Connection Issues

If you encounter connection issues:

1. **Verify kubeconfig**: Ensure your kubeconfig is properly mounted
2. **Check network**: Use `--network host` for port-forwarding
3. **Verify kagent URL**: Check that the kagent-url flag points to the correct endpoint
4. **Check verbose output**: Add `-v` flag for detailed logging

### Permission Issues

If you see permission errors with kubeconfig:

```bash
# Make sure the kubeconfig has proper permissions
chmod 644 ~/.kube/config
```

### kubectl Not Found

The kubectl binary is included in the image. If you encounter issues:

```bash
# Test kubectl availability
docker run --rm kagent-cli:latest kubectl version --client
```

## Security Considerations

- The image runs as a non-root user (`nonroot:nonroot`)
- Mount kubeconfig as read-only (`:ro` flag)
- Uses minimal Chainguard base images with reduced attack surface
- No shell access in the base image by default

## Image Size

The final image is optimized for size:
- Base image: Chainguard glibc-dynamic (minimal)
- Only includes kagent CLI binary and kubectl
- No unnecessary tools or libraries

## Building for Production

For production use, consider:

1. **Tag with specific versions**: Use semantic versioning
2. **Push to registry**: Push to your container registry
3. **Scan for vulnerabilities**: Use tools like trivy or snyk
4. **Sign images**: Use Docker Content Trust or cosign

Example:
```bash
# Build
make docker-build-cli

# Tag for registry
docker tag kagent-cli:latest ghcr.io/your-org/kagent-cli:v1.0.0

# Push
docker push ghcr.io/your-org/kagent-cli:v1.0.0
```

## Contributing

When updating the Dockerfile:
1. Test both single-arch and multi-arch builds
2. Verify all CLI commands work in the container
3. Check image size hasn't grown unnecessarily
4. Update this README with any new usage patterns

## License

See the LICENSE file in the repository root.

