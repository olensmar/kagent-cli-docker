# Kagent CLI Docker Examples

This directory contains practical examples for using the kagent CLI Docker image.

## Quick Start

### 1. Build the Image

```bash
cd ../../
make docker-build-cli
```

### 2. Run Basic Commands

**Get help:**
```bash
./kagent-docker.sh --help
```

**List agents:**
```bash
./kagent-docker.sh get agent -n kagent
```

**Get version:**
```bash
./kagent-docker.sh version
```

## Example Usage Patterns

### Example 1: Simple Task Invocation

```bash
./kagent-docker.sh invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "List all pods in the kagent namespace"
```

### Example 2: Task from File

Create a task file:
```bash
cat > task.txt << EOF
Please analyze the health of the kagent namespace:
1. List all pods and their status
2. Check for any pods that are not running
3. Summarize the findings
EOF
```

Run with the task file:
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

### Example 3: Streaming Response

For real-time agent responses:
```bash
./kagent-docker.sh invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "Explain the architecture of Kubernetes" \
  --stream
```

### Example 4: Using Session Context

Create a session and continue conversation:
```bash
# First invocation (creates new session)
SESSION_ID=$(./kagent-docker.sh invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "What namespaces exist in this cluster?" \
  | jq -r '.sessionId')

# Continue in same session
./kagent-docker.sh invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --session "$SESSION_ID" \
  --task "List all pods in the first namespace you mentioned"
```

### Example 5: Direct URL Connection

When kagent is exposed via LoadBalancer or NodePort:
```bash
docker run --rm \
  kagent-cli:latest invoke \
  --kagent-url "http://kagent.example.com:8083" \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "Get cluster info"
```

### Example 6: CI/CD Pipeline Integration

In a CI/CD pipeline (GitHub Actions, GitLab CI, etc.):

```yaml
# .github/workflows/invoke-agent.yml
name: Invoke Kagent Agent

on:
  workflow_dispatch:
    inputs:
      task:
        description: 'Task to execute'
        required: true
      agent:
        description: 'Agent name'
        required: true
        default: 'k8s-agent'

jobs:
  invoke:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Run kagent invoke
        run: |
          docker run --rm \
            -e KUBECONFIG_DATA="${{ secrets.KUBECONFIG }}" \
            kagent-cli:latest invoke \
            --agent "${{ github.event.inputs.agent }}" \
            --namespace "kagent" \
            --task "${{ github.event.inputs.task }}"
```

## Docker Compose Examples

See the provided `docker-compose.cli.yml` files for different scenarios:

### Basic Usage

```bash
# In the go directory
docker-compose -f docker-compose.cli.yml run --rm kagent-cli invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "List all services"
```

### With Custom Environment

Create `.env` file:
```env
KAGENT_URL=http://kagent-controller.kagent.svc.cluster.local:8083
KAGENT_NAMESPACE=kagent
```

Update `docker-compose.cli.yml`:
```yaml
services:
  kagent-cli:
    env_file: .env
    environment:
      - KAGENT_URL=${KAGENT_URL}
```

## Advanced Examples

### Example 7: Batch Processing

Process multiple tasks from a file:

```bash
cat > tasks.txt << EOF
List all namespaces
Count pods in kagent namespace
Show all services in default namespace
EOF

while IFS= read -r task; do
  echo "Processing: $task"
  ./kagent-docker.sh invoke \
    --agent "k8s-agent" \
    --namespace "kagent" \
    --task "$task"
done < tasks.txt
```

### Example 8: JSON Output Processing

Extract specific information from responses:

```bash
./kagent-docker.sh invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "List all pods" \
  | jq '.result.content'
```

### Example 9: Error Handling

Robust script with error handling:

```bash
#!/bin/bash
set -e

AGENT="k8s-agent"
NAMESPACE="kagent"
TASK="Get cluster status"

if ! response=$(./kagent-docker.sh invoke \
  --agent "$AGENT" \
  --namespace "$NAMESPACE" \
  --task "$TASK" 2>&1); then
  echo "Error invoking agent: $response"
  exit 1
fi

echo "Success: $response"
```

## Kubernetes Integration

### Example 10: CronJob for Scheduled Tasks

Create a Kubernetes CronJob that uses the CLI container:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kagent-cli-scheduled
  namespace: kagent
spec:
  schedule: "0 * * * *"  # Every hour
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: kagent-cli
          containers:
          - name: kagent-cli
            image: kagent-cli:latest
            args:
            - "invoke"
            - "--agent"
            - "k8s-agent"
            - "--namespace"
            - "kagent"
            - "--task"
            - "Generate hourly cluster health report"
            env:
            - name: KAGENT_URL
              value: "http://kagent-controller.kagent.svc.cluster.local:8083"
          restartPolicy: OnFailure
```

### Example 11: Kubernetes Job

One-time task execution:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: kagent-cli-onetime
  namespace: kagent
spec:
  template:
    spec:
      serviceAccountName: kagent-cli
      containers:
      - name: kagent-cli
        image: kagent-cli:latest
        args:
        - "invoke"
        - "--agent"
        - "k8s-agent"
        - "--namespace"
        - "kagent"
        - "--task"
        - "Analyze cluster security posture"
        env:
        - name: KAGENT_URL
          value: "http://kagent-controller.kagent.svc.cluster.local:8083"
      restartPolicy: Never
  backoffLimit: 3
```

## Tips and Best Practices

1. **Use Named Volumes**: Persist configuration between runs
   ```bash
   docker volume create kagent-config
   ```

2. **Network Mode**: Use `--network host` for port-forwarding to work
   
3. **Read-only Mounts**: Always mount kubeconfig as read-only (`:ro`)

4. **Environment Variables**: Pass sensitive data via environment variables, not command line

5. **Verbose Output**: Add `-v` flag for debugging:
   ```bash
   ./kagent-docker.sh invoke -v --agent "k8s-agent" --task "Debug task"
   ```

6. **Session Management**: Use sessions for related tasks to maintain context

7. **Streaming**: Use `--stream` for long-running tasks to see progress

8. **Error Handling**: Always capture and handle errors in scripts

## Troubleshooting

### Issue: "Cannot connect to kagent"

**Solution**: Verify network connectivity and use `--network host`:
```bash
docker run --rm --network host kagent-cli:latest version
```

### Issue: "kubectl: command not found"

**Solution**: The kubectl binary should be included. Verify:
```bash
docker run --rm kagent-cli:latest kubectl version --client
```

### Issue: "Permission denied" for kubeconfig

**Solution**: Fix kubeconfig permissions:
```bash
chmod 644 ~/.kube/config
```

### Issue: Port-forward fails

**Solution**: Ensure you're using `--network host` and kubeconfig is mounted

## Additional Resources

- [Main CLI Docker README](../../README.cli-docker.md)
- [Kagent Documentation](../../../README.md)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## Contributing

Found a useful pattern? Submit a PR with your example!

