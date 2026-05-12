# Makefile do backend Go (apps/api)
# Use a partir do raiz: `make -C apps/api <target>`

GO        := go
GOFLAGS   := -trimpath
LDFLAGS   := -s -w -X main.version=$(shell git describe --tags --always --dirty 2>/dev/null || echo dev)

.DEFAULT_GOAL := help

help: ## lista targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

deps: ## baixa dependências
	$(GO) mod download

build: ## compila o servidor
	$(GO) build $(GOFLAGS) -ldflags="$(LDFLAGS)" -o bin/server ./cmd/server

run: ## sobe o servidor localmente (porta 8080)
	$(GO) run ./cmd/server

test: ## roda testes unitários e de integração
	$(GO) test -race -count=1 ./...

test-cover: ## roda testes com cobertura
	$(GO) test -race -count=1 -coverprofile=coverage.out ./...
	$(GO) tool cover -func=coverage.out

lint: ## golangci-lint (instale com: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest)
	golangci-lint run

fmt: ## formata o código
	$(GO) fmt ./...
	@command -v goimports >/dev/null 2>&1 && goimports -w -local github.com/example/scaffolding . || true

vet: ## go vet
	$(GO) vet ./...

vuln: ## checa vulnerabilidades (instale com: go install golang.org/x/vuln/cmd/govulncheck@latest)
	govulncheck ./...

sqlc: ## gera código a partir de db/queries/
	sqlc generate

migrate-create: ## cria par up/down (uso: make migrate-create NAME=add_users_table)
	@test -n "$(NAME)" || (echo "uso: make migrate-create NAME=descricao" && exit 1)
	@mkdir -p migrations
	@ts=$$(date -u +%Y%m%d%H%M%S); \
	  touch "migrations/$${ts}_$(NAME).up.sql" "migrations/$${ts}_$(NAME).down.sql"; \
	  echo "criado: migrations/$${ts}_$(NAME).{up,down}.sql"

migrate-up: ## aplica migrations no DB local
	migrate -database "$$DATABASE_URL" -path migrations up

migrate-down: ## reverte 1 migration (uso local apenas)
	migrate -database "$$DATABASE_URL" -path migrations down 1

clean: ## remove artefatos
	rm -rf bin/ coverage.out

.PHONY: help deps build run test test-cover lint fmt vet vuln sqlc migrate-create migrate-up migrate-down clean
