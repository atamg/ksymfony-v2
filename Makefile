.PHONY: up down logs test cs stan help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sed -E 's/:.*##/: /'

up: ## Build & start (Docker Compose)
	docker compose up -d --build

down: ## Stop containers
	docker compose down

logs: ## Tail last 100 lines of logs
	docker compose logs -f --tail=100

test: ## Run PHPUnit tests
	./vendor/bin/phpunit

cs: ## Fix coding standards
	./vendor/bin/php-cs-fixer fix --diff

stan: ## Static analysis with PHPStan
	./vendor/bin/phpstan analyse
