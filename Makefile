# Check to see if we can use ash, in Alpine images, or default to BASH.
SHELL_PATH = /bin/ash
SHELL = $(if $(wildcard $(SHELL_PATH)),/bin/ash,/bin/bash)

# Deploy First Mentality

# ==============================================================================
# Go Installation
#
#	You need to have Go version 1.24 to run this code.
#
#	https://go.dev/dl/
#
#	If you are not allowed to update your Go frontend, you can install
#	and use a 1.24 frontend.
#
#	$ go install golang.org/dl/go1.24@latest
#	$ go1.24 download
#
#	This means you need to use `go1.24` instead of `go` for any command
#	using the Go frontend tooling from the Makefile.

# ==============================================================================
# Install Tooling and Dependencies
#
#	This project uses Docker and it is expected to be installed. Please provide
#	Docker at least 4 CPUs. To use Podman instead please alias Docker CLI to
#	Podman CLI or symlink the Docker socket to the Podman socket. More
#	information on migrating from Docker to Podman can be found at
#	https://podman-desktop.io/docs/migrating-from-docker.
#
#	Run these commands to install everything needed.
#	$ make dev-docker
#	$ make dev-gotooling

# ==============================================================================
# Running The Project
#
#	$ make dev-up
#	$ make dev-update-apply
#	$ make token
#	$ export TOKEN=<token>
#	$ make users
#
#	You can use `make dev-status` to look at the status of your KIND cluster.

# ==============================================================================
# CLASS NOTES
#
# Kind
# 	For full Kind v0.28 release notes: https://github.com/kubernetes-sigs/kind/releases/tag/v0.28.0
#

# ==============================================================================
# Define dependencies

GOLANG          	:= golang:1.24
ALPINE          	:= alpine:3.21
KIND            	:= kindest/node:v1.32.5
POSTGRES        	:= postgres:17.5
GRAFANA         	:= grafana/grafana:12.0.0
PROMETHEUS      	:= prom/prometheus:v3.4.0

KIND_CLUSTER    	:= stacknite-cluster
NAMESPACE       	:= stacknite-system
BASE_IMAGE_NAME 	:= localhost/stacknite
VERSION         	:= 0.0.1

WEBDETECT_APP			:= webdetect
WEBDETECT_IMAGE	:= $(BASE_IMAGE_NAME)/$(WEBDETECT_APP):$(VERSION)

# ==============================================================================
# Install dependencies

dev-gotooling:
	go install honnef.co/go/tools/cmd/staticcheck@latest
	go install golang.org/x/vuln/cmd/govulncheck@latest
	go install golang.org/x/tools/cmd/goimports@latest

dev-docker:
	docker pull $(GOLANG) & \
	docker pull $(ALPINE) & \
	docker pull $(KIND) & \
	docker pull $(POSTGRES) & \
	wait;

# ==============================================================================
# Building containers

build: webdetect

webdetect:
	docker build \
		-f zarf/docker/dockerfile.webdetect \
		-t $(WEBDETECT_IMAGE) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
		.

# ==============================================================================
# Running from within k8s/kind

dev-up:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/dev/kind-config.yaml

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

	kind load docker-image $(POSTGRES) --name $(KIND_CLUSTER) & \
	wait;

dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

dev-status-all:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

dev-status:
	watch -n 2 kubectl get pods -o wide --all-namespaces

# ------------------------------------------------------------------------------

dev-load:
	kind load docker-image $(WEBDETECT_IMAGE) --name $(KIND_CLUSTER) & \
	wait;

dev-apply:
	kustomize build zarf/k8s/dev/database | kubectl apply -f -
	kubectl rollout status --namespace=$(NAMESPACE) --watch --timeout=120s sts/database

	kustomize build zarf/k8s/dev/webdetect | kubectl apply -f -
	kubectl wait pods --namespace=$(NAMESPACE) --selector app=$(WEBDETECT_APP) --timeout=120s --for=condition=Ready

dev-restart:
	kubectl rollout restart deployment $(WEBDETECT_APP) --namespace=$(NAMESPACE)

dev-run: build dev-up dev-load dev-apply

dev-update: build dev-load dev-restart

dev-update-apply: build dev-load dev-apply

# ------------------------------------------------------------------------------

dev-logs: dev-logs-webdetect dev-logs-db dev-logs-grafana

dev-logs-webdetect:
	kubectl logs --namespace=$(NAMESPACE) -l app=$(WEBDETECT_APP) --all-containers=true -f --tail=100 --max-log-requests=6 | go run api/tooling/logfmt/main.go -service=$(WEBDETECT_APP)

dev-logs-db:
	kubectl logs --namespace=$(NAMESPACE) -l app=database --all-containers=true -f --tail=100

dev-logs-grafana:
	kubectl logs --namespace=$(NAMESPACE) -l app=grafana --all-containers=true -f --tail=100

# ------------------------------------------------------------------------------

dev-services-delete:
	kustomize build zarf/k8s/dev/webdetect | kubectl delete -f -


# ==============================================================================
# Docker Compose

# ==============================================================================
# Administration

# ==============================================================================
# Metrics and Tracing

# ==============================================================================
# Running tests within the local computer

# ==============================================================================
# Hitting endpoints

# ==============================================================================
# Modules support

tidy:
	go mod tidy
	go mod vendor

# ==============================================================================
# Class Stuff

# ==============================================================================
# Talk commands

# ==============================================================================
# Admin Frontend

# ==============================================================================
# Help command
help:
	@echo "Usage: make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  dev-gotooling           Install Go tooling"
	@echo "  dev-docker              Pull Docker images"
	@echo "  build                   Build all the containers"
	@echo "  webdetect               Build the webdetect container"
	@echo "  dev-up                  Start the KIND cluster"
	@echo "  dev-down                Stop the KIND cluster"
	@echo "  dev-status-all          Show the status of the KIND cluster"
	@echo "  dev-status              Show the status of the pods"
	@echo "  dev-load                Load the containers into KIND"
	@echo "  dev-apply               Apply the manifests to KIND"
	@echo "  dev-restart             Restart the deployments"
	@echo "  dev-run              	 Build, up, load, and apply the deployments"
	@echo "  dev-update              Build, load, and restart the deployments"
	@echo "  dev-update-apply        Build, load, and apply the deployments"
	@echo "  dev-logs                Show the logs for all the services"
	@echo "  dev-logs-webdetect      Show the logs for the webdetect service"
	@echo "  dev-logs-db             Show the logs for the db service"
	@echo "  dev-logs-grafana        Show the logs for the grafana service"
	@echo "  dev-services-delete     Delete all"
	@echo "  tidy                    Run go tidy and vendor"