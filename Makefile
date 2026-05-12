# Makefile raiz — orquestra apps/api (Go) e apps/web (React) no monorepo.

API_DIR  := apps/api
WEB_DIR  := apps/web

.DEFAULT_GOAL := help

help: ## lista targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- setup ---------------------------------------------------------------

setup: ## instala todas as dependências + ativa hooks
	$(MAKE) -C $(API_DIR) deps
	cd $(WEB_DIR) && pnpm install
	$(MAKE) hooks-install

hooks-install: ## ativa hooks do agente (Claude Code) + git (lefthook)
	@if [ ! -f .claude/settings.json ] && [ -f claude-settings.json.example ]; then \
	  mkdir -p .claude && cp claude-settings.json.example .claude/settings.json; \
	  echo "criado .claude/settings.json a partir do exemplo"; \
	fi
	chmod +x .agent/hooks/*.sh
	@if command -v lefthook >/dev/null 2>&1; then \
	  lefthook install; \
	else \
	  echo "AVISO: lefthook não instalado. Instale com 'brew install lefthook' ou 'go install github.com/evilmartians/lefthook@latest'"; \
	fi
	@echo
	@echo "Hooks ativos:"
	@echo "  • Claude Code: .claude/settings.json → .agent/hooks/{pre,post}-tool-use.sh"
	@echo "  • Git (lefthook): lefthook.yml (pre-commit, pre-push, commit-msg)"
	@echo "  • CI: .github/workflows/{ci,security}.yml"

hooks-test: ## testa os hooks com payloads de exemplo
	@echo ">> testando pre-tool-use.sh com comando rm -rf perigoso (deve BLOQUEAR)"
	@echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /etc"}}' | .agent/hooks/pre-tool-use.sh && echo "FALHOU: deveria ter bloqueado" || echo "OK: bloqueou"
	@echo
	@echo ">> testando pre-tool-use.sh com comando benigno (deve PERMITIR)"
	@echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | .agent/hooks/pre-tool-use.sh && echo "OK: permitiu" || echo "FALHOU: bloqueou indevidamente"

# --- dev -----------------------------------------------------------------

dev: ## sobe backend e frontend em paralelo
	@echo ">> backend: :8080  |  frontend: :5173"
	@(trap 'kill 0' INT; \
	  $(MAKE) -C $(API_DIR) run & \
	  cd $(WEB_DIR) && pnpm dev & \
	  wait)

dev-api: ## sobe apenas o backend
	$(MAKE) -C $(API_DIR) run

dev-web: ## sobe apenas o frontend
	cd $(WEB_DIR) && pnpm dev

# --- test ----------------------------------------------------------------

test: test-api test-web ## roda todos os testes

test-api: ## testes Go
	$(MAKE) -C $(API_DIR) test

test-web: ## testes JS/TS (vitest)
	cd $(WEB_DIR) && pnpm test

test-e2e: ## Playwright (precisa de api + web rodando)
	cd $(WEB_DIR) && pnpm test:e2e

# --- lint / typecheck ----------------------------------------------------

lint: lint-api lint-web ## linters em todos os apps

lint-api: ## golangci-lint
	$(MAKE) -C $(API_DIR) lint

lint-web: ## eslint
	cd $(WEB_DIR) && pnpm lint

typecheck: ## tsc + go vet
	$(MAKE) -C $(API_DIR) vet
	cd $(WEB_DIR) && pnpm typecheck

fmt: ## formata todo código
	$(MAKE) -C $(API_DIR) fmt
	cd $(WEB_DIR) && pnpm format

# --- contrato ------------------------------------------------------------

validate: validate-openapi gen-api-types typecheck ## valida spec ↔ código

validate-openapi: ## lint do OpenAPI (requer spectral)
	@command -v spectral >/dev/null 2>&1 || (echo "instale: npm i -g @stoplight/spectral-cli" && exit 1)
	spectral lint docs/api/openapi.yaml

gen-api-types: ## regenera tipos do frontend a partir do OpenAPI
	cd $(WEB_DIR) && pnpm gen:api

# --- segurança -----------------------------------------------------------

vuln: ## checa vulnerabilidades (govulncheck + pnpm audit)
	$(MAKE) -C $(API_DIR) vuln
	cd $(WEB_DIR) && pnpm audit --prod || true

# --- build ---------------------------------------------------------------

build: ## compila todos os apps
	$(MAKE) -C $(API_DIR) build
	cd $(WEB_DIR) && pnpm build

# --- DB ------------------------------------------------------------------

db-up: ## sobe Postgres local via docker compose
	docker compose up -d db

db-down: ## para Postgres local
	docker compose down

migrate-up: ## aplica migrations no DB local
	$(MAKE) -C $(API_DIR) migrate-up

migrate-create: ## cria migration (uso: make migrate-create NAME=add_users)
	$(MAKE) -C $(API_DIR) migrate-create NAME=$(NAME)

# --- agentes -------------------------------------------------------------

hooks-enable: hooks-install ## (alias) ativa hooks — preferir 'hooks-install'

clean: ## limpa artefatos
	$(MAKE) -C $(API_DIR) clean
	rm -rf $(WEB_DIR)/dist $(WEB_DIR)/node_modules/.vite

.PHONY: help setup dev dev-api dev-web test test-api test-web test-e2e \
        lint lint-api lint-web typecheck fmt validate validate-openapi \
        gen-api-types vuln build db-up db-down migrate-up migrate-create \
        hooks-install hooks-test hooks-enable clean
