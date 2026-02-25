# DevContainer Serverless 2.0 Makefile

# Configuration
REGISTRY ?= ghcr.io/cpfarhood
ROUTING_PROXY_IMAGE := $(REGISTRY)/devcontainer-routing-proxy
DEVCONTAINER_IMAGE := $(REGISTRY)/devcontainer
VERSION ?= 2.0.0-alpha
NAMESPACE := devcontainers

# Knative service name
KN_SERVICE := devcontainer-serverless

.PHONY: help build push deploy test clean

help: ## Display this help message
	@echo "DevContainer Serverless 2.0"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Build targets
build-routing-proxy: ## Build the routing proxy image
	@echo "Building routing proxy image..."
	cd routing-proxy && docker build -t $(ROUTING_PROXY_IMAGE):$(VERSION) .
	docker tag $(ROUTING_PROXY_IMAGE):$(VERSION) $(ROUTING_PROXY_IMAGE):latest

build-devcontainer: ## Build the main devcontainer image (from parent directory)
	@echo "Building devcontainer image..."
	cd .. && docker build -t $(DEVCONTAINER_IMAGE):$(VERSION) .
	docker tag $(DEVCONTAINER_IMAGE):$(VERSION) $(DEVCONTAINER_IMAGE):latest

build: build-routing-proxy build-devcontainer ## Build all images

# Push targets
push-routing-proxy: build-routing-proxy ## Push routing proxy image
	@echo "Pushing routing proxy image..."
	docker push $(ROUTING_PROXY_IMAGE):$(VERSION)
	docker push $(ROUTING_PROXY_IMAGE):latest

push-devcontainer: build-devcontainer ## Push devcontainer image
	@echo "Pushing devcontainer image..."
	docker push $(DEVCONTAINER_IMAGE):$(VERSION)
	docker push $(DEVCONTAINER_IMAGE):latest

push: push-routing-proxy push-devcontainer ## Push all images

# Deployment targets
create-namespace: ## Create the devcontainers namespace
	@echo "Creating namespace..."
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

deploy-secrets: create-namespace ## Deploy secrets (update values first!)
	@echo "Deploying secrets..."
	@echo "WARNING: Update the secret values in deployment.yaml first!"
	kubectl apply -f deployment.yaml
	@echo "Don't forget to update the secret with real values:"
	@echo "kubectl edit secret devcontainer-serverless-secrets -n $(NAMESPACE)"

deploy-components: create-namespace ## Deploy routing proxy and Knative service
	@echo "Deploying serverless components..."
	kubectl apply -f deployment.yaml

deploy: deploy-secrets deploy-components ## Deploy everything

# Configuration targets
configure-authentik: ## Apply Authentik configuration
	@echo "Applying Authentik configuration..."
	kubectl apply -f authentik-config.yaml
	@echo "Complete the setup in Authentik web UI:"
	@echo "1. Create Forward Auth Provider"
	@echo "2. Create Application"
	@echo "3. Create Outpost"

# Testing targets
test-routing-proxy: ## Test routing proxy locally
	@echo "Testing routing proxy..."
	@echo "Starting local test..."
	cd routing-proxy && docker run --rm -d --name devcontainer-routing-test \
		-p 8080:8080 \
		-e DEVCONTAINER_SERVICE_URL=httpbin.org \
		$(ROUTING_PROXY_IMAGE):latest
	@echo "Testing GitHub repo extraction..."
	sleep 2
	curl -v "http://localhost:8080/github/microsoft/vscode" || true
	docker stop devcontainer-routing-test
	@echo "Test complete!"

test-knative: ## Test Knative service deployment
	@echo "Testing Knative service..."
	kubectl get ksvc $(KN_SERVICE) -n $(NAMESPACE)
	kubectl describe ksvc $(KN_SERVICE) -n $(NAMESPACE)

test: test-routing-proxy test-knative ## Run all tests

# Status and debugging targets
status: ## Show status of all components
	@echo "=== Namespace ==="
	kubectl get ns $(NAMESPACE) || echo "Namespace not found"
	@echo ""
	@echo "=== Routing Proxy ==="
	kubectl get deployment devcontainer-routing-proxy -n $(NAMESPACE) || echo "Routing proxy not found"
	@echo ""
	@echo "=== Knative Service ==="
	kubectl get ksvc $(KN_SERVICE) -n $(NAMESPACE) || echo "Knative service not found"
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE)
	@echo ""
	@echo "=== Ingress ==="
	kubectl get ingress -n $(NAMESPACE)

logs-routing-proxy: ## Show routing proxy logs
	kubectl logs -n $(NAMESPACE) deployment/devcontainer-routing-proxy -f

logs-knative: ## Show Knative service logs
	kubectl logs -n $(NAMESPACE) -l serving.knative.dev/service=$(KN_SERVICE) -f

# Cleanup targets
clean-pods: ## Delete all pods in the namespace
	kubectl delete pods --all -n $(NAMESPACE)

clean-deployment: ## Delete the serverless deployment
	kubectl delete -f deployment.yaml --ignore-not-found

clean-namespace: ## Delete the entire namespace
	kubectl delete namespace $(NAMESPACE) --ignore-not-found

clean: clean-deployment ## Clean up deployment

# Development targets
dev-setup: ## Set up development environment
	@echo "Setting up development environment..."
	@echo "Prerequisites:"
	@echo "- Kubernetes cluster with Knative Serving"
	@echo "- kubectl configured"
	@echo "- Docker for building images"
	@echo ""
	@echo "Run 'make build deploy' to get started"

scale-to-zero: ## Force Knative service to scale to zero
	@echo "Scaling Knative service to zero..."
	kubectl patch ksvc $(KN_SERVICE) -n $(NAMESPACE) --type='merge' -p='{"spec":{"template":{"metadata":{"annotations":{"autoscaling.knative.dev/minScale":"0"}}}}}'

scale-up: ## Trigger a scale-up of the Knative service
	@echo "Triggering scale-up..."
	curl -H "X-GitHub-Repo: https://github.com/microsoft/vscode" \
		"http://devcontainer-routing-proxy.$(NAMESPACE).svc.cluster.local/github/microsoft/vscode" || \
	kubectl run curl --rm -i --restart=Never --image=curlimages/curl -- \
		-H "X-GitHub-Repo: https://github.com/microsoft/vscode" \
		"http://devcontainer-routing-proxy.$(NAMESPACE).svc.cluster.local/github/microsoft/vscode"

# Documentation targets
docs: ## Generate documentation
	@echo "Documentation files:"
	@echo "- README.md: Main documentation"
	@echo "- deployment.yaml: Kubernetes manifests"
	@echo "- authentik-config.yaml: Authentik configuration"
	@echo ""
	@echo "View online documentation at: https://github.com/cpfarhood/devcontainer/tree/feature/serverless-2.0.0/serverless"

# Version management
version: ## Show current version
	@echo "Version: $(VERSION)"
	@echo "Registry: $(REGISTRY)"
	@echo "Images:"
	@echo "  - $(ROUTING_PROXY_IMAGE):$(VERSION)"
	@echo "  - $(DEVCONTAINER_IMAGE):$(VERSION)"

# Quick development workflow
dev: build deploy status ## Quick development: build, deploy, show status

# Production deployment workflow
prod: build push deploy configure-authentik status ## Production deployment workflow