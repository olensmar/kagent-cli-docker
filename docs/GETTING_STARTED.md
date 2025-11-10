# 🚀 Getting Started with Kagent CLI Docker

This guide will get you up and running with the kagent CLI Docker image in 5 minutes.

## Prerequisites

- ✅ Docker installed
- ✅ Access to a Kubernetes cluster (optional)
- ✅ kubeconfig file (optional, for k8s features)

## Step 1: Build the Image (2 minutes)

```bash
cd go
make docker-build-cli
```

**Expected output:**
```
Building kagent CLI on linux/amd64 -> linux/amd64
Successfully tagged kagent-cli:latest
```

## Step 2: Verify the Build (30 seconds)

```bash
./test-cli-docker.sh
```

**Expected output:**
```
========================================
Kagent CLI Docker Image Test Suite
========================================

[PASS] Image kagent-cli:latest exists
[PASS] Image size is reasonable: 150MB
[PASS] kagent binary is present
[PASS] kubectl is present
...
Results: 10 passed, 0 failed out of 10 tests

========================================
All Tests Passed! ✨
========================================
```

## Step 3: Run Your First Command (10 seconds)

```bash
# Show help
docker run --rm kagent-cli:latest --help
```

## Step 4: Invoke an Agent (30 seconds)

### Option A: Using the Convenience Script (Recommended)

```bash
./kagent-docker.sh invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "List all pods in the kagent namespace"
```

### Option B: Direct Docker Command

```bash
docker run --rm \
  -v ~/.kube/config:/home/nonroot/.kube/config:ro \
  --network host \
  kagent-cli:latest invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "List all pods in the kagent namespace"
```

## Step 5: Create an Alias (Optional, 10 seconds)

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias kagent='docker run --rm -v ~/.kube/config:/home/nonroot/.kube/config:ro --network host kagent-cli:latest'
```

Then reload your shell:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

Now you can use it like a native command:
```bash
kagent invoke --agent "k8s-agent" --task "Get cluster info"
kagent get agent
kagent version
```

## Common Use Cases

### 1. List Agents

```bash
kagent get agent -n kagent
```

### 2. Stream Agent Response

```bash
kagent invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "Explain Kubernetes architecture" \
  --stream
```

### 3. Read Task from File

Create a file `task.txt`:
```
Analyze the health of the kagent namespace:
1. List all pods and their status
2. Check for any issues
3. Provide recommendations
```

Then run:
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

### 4. Continue a Session

```bash
# First message (creates session)
SESSION_ID=$(kagent invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --task "What namespaces exist?" \
  | jq -r '.sessionId')

# Continue the conversation
kagent invoke \
  --agent "k8s-agent" \
  --namespace "kagent" \
  --session "$SESSION_ID" \
  --task "List pods in the first namespace"
```

## Troubleshooting

### Issue: "Cannot connect to kagent"

**Solution 1**: Check if kagent is running
```bash
kubectl get pods -n kagent
```

**Solution 2**: Verify port-forward works
```bash
kubectl port-forward -n kagent svc/kagent-controller 8083:8083
```

**Solution 3**: Use the URL override
```bash
kagent invoke --kagent-url "http://your-kagent-url:8083" ...
```

### Issue: "Permission denied" on kubeconfig

```bash
chmod 644 ~/.kube/config
```

### Issue: Image not found

```bash
# Rebuild the image
cd go
make docker-build-cli
```

## Next Steps

### Learn More
- 📖 **Full Documentation**: [README.cli-docker.md](README.cli-docker.md)
- 🎯 **Quick Reference**: [QUICKREF.cli-docker.md](QUICKREF.cli-docker.md)
- 📚 **Examples**: [examples/cli-docker/README.md](examples/cli-docker/README.md)

### Advanced Usage
- **Docker Compose**: See `docker-compose.cli.yml`
- **CI/CD Integration**: See examples/cli-docker/README.md
- **Kubernetes CronJobs**: See `examples/cli-docker/kubernetes-cronjob.yaml`
- **Batch Processing**: See examples/cli-docker/README.md

### Production Deployment
1. **Tag & Push**: Tag your image and push to registry
   ```bash
   docker tag kagent-cli:latest your-registry/kagent-cli:v1.0.0
   docker push your-registry/kagent-cli:v1.0.0
   ```

2. **Deploy to Kubernetes**: Use the provided manifests
   ```bash
   kubectl apply -f examples/cli-docker/kubernetes-cronjob.yaml
   ```

3. **Set up CI/CD**: Integrate with your pipeline (see examples)

## Tips for Success

1. ✅ **Always use `--network host`** when port-forwarding is needed
2. ✅ **Mount kubeconfig as read-only** (`:ro`) for security
3. ✅ **Create a shell alias** for convenience
4. ✅ **Use `--stream` flag** for long-running tasks
5. ✅ **Check the test script** to verify everything works
6. ✅ **Read the quick reference** for common commands

## Help & Support

- **Documentation**: All docs are in the `go/` directory
- **Examples**: Check `examples/cli-docker/` for practical examples
- **Issues**: Report issues on GitHub
- **Community**: Join the Kagent community

---

## Summary of Available Resources

```
go/
├── Dockerfile.cli                    # Main Dockerfile
├── kagent-docker.sh                  # Convenience script ⭐
├── test-cli-docker.sh                # Test suite
├── docker-compose.cli.yml            # Docker Compose config
├── README.cli-docker.md              # Full documentation 📖
├── QUICKREF.cli-docker.md            # Quick reference 🎯
├── GETTING_STARTED_DOCKER.md         # This file 🚀
└── examples/cli-docker/
    ├── README.md                     # Examples 📚
    ├── example-task.txt              # Sample task
    ├── docker-compose-advanced.yml   # Advanced compose
    └── kubernetes-cronjob.yaml       # K8s manifests
```

**Ready to go? Start with `./kagent-docker.sh --help`** 🎉

