VERSION ?= latest
KAGENT_VERSION ?= main
LDFLAGS ?= -X main.version=$(VERSION)

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

.PHONY: push
push: ## Push to registry
	docker push kagent-cli:$(VERSION)
	docker push kagent-cli:latest