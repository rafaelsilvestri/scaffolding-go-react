# apps/api — Backend Go

API HTTP em Go 1.22 usando chi + sqlc + PostgreSQL.

## Estrutura

```
apps/api/
├── cmd/server/             # entry point (main.go)
├── internal/
│   ├── config/             # carregamento de env vars validadas
│   ├── domain/             # entidades + erros sentinela (sem I/O)
│   ├── service/            # use cases (a criar)
│   ├── storage/            # persistência (sqlc + repos) (a criar)
│   └── http/
│       ├── router.go       # composição do chi
│       ├── middleware/     # logger, recovery, security headers
│       ├── handlers/       # um arquivo por recurso
│       └── response/       # envelope de erro + helpers
├── db/queries/             # SQL para sqlc gerar (.sql)
├── migrations/             # forward-only (.up.sql + .down.sql)
├── sqlc.yaml
├── .golangci.yml
├── go.mod
├── Dockerfile
└── Makefile
```

## Rodando local

```bash
# 1. Sobre Postgres (ver docker-compose na raiz, se houver)
# 2. Defina DATABASE_URL=postgres://user:pass@localhost:5432/app
make deps
make run        # :8080
```

## Testes

```bash
make test       # com -race
make test-cover # cobertura
```

## Convenções

- **Pacote = uma responsabilidade.** Sem `utils/`, `helpers/`.
- **`internal/`** para tudo que não deve ser importado por outros módulos.
- **Erros**: `fmt.Errorf("contexto: %w", err)`. Sentinela em `domain/errors.go`.
- **Logs**: `log/slog`. Sem `fmt.Println` em código de produção.
- **Sem `panic` fora de `main`** ou inicialização não-recuperável.

## Quando adicionar dependência

- Justifique no PR (link para uso, comparação com alternativa, manutenção)
- Rode `make vuln` para checar CVEs
- ADR se for crítica (DB driver, framework HTTP, lib de cripto)
