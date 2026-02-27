.PHONY: build push run stop clean help

# Variables
REGISTRY ?= ghcr.io/cpfarhood
IMAGE_NAME ?= devcontainer
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
		-v $(PWD)/home:/home \
		-v $(PWD)/workspace:/workspace \
		--name devcontainer \
		$(FULL_IMAGE)
	@echo "Access at http://localhost:5800"

# Stop the running container
stop:
	@echo "Stopping devcontainer..."
	docker stop devcontainer || true
	docker rm devcontainer || true

# Clean up local volumes
clean: stop
	@echo "Cleaning up..."
	rm -rf ./home ./workspace

# Helm deployment
RELEASE_NAME ?= mydev
NAMESPACE ?= default

helm-deploy:
	@echo "Deploying with Helm (release: $(RELEASE_NAME))..."
	@if [ -z "$(GITHUB_REPO)" ]; then \
		echo "ERROR: GITHUB_REPO environment variable is required"; \
		echo "Usage: GITHUB_REPO=https://github.com/user/repo make helm-deploy"; \
		exit 1; \
	fi
	helm upgrade --install $(RELEASE_NAME) ./chart \
		--namespace $(NAMESPACE) \
		--set name=$(RELEASE_NAME) \
		--set githubRepo="$(GITHUB_REPO)" \
		--set image.repository=$(REGISTRY)/$(IMAGE_NAME) \
		--set image.tag=$(IMAGE_TAG)

helm-delete:
	@echo "Deleting Helm release $(RELEASE_NAME)..."
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	@echo "Note: PVC persists. To delete: kubectl delete pvc userhome-$(RELEASE_NAME) -n $(NAMESPACE)"

helm-logs:
	@echo "Showing logs for $(RELEASE_NAME)..."
	kubectl logs -f deployment/devcontainer-$(RELEASE_NAME) -n $(NAMESPACE)

helm-shell:
	@echo "Opening shell in $(RELEASE_NAME)..."
	kubectl exec -it deployment/devcontainer-$(RELEASE_NAME) -n $(NAMESPACE) -- bash

helm-port-forward:
	@echo "Port forwarding $(RELEASE_NAME) to localhost:5800..."
	kubectl port-forward deployment/devcontainer-$(RELEASE_NAME) 5800:5800 -n $(NAMESPACE)

# Show help
help:
	@echo "Dev Container Makefile"
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
	@echo "Helm/Kubernetes Targets:"
	@echo "  helm-deploy        - Deploy with Helm chart (requires GITHUB_REPO)"
	@echo "  helm-delete        - Delete Helm release"
	@echo "  helm-logs          - Show container logs"
	@echo "  helm-shell         - Open shell in container"
	@echo "  helm-port-forward  - Port forward to localhost"
	@echo ""
	@echo "Variables:"
	@echo "  REGISTRY           - Docker registry (default: ghcr.io/cpfarhood)"
	@echo "  IMAGE_NAME         - Image name (default: devcontainer)"
	@echo "  IMAGE_TAG          - Image tag (default: latest)"
	@echo "  RELEASE_NAME       - Helm release name (default: mydev)"
	@echo "  NAMESPACE          - Kubernetes namespace (default: default)"
	@echo "  GITHUB_REPO        - GitHub repository URL (required for helm-deploy)"
	@echo ""
	@echo "Environment Variables for 'make run':"
	@echo "  GITHUB_REPO        - GitHub repository URL"
	@echo "  GITHUB_TOKEN       - GitHub token (optional)"
	@echo "  VNC_PASSWORD       - VNC password (optional)"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make push REGISTRY=ghcr.io/myuser IMAGE_TAG=v1.0"
	@echo "  GITHUB_REPO=https://github.com/user/repo make run"
	@echo "  GITHUB_REPO=https://github.com/user/repo make helm-deploy"
	@echo "  RELEASE_NAME=alice-dev GITHUB_REPO=https://github.com/alice/project make helm-deploy"
