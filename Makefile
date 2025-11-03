.PHONY: help up down restart logs logs-radius logs-postgres shell shell-postgres clean build status

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start all services
	docker-compose up -d

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

build: ## Build the FreeRADIUS image
	docker-compose build

logs: ## Show logs from all services
	docker-compose logs -f

logs-radius: ## Show FreeRADIUS logs only
	docker-compose logs -f freeradius

logs-postgres: ## Show PostgreSQL logs only
	docker-compose logs -f postgres

shell: ## Open a shell in the FreeRADIUS container
	docker-compose exec freeradius /bin/bash

shell-postgres: ## Open a psql shell in the PostgreSQL container
	docker-compose exec postgres psql -U radius -d radius

status: ## Show status of all services
	docker-compose ps

clean: ## Stop and remove all containers, networks, and volumes
	docker-compose down -v

test: ## Test RADIUS authentication with user 'bob'
	docker-compose exec freeradius radtest bob test localhost 0 testing123

debug: ## Start FreeRADIUS in debug mode
	docker-compose exec freeradius radiusd -X
