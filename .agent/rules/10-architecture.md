# 10 — Arquitetura

## Topologia do monorepo

```
apps/
├── api/    # Go: backend HTTP, fonte da verdade do domínio
└── web/    # React: cliente que consome a API REST

docs/api/openapi.yaml    # Contrato. Os dois lados se conformam a ele.
```

> O contrato OpenAPI é o **único acoplamento permitido** entre `apps/api` e `apps/web`. Não importe nada de um app no outro.

## Backend (apps/api)

Camadas, de fora para dentro:

```
cmd/server/         # Entry point. Wire deps, start server.
internal/
├── http/           # Handlers, middleware, routing. Sem regra de negócio.
│   ├── handlers/
│   ├── middleware/
│   └── response/   # Envelope Result<T, E>, helpers de status code
├── domain/         # Entidades + regras de negócio puras (sem I/O)
├── service/        # Use cases. Orquestra domain + storage.
├── storage/        # Persistência (sqlc-generated + repos)
└── config/         # Carregamento de env vars + validação
```

**Regras**:

1. `domain/` não importa de `http/`, `storage/` ou `service/`
2. `service/` importa `domain/` e `storage/`. Não importa `http/`.
3. `http/` importa `service/`. Não conhece SQL.
4. Dependências fluem **para dentro**. Nunca o inverso.
5. Cada handler tem teste de integração (httptest) cobrindo: caso feliz, validação, erro do serviço.

## Frontend (apps/web)

```
src/
├── api/            # Cliente HTTP gerado a partir do OpenAPI + hooks de query
├── components/     # Componentes reutilizáveis, sem fetch direto
├── features/       # Pastas por feature de produto (login, dashboard, etc.)
│   └── <feature>/
│       ├── components/
│       ├── hooks/
│       └── routes.tsx
├── lib/            # Utilities puras (formatters, validators)
└── App.tsx
```

**Regras**:

1. Componentes em `components/` não fazem fetch — recebem dados via props
2. Data fetching apenas em hooks dentro de `features/<f>/hooks/` ou `api/`
3. Estado de servidor: TanStack Query. Estado local: `useState`/`useReducer`. Nada de Redux.
4. Roteamento: `react-router` ou `tanstack-router` — escolha definida no ADR-0002

## Contrato e geração de tipos

- Source of truth: `docs/api/openapi.yaml`
- Backend gera handlers stubs com `oapi-codegen` (opcional)
- Frontend gera types e funções com `openapi-typescript` + `openapi-fetch`
- CI valida: spec → tipos gerados → código compila → testes passam

## Migrations

- Pasta: `apps/api/migrations/`
- Forward-only. Nunca editar uma migration aplicada — crie uma nova.
- Nome: `YYYYMMDDHHMM_<descricao>.up.sql` e `.down.sql`
- `down.sql` existe para emergências locais. Em produção, fazemos forward-fix.

## Observabilidade

- Logs estruturados (`slog` em Go) com correlação por request ID
- Métricas via `/metrics` (Prometheus) — middleware no router
- Traces via OpenTelemetry quando habilitado por env var

## Performance

- Endpoints REST p95 < 200ms para operações de leitura
- N+1 é bug, não otimização — pegue em code review
