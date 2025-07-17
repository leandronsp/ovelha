SHELL = /bin/bash
.ONESHELL:
.DEFAULT_GOAL: help

help: ## Prints available commands
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[.a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

payment-processor.up: ## Start the payment processor service
	docker compose -f payment-processor/docker-compose.yml up -d

payment-processor.down: ## Stop the payment processor service
	docker compose -f payment-processor/docker-compose.yml down

payment-processor.logs: ## View logs for the payment processor service
	docker compose -f payment-processor/docker-compose.yml logs -f

compose.down:
	@docker-compose down --remove-orphans

compose.logs:
	@docker-compose logs -f

api.setup: ## Set up the API service
	@docker compose build
	@docker-compose run --rm api01 bundle

start.dev: ## Start the development environment
	@docker-compose up -d nginx

docker.stats: ## Show docker stats
	@docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

docker.build: ## Build the docker image
	@docker build -t leandronsp/ovelha --target prod .

docker.push: ## Push the docker image
	@docker push leandronsp/ovelha

health.check: ## Check the stack is healthy
	@curl -v http://localhost:9999/clientes/42/extrato

stress.it: ## Run stress tests
	@sh stress-test/run-test.sh

ovelha: ## Unleash the madness
	@make compose.down
	@make api.setup
	@docker-compose up -d 
	@make docker.stats
