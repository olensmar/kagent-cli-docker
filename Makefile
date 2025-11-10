VERSION ?= latest
KAGENT_VERSION ?= main
LDFLAGS ?= -X main.version=$(VERSION)
DOCKER_HUB_USERNAME ?= olensmar

.PHONY: build
build: ## Build the Docker image
	docker build \
		--build-arg LDFLAGS="$(LDFLAGS)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg KAGENT_VERSION="$(KAGENT_VERSION)" \
		-t kagent-cli:$(VERSION) \
		-t kagent-cli:latest \
		.

.PHONY: build-multiarch
build-multiarch: ## Build for multiple architectures
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--build-arg LDFLAGS="$(LDFLAGS)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg KAGENT_VERSION="$(KAGENT_VERSION)" \
		-t kagent-cli:$(VERSION) \
		-t kagent-cli:latest \
		.

.PHONY: test
test: ## Run tests
	./test-docker.sh

.PHONY: tag-dockerhub
tag-dockerhub: ## Tag image for Docker Hub
	docker tag kagent-cli:$(VERSION) $(DOCKER_HUB_USERNAME)/kagent-cli:$(VERSION)
	docker tag kagent-cli:latest $(DOCKER_HUB_USERNAME)/kagent-cli:latest

.PHONY: push-dockerhub
push-dockerhub: tag-dockerhub ## Push to Docker Hub
	docker push $(DOCKER_HUB_USERNAME)/kagent-cli:$(VERSION)
	docker push $(DOCKER_HUB_USERNAME)/kagent-cli:latest

.PHONY: build-and-push-dockerhub
build-and-push-dockerhub: build push-dockerhub ## Build and push to Docker Hub

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-30s %s\n", $$1, $$2}'