# GitHub Actions Workflows

## Build and Push Docker Image

This workflow builds the kagent CLI Docker image and pushes it to Docker Hub.

### Prerequisites

Before running the workflow, you need to set up a Docker Hub access token:

1. **Create a Docker Hub Access Token:**
   - Go to https://hub.docker.com/settings/security
   - Click "New Access Token"
   - Give it a name (e.g., "github-actions")
   - Set permissions to "Read, Write, Delete"
   - Copy the generated token

2. **Add the token to GitHub Secrets:**
   - Go to your repository on GitHub
   - Navigate to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `DOCKERHUB_TOKEN`
   - Value: Paste your Docker Hub access token
   - Click "Add secret"

### Running the Workflow

The workflow can be triggered manually from the GitHub Actions tab:

1. Go to the **Actions** tab in your GitHub repository
2. Select **"Build and Push Docker Image"** from the workflows list
3. Click **"Run workflow"**
4. Configure the inputs:
   - **Version tag**: The Docker image tag (e.g., `v1.0.0`, `latest`)
   - **Kagent version**: The kagent branch/tag to build from (e.g., `main`, `v1.0.0`)
5. Click **"Run workflow"**

### Workflow Inputs

- **version** (optional, default: `latest`)
  - The version tag for the Docker image
  - Examples: `v1.0.0`, `v1.1.0-beta`, `latest`
  - Will be tagged as: `olensmar/kagent-cli:<version>`

- **kagent_version** (optional, default: `main`)
  - The kagent repository branch or tag to build from
  - Examples: `main`, `v1.0.0`, `feature-branch`
  - This determines which version of the kagent CLI will be built

### What the Workflow Does

1. **Checks out** the repository code
2. **Sets up QEMU** for multi-architecture builds
3. **Sets up Docker Buildx** for advanced build features
4. **Logs in to Docker Hub** using your credentials
5. **Builds the image** for both AMD64 and ARM64 architectures
6. **Pushes the image** to Docker Hub at `olensmar/kagent-cli`
7. Uses GitHub Actions **cache** to speed up subsequent builds

### Example Usage

After the workflow completes, you can pull and use the image:

```bash
# Pull the image
docker pull olensmar/kagent-cli:latest

# Run the CLI
docker run --rm olensmar/kagent-cli:latest --help

# Invoke an agent
docker run --rm \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  --network host \
  olensmar/kagent-cli:latest invoke \
  --agent "k8s-agent" \
  --task "List all pods"
```

### Troubleshooting

**Error: "unauthorized: authentication required"**
- Check that the `DOCKERHUB_TOKEN` secret is set correctly
- Verify the token has write permissions
- Ensure the token hasn't expired

**Error: "failed to solve: process "/bin/sh -c git clone..."**
- The kagent repository might be unavailable
- Check the `kagent_version` input is a valid branch/tag
- Verify network connectivity

**Build takes too long**
- First builds take longer (10-15 minutes)
- Subsequent builds use cache and are much faster (2-5 minutes)

### Multi-Architecture Support

The workflow builds for both:
- **linux/amd64** - Intel/AMD processors
- **linux/arm64** - ARM processors (Apple Silicon, AWS Graviton, etc.)

Docker will automatically pull the correct architecture for your platform.

