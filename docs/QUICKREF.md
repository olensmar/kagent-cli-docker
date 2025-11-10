# Kagent CLI Docker - Quick Reference

## Build & Setup

```bash
# Build the image
cd go && make docker-build-cli

# Test the image
./test-cli-docker.sh

# Create shell alias (add to ~/.bashrc or ~/.zshrc)
alias kagent='docker run --rm -v ~/.kube/config:/home/nonroot/.kube/config:ro --network host kagent-cli:latest'
```

## Basic Commands

```bash
# Help
docker run --rm kagent-cli:latest --help

# Version
docker run --rm kagent-cli:latest version

# List agents
kagent get agent -n kagent

# List sessions
kagent get session -n kagent

# List tools
kagent get tool -n kagent
```

## Invoke Agent

```bash
# Basic invoke
kagent invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "Your task here"

# With streaming
kagent invoke -S \
  --agent "k8s-agent" \
  -n kagent \
  -t "Your task here"

# From file
kagent invoke \
  -a "k8s-agent" \
  -n kagent \
  -f task.txt

# From stdin
echo "Your task" | kagent invoke -a "k8s-agent" -n kagent -f -

# Continue session
kagent invoke \
  -a "k8s-agent" \
  -n kagent \
  -s "session-id" \
  -t "Follow-up task"
```

## Using the Convenience Script

```bash
# The script automatically handles volume mounts and network
./kagent-docker.sh invoke -a "k8s-agent" -t "List pods"
./kagent-docker.sh get agent
./kagent-docker.sh version
```

## Docker Compose

```bash
# Run with docker-compose
docker-compose -f docker-compose.cli.yml run --rm kagent-cli invoke \
  --agent "k8s-agent" \
  --task "Your task"
```

## Common Patterns

### CI/CD Pipeline
```bash
docker run --rm \
  -e KUBECONFIG_DATA="${KUBECONFIG_SECRET}" \
  kagent-cli:latest invoke \
  --agent "k8s-agent" \
  --task "Run tests"
```

### Batch Processing
```bash
for task in tasks/*.txt; do
  kagent invoke -a "k8s-agent" -f "$task"
done
```

### Output to File
```bash
kagent invoke \
  -a "k8s-agent" \
  -t "Generate report" > report.json
```

### With jq Processing
```bash
kagent invoke \
  -a "k8s-agent" \
  -t "Get pod status" | jq '.result'
```

## Flags Reference

### Global Flags
- `--kagent-url`: URL to kagent server (default: http://localhost:8083)
- `-n, --namespace`: Kubernetes namespace (default: kagent)
- `-o, --output-format`: Output format (table|json|yaml)
- `-v, --verbose`: Verbose output
- `--timeout`: Request timeout (default: 300s)

### Invoke Flags
- `-a, --agent`: Agent name (required)
- `-t, --task`: Task to execute
- `-f, --file`: Read task from file (use `-` for stdin)
- `-s, --session`: Session ID for continuing conversation
- `-S, --stream`: Stream the response

## Volume Mounts

```bash
# Mount kubeconfig
-v ~/.kube/config:/home/nonroot/.kube/config:ro

# Mount task files
-v $(pwd)/tasks:/tasks:ro

# Persistent config
-v kagent-config:/home/nonroot/.kagent

# Output directory
-v $(pwd)/output:/output:rw
```

## Environment Variables

```bash
# Set kubeconfig location
-e KUBECONFIG=/path/to/config

# Set namespace
-e KAGENT_NAMESPACE=production

# Set kagent URL
-e KAGENT_URL=http://kagent.example.com:8083
```

## Network Modes

```bash
# Host network (for port-forwarding)
--network host

# Custom network
--network my-network

# Bridge (default)
--network bridge
```

## Troubleshooting

### Can't connect to kagent
```bash
# Check connection
kagent version

# Verify port-forward works
kubectl -n kagent port-forward svc/kagent-controller 8083:8083

# Use direct URL
kagent invoke --kagent-url "http://kagent-url:8083" ...
```

### Permission denied on kubeconfig
```bash
chmod 644 ~/.kube/config
```

### kubectl not found
```bash
# Verify kubectl is in image
docker run --rm --entrypoint kubectl kagent-cli:latest version --client
```

## Tips

1. **Always use `--network host`** for port-forwarding
2. **Mount kubeconfig as read-only** (`:ro`) for security
3. **Use `-S` flag** for long-running tasks to see progress
4. **Create shell alias** for easier usage
5. **Use docker-compose** for complex setups
6. **Persist config** with named volumes
7. **Check logs** with `-v` flag for debugging

## Links

- Full Documentation: [README.cli-docker.md](README.cli-docker.md)
- Examples: [examples/cli-docker/](examples/cli-docker/)
- GitHub Issues: https://github.com/kagent-dev/kagent/issues

