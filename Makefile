.PHONY: build push run stop clean help

# Variables
REGISTRY ?= ghcr.io/cpfarhood
IMAGE_NAME ?= antigravity
IMAGE_TAG ?= latest
FULL_IMAGE = $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

.DEFAULT_GOAL := help

# Build the Docker image
build:
	@echo "Building $(FULL_IMAGE)..."
	docker build -t $(FULL_IMAGE) .

# Push the image to registry
push: build
	@echo "Pushing $(FULL_IMAGE)..."
	docker push $(FULL_IMAGE)

# Run locally with Docker
run:
	@echo "Running $(FULL_IMAGE) locally..."
	docker run -d \
		-p 5800:5800 \
		-e GITHUB_REPO="${GITHUB_REPO}" \
		-e GITHUB_TOKEN="${GITHUB_TOKEN}" \
		-e VNC_PASSWORD="${VNC_PASSWORD}" \
		-e HAPPY_EXPERIMENTAL="true" \
		-v $(PWD)/home:/home \
		-v $(PWD)/workspace:/workspace \
		--name antigravity \
		$(FULL_IMAGE)
	@echo "Access at http://localhost:5800"

# Stop the running container
stop:
	@echo "Stopping antigravity container..."
	docker stop antigravity || true
	docker rm antigravity || true

# Clean up local volumes
clean: stop
	@echo "Cleaning up..."
	rm -rf ./home ./workspace

# Kubernetes deployment
k8s-deploy:
	@echo "Deploying to Kubernetes..."
	kubectl apply -k k8s/

k8s-delete:
	@echo "Deleting from Kubernetes..."
	kubectl delete -k k8s/

k8s-logs:
	@echo "Showing logs..."
	kubectl logs -f antigravity-0

k8s-shell:
	@echo "Opening shell..."
	kubectl exec -it antigravity-0 -- bash

k8s-port-forward:
	@echo "Port forwarding to localhost:5800..."
	kubectl port-forward antigravity-0 5800:5800

# Show help
help:
	@echo "Antigravity Dev Container Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Docker Targets:"
	@echo "  build              - Build the Docker image"
	@echo "  push               - Push image to registry"
	@echo "  run                - Run container locally (requires env vars)"
	@echo "  stop               - Stop running container"
	@echo "  clean              - Clean up containers and volumes"
	@echo ""
	@echo "Kubernetes Targets:"
	@echo "  k8s-deploy         - Deploy to Kubernetes"
	@echo "  k8s-delete         - Delete from Kubernetes"
	@echo "  k8s-logs           - Show container logs"
	@echo "  k8s-shell          - Open shell in container"
	@echo "  k8s-port-forward   - Port forward to localhost"
	@echo ""
	@echo "Variables:"
	@echo "  REGISTRY           - Docker registry (default: ghcr.io/cpfarhood)"
	@echo "  IMAGE_NAME         - Image name (default: antigravity)"
	@echo "  IMAGE_TAG          - Image tag (default: latest)"
	@echo ""
	@echo "Environment Variables for 'make run':"
	@echo "  GITHUB_REPO        - GitHub repository URL"
	@echo "  GITHUB_TOKEN       - GitHub token (optional)"
	@echo "  VNC_PASSWORD       - VNC password (optional)"
	@echo ""
	@echo "Example:"
	@echo "  make build"
	@echo "  make push REGISTRY=ghcr.io/myuser IMAGE_TAG=v1.0"
	@echo "  GITHUB_REPO=https://github.com/user/repo make run"
