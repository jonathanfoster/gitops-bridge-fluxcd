SHELL=/usr/bin/env bash -o pipefail
.SHELLFLAGS=-ec

.DEFAULT_GOAL:=help

FLUX_CLUSTER_PATH?=clusters/local
KIND_CLUSTER_NAME?=gitops-bridge-flux

.PHONY: flux-bootstrap
flux-bootstrap: flux-install-operator flux-create-instance ## Bootstrap Flux

.PHONY: flux-install-operator
flux-install-operator: ## Install Flux operator
	helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator -n flux-system --create-namespace

.PHONY: flux-create-instance
flux-create-instance: ## Create Flux instance
	kubectl apply -f ${FLUX_CLUSTER_PATH}/flux-system/flux.yaml

.PHONY: flux-get-all
flux-get-all: ## Get all Flux resources
	flux get all -A

.PHONY: flux-get-failed
flux-get-failed: ## Get failed Flux resources
	flux get all -A --status-selector=ready=false

.PHONY: flux-reconcile
flux-reconcile: ## Reconcile all Flux resources
	flux reconcile source git flux-system
	flux suspend kustomization --all
	flux resume kustomization --all

.PHONY: help
help: ## Show this help message
	@echo "Usage:"
	@echo "  make [target]"
	@echo ""
	@echo "Available Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_0-9-]+:.*?## / {printf "  %-25s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: install-toolchain
install-toolchain: ## Install toolchain
	brew install age
	brew install fluxcd/tap/flux
	brew install helm
	brew install kind
	brew install kubeconform
	brew install kustomize
	brew tap nats-io/nats-tools
	brew install nats-io/nats-tools/nats
	brew install sops
	brew install yamllint
	brew install yq

.PHONY: kind-create-cluster
kind-create-cluster: ## Create kind cluster
	kind create cluster --config=hack/kind.yaml --name=${KIND_CLUSTER_NAME}

.PHONY: kind-delete-cluster
kind-delete-cluster: ## Delete kind cluster
	kind delete cluster --name=${KIND_CLUSTER_NAME}

.PHONY: lint
lint: lint-kustomize lint-yaml ## Lint all files

.PHONY: lint-kustomize
lint-kustomize: ## Lint kustomize files
	./hack/validate.sh

.PHONY: lint-yaml
lint-yaml: ## Lint YAML files
	yamllint .

.PHONY: pre-commit
pre-commit: lint ## Run pre-commit checks
