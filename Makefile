.DEFAULT_GOAL := help
VENV_FOLDER := .venv
VENV_PATH := $(shell pwd)/$(VENV_FOLDER)
VENV_BIN := $(VENV_PATH)/bin
PYTHON := $(VENV_BIN)/python
PACKAGER := uv
PROJECT_NAME := "webhook-fail2ban-irc"
PROJECT_PORT_SRC := 8001
PROJECT_PORT_DST := 8000
IRC_CHANNEL := "fail2ban"

help:
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##)|(^##)' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "; printf "Usage: make \033[32m<target>\033[0m\n"}{printf "\033[32m%-20s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m## /\n[33m/'

install: install_uv ## Install dependencies
	$(PACKAGER) sync

install_dev: install_uv ## Install development dependencies
	$(PACKAGER) sync --dev

install_uv: ## Install the packager
	@if ! command -v uv >/dev/null 2>&1; then \
		if ! command -v curl >/dev/null 2>&1; then \
			echo "curl could not be found, please install it first."; \
			exit 1; \
		else \
			echo "Installing uv..."; \
			curl -LsSf https://astral.sh/uv/install.sh | sh; \
		fi; \
	else \
		echo "uv is already installed."; \
	fi


create_venv: ## Create virtual environment
	@if [ ! -d "$(VENV_FOLDER)" ]; then \
		if ! command -v python &> /dev/null; then \
			python3 -m venv $(VENV_FOLDER); \
		else \
			python -m venv $(VENV_FOLDER); \
		fi \
	else \
		echo "Virtual environment already exists at $(VENV_PATH)"; \
	fi

venv: create_venv ## Load virtual environment
	. $(VENV_BIN)/activate

serve: venv install ## Run a local server
	. $(VENV_BIN)/activate; $(PYTHON) src/main.py

build: 
	docker rm -f $(PROJECT_NAME) || true
	docker rmi $(PROJECT_NAME) || true
	docker system prune -f
	docker build -t $(PROJECT_NAME) -f docker/Dockerfile .

run: build
	docker rm -f $(PROJECT_NAME) || true
	docker run -d --name $(PROJECT_NAME) -p $(PROJECT_PORT_SRC):$(PROJECT_PORT_DST) -e "TZ=Europe/Paris" -e "IRC_SERVER=192.168.1.17" -e "IRC_CHANNEL=#$(IRC_CHANNEL)" $(PROJECT_NAME)


