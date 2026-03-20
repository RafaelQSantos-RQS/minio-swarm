.DEFAULT_GOAL := help

ifneq (,$(wildcard ./.env))
	include ./.env
	export
endif

ENV_FILE         = .env
ENV_TEMPLATE     = .env.template
DOCKER_NETWORK   = swarm-net
STACK_NAME       = s3

define log
	echo "[$$(date '+%Y-%m-%d %H:%M:%S')] $(1)"
endef

.PHONY: help setup \
	deploy remove status logs pull validate

help: ## 🤔 Show this help message
	@echo ""
	@echo "  ╔══════════════════════════════════════════════════════════════════╗"
	@echo "  ║                     MINIO SWARM MANAGEMENT                       ║"
	@echo "  ╚══════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "  📋  SETUP"
	@echo "  ────────────────────────────────────────────────────────────────────"
	@echo "    make setup              Generate .env from template"
	@echo ""
	@echo "  🚀  DEPLOY"
	@echo "  ────────────────────────────────────────────────────────────────────"
	@echo "    make deploy             Deploy MinIO stack to Swarm"
	@echo "    make remove             Remove MinIO stack from Swarm"
	@echo "    make status             Show stack status"
	@echo "    make logs               Show MinIO logs"
	@echo "    make pull               Pull latest images"
	@echo "    make validate           Validates the matching of the compose file with the env file"
	@echo ""
	@echo "  ────────────────────────────────────────────────────────────────────"
	@echo "  Prerequisites:"
	@echo "    - Copy .env.template to .env and configure"
	@echo "    - Ensure $(DOCKER_NETWORK) network exists in the cluster"
	@echo ""

setup: ## 📋 Generate .env from template
	@$(call log,Checking if network $(DOCKER_NETWORK) exists...)
	@docker network inspect $(DOCKER_NETWORK) >/dev/null 2>&1 || \
		$(call log,❌ Network $(DOCKER_NETWORK) not found. Please create it in your cluster.)

	@if [ ! -f $(ENV_FILE) ]; then \
		if [ -f $(ENV_TEMPLATE) ]; then \
			$(call log,Generating $(ENV_FILE) from template); \
			cp $(ENV_TEMPLATE) $(ENV_FILE); \
			$(call log,⚠️ Please edit $(ENV_FILE) and run 'make setup' again); \
			exit 1; \
		else \
			$(call log,❌ No $(ENV_TEMPLATE) found. Cannot continue.); \
			exit 1; \
		fi \
	else \
		$(call log,$(ENV_FILE) already exists); \
	fi
	@$(call log,Setup completed)

deploy: ## 🚀 Deploy MinIO to Swarm
	@$(call log,Deploying MinIO to Swarm...)
	@if [ -f $(ENV_FILE) ]; then \
		export $$(cat $(ENV_FILE) | xargs) && docker stack deploy --with-registry-auth --detach=true -c docker-stack.yaml $(STACK_NAME); \
	else \
		$(call log,❌ $(ENV_FILE) not found. Run 'make setup' first.); \
		exit 1; \
	fi
	@$(call log,MinIO deployed to Swarm)

remove: ## 🗑️ Remove MinIO from Swarm
	@$(call log,Removing MinIO from Swarm...)
	@docker stack rm $(STACK_NAME)
	@$(call log,MinIO removed from Swarm)

status: ## 📊 Show stack status
	@docker stack ps $(STACK_NAME)

logs: ## 📜 Show MinIO logs
	@docker service logs $(STACK_NAME)_minio -f

pull: ## 📦 Pull latest images
	@$(call log,Pulling latest images...)
	@docker pull quay.io/minio/aistor/minio:latest
	@$(call log,Images pulled)

validate:
	@$(call log,Validating the configuration. Please pay attention...)
	@if [ -f $(ENV_FILE) ]; then \
		export $$(cat $(ENV_FILE) | xargs) && docker stack config --compose-file docker-stack.yaml; \
	else \
		$(call log,❌ $(ENV_FILE) not found. Run 'make setup' first.); \
		exit 1; \
	fi
