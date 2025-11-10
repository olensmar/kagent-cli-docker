# Setup Guide for kagent-cli-docker

This guide will help you set up the repository and configure automated Docker Hub publishing.

## Prerequisites

- GitHub repository created and code pushed
- Docker Hub account (username: `olensmar`)

## One-Time Setup

### 1. Create Docker Hub Access Token

1. Log in to Docker Hub at https://hub.docker.com
2. Go to **Account Settings** → **Security** → **Access Tokens**
3. Click **"New Access Token"**
4. Configure the token:
   - Description: `github-actions-kagent-cli`
   - Access permissions: **Read, Write, Delete**
5. Click **"Generate"**
6. **Copy the token** (you won't be able to see it again!)

### 2. Add Token to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Add the secret:
   - Name: `DOCKERHUB_TOKEN`
   - Secret: Paste the Docker Hub access token from step 1
5. Click **"Add secret"**

### 3. Verify Repository Setup

Your repository should have this structure:

```
kagent-cli-docker/
├── .github/
│   └── workflows/
│       ├── build-and-push.yml    ← GitHub Actions workflow
│       └── README.md              ← Workflow documentation
├── docs/
│   ├── GETTING_STARTED.md
│   └── QUICKREF.md
├── examples/
│   ├── docker-compose-advanced.yml
│   ├── example-task.txt
│   ├── kubernetes-cronjob.yaml
│   └── README.md
├── .dockerignore
├── Dockerfile
├── Makefile
├── README.md
├── docker-compose.yml
├── kagent-docker.sh
└── test-docker.sh
```

## Usage

### Automated Build with GitHub Actions (Recommended)

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Select **"Build and Push Docker Image"** workflow
4. Click **"Run workflow"**
5. Fill in the parameters:
   - **Version tag**: e.g., `v1.0.0`, `v1.1.0`, or `latest`
   - **Kagent version**: e.g., `main`, `v1.0.0`, or any branch/tag
6. Click **"Run workflow"**

The workflow will:
- Build the image for AMD64 and ARM64 architectures
- Push to `olensmar/kagent-cli:<version>`
- Use GitHub Actions cache for faster builds

### Manual Build and Push

If you prefer to build and push manually from your local machine:

```bash
# Log in to Docker Hub
docker login -u olensmar

# Build the image
make build

# Tag and push to Docker Hub
make push-dockerhub

# Or do everything in one command
make build-and-push-dockerhub
```

### Build a Specific Version

```bash
# Build and push a specific version
make build-and-push-dockerhub VERSION=v1.0.0 KAGENT_VERSION=v1.0.0
```

## Verification

After the build completes, verify the image is available:

```bash
# Pull the image
docker pull olensmar/kagent-cli:latest

# Test it
docker run --rm olensmar/kagent-cli:latest --help
```

## Docker Hub Repository

Your images will be available at:
- **Repository**: https://hub.docker.com/r/olensmar/kagent-cli
- **Image**: `olensmar/kagent-cli:latest`
- **Versioned**: `olensmar/kagent-cli:v1.0.0`

## Troubleshooting

### GitHub Actions failing with authentication error

**Error**: `unauthorized: authentication required`

**Solution**:
1. Verify the `DOCKERHUB_TOKEN` secret is set correctly in GitHub
2. Make sure the token hasn't expired
3. Check that the token has write permissions

### Docker Hub push rate limited

**Error**: `toomanyrequests: You have reached your pull rate limit`

**Solution**:
- Authenticated users have higher rate limits
- Wait a few minutes and try again
- Consider upgrading your Docker Hub plan

### Build taking too long

**First build**: 10-15 minutes is normal (downloading base images, cloning repo, building)

**Subsequent builds**: 2-5 minutes (using GitHub Actions cache)

**Tip**: The GitHub Actions workflow uses aggressive caching to speed up rebuilds.

## Updating the Workflow

The workflow file is located at `.github/workflows/build-and-push.yml`.

You can customize:
- **Base images**: Change the Chainguard images in `Dockerfile`
- **Platforms**: Modify the `platforms` in the workflow
- **Triggers**: Add automatic triggers (on push, on release, etc.)
- **Docker Hub username**: Change `DOCKER_HUB_USERNAME` in the workflow

## Next Steps

1. ✅ Set up Docker Hub token (done above)
2. ✅ Configure GitHub secrets (done above)
3. 🚀 Run your first build via GitHub Actions
4. 📝 Update the main kagent README to link to this repository
5. 🔄 Set up automated builds on new kagent releases (optional)

## Support

- **Workflow Issues**: See [.github/workflows/README.md](.github/workflows/README.md)
- **Docker Issues**: See [README.md](README.md)
- **Examples**: See [examples/README.md](examples/README.md)

