ifndef APPLICATION_CONFIG
	# Determine which .env file to use
	ifneq ("$(wildcard .env.local)", "")
		include .env.local
	else
		include .env
	endif
endif

ifdef GITHUB_WORKFLOW
	INSIDE_DOCKER = 1
else ifneq ("$(wildcard /.dockerenv)", "")
	INSIDE_DOCKER = 1
else
	INSIDE_DOCKER = 0
endif

# Global variables that we're using
HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)

WARNING_HOST = @printf "\033[31mThis command cannot be run inside docker container!\033[39m\n"
WARNING_DOCKER = @printf "\033[31mThis command must be run inside docker container!\nUse 'make bash' command to get shell inside container.\033[39m\n"

.DEFAULT_GOAL := help
.PHONY: help

help:
	@grep -E '^[a-zA-Z-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "[32m%-27s[0m %s\n", $$1, $$2}'

CONSOLE := $(shell which bin/console)
sf_console:
ifndef CONSOLE
	@printf "Run \033[32mcomposer require cli\033[39m to install the Symfony console.\n"
endif

cache-clear: ## Clears the cache
ifdef CONSOLE
	@bin/console cache:clear --no-warmup
else
	@rm -rf var/cache/*
endif
.PHONY: cache-clear

cache-warmup: cache-clear ## Warms up an empty cache
ifdef CONSOLE
	@bin/console cache:warmup
else
	@printf "Cannot warm up the cache (needs symfony/console).\n"
endif
.PHONY: cache-warmup

lint-yaml: ## Lint config YAML files
ifeq ($(INSIDE_DOCKER), 1)
	@echo "\033[32mLinting YAML config files\033[39m"
	@@bin/console lint:yaml config --parse-tags
else
	$(WARNING_DOCKER)
endif

update: ## Update composer dependencies
ifeq ($(INSIDE_DOCKER), 1)
	@php -d memory_limit=-1 /usr/bin/composer update
else
	$(WARNING_DOCKER)
endif

bash: ## Get bash inside PHP container
ifeq ($(INSIDE_DOCKER), 1)
	$(WARNING_HOST)
else
	@HOST_UID=$(HOST_UID) HOST_GID=$(HOST_GID) docker-compose exec php bash
endif

start: ## Start application in development mode
ifeq ($(INSIDE_DOCKER), 1)
	$(WARNING_HOST)
else
	@HOST_UID=$(HOST_UID) HOST_GID=$(HOST_GID) docker-compose up
endif

start-build: ## Start application in development mode and build containers
ifeq ($(INSIDE_DOCKER), 1)
	$(WARNING_HOST)
else
	@HOST_UID=$(HOST_UID) HOST_GID=$(HOST_GID) docker-compose up --build
endif

stop: ## Stop application containers
ifeq ($(INSIDE_DOCKER), 1)
	$(WARNING_HOST)
else
	@HOST_UID=$(HOST_UID) HOST_GID=$(HOST_GID) docker-compose down
endif

psalm: ## Runs Psalm static analysis tool
ifeq ($(INSIDE_DOCKER), 1)
	@echo "\033[32mRunning Psalm - A static analysis tool for PHP\033[39m"
	@mkdir -p build
	@@bin/console cache:clear --env=dev
	@php ./vendor/bin/psalm --version
	@php ./vendor/bin/psalm --no-cache --report=./build/psalm.json
else
	$(WARNING_DOCKER)
endif

psalm-info: ## Runs Psalm static analysis tool with extra info
ifeq ($(INSIDE_DOCKER), 1)
	@echo "\033[32mRunning Psalm - A static analysis tool for PHP\033[39m"
	@mkdir -p build
	@@bin/console cache:clear --env=dev
	@php ./vendor/bin/psalm --version
	@php ./vendor/bin/psalm --no-cache --show-info=true --report=./build/psalm.json
else
	$(WARNING_DOCKER)
endif
