# Constituição do Projeto: scaffolding-go-react

> Este arquivo é lido pelo agente no início de **toda** conversa. Mantenha curto e denso.

## Missão

Aplicação web de exemplo que demonstra Spec-Driven Development com agentes de AI, em um stack Go + React separado por contrato OpenAPI.

## Decisões irreversíveis (não revisitar sem ADR)

- **Backend**: Go 1.22+ (módulos, sem `gopath`). Router `chi`, SQL via `sqlc`. Sem ORM com magia. Ver `specs/adrs/0001-stack-choice.md`.
- **Frontend**: React 18 + TypeScript estrito (`strict: true`, `noUncheckedIndexedAccess: true`). Vite. Estado de servidor via TanStack Query. Sem Redux global.
- **Banco**: PostgreSQL 16. Migrations forward-only via `golang-migrate`.
- **API**: REST com OpenAPI 3.1 em `docs/api/openapi.yaml`. Toda mudança de superfície atualiza o contrato **antes** do código.
- **Erros**: envelope `Result<T, E>` (ver `apps/api/internal/http/response/`). Nunca retornar `{ error: "..." }` solto. Ver ADR-0003.
- **Auth**: OAuth2 + PKCE (não implementado neste exemplo, mas decidido).

## Estilo de código

- **Go**: `gofmt`, `go vet`, `golangci-lint` (config em `apps/api/.golangci.yml`). Funções pequenas, erros como valores, sem `panic` fora de `main`.
- **TS**: ESLint strict, sem `any` (use `unknown` + narrowing). Componentes funcionais com hooks. Sem `useEffect` para data fetching — use TanStack Query.
- Nome de teste descreve **comportamento**, não implementação.

## Comandos essenciais

| Comando | O que faz |
|---|---|
| `make setup` | Instala dependências de api + web |
| `make dev` | Sobe backend (`:8080`) e frontend (`:5173`) em paralelo |
| `make test` | `go test ./...` + `pnpm -r test` |
| `make lint` | `golangci-lint run` + `pnpm -r lint` |
| `make typecheck` | `tsc --noEmit` em todos os pacotes JS |
| `make validate` | Valida código contra OpenAPI |
| `make migrate-up` | Aplica migrations no DB local |

## Workflow obrigatório

1. **Ler a spec** da feature antes de codificar (em `specs/<id>-<slug>/spec.md`)
2. **Plan mode** antes de editar mais de um arquivo
3. **Atualizar OpenAPI primeiro** quando mudar superfície de API
4. **Testes acompanham o commit** (mesmo PR) — não há "testes na próxima sprint"
5. **Subagent `spec-verifier`** roda antes de abrir PR

## Onde encontrar

- Specs por feature: `specs/<id>-<slug>/`
- ADRs: `specs/adrs/`
- Glossário de domínio: `docs/domain/glossary.md`
- Padrões de código: `.agent/rules/`
- Procedimentos: `.agent/skills/`

## O que evitar

- **Não use `any` em TS** — prefira `unknown` + narrowing
- **Não use `interface{}` em Go** salvo em testes ou plumbing — prefira generics ou tipos concretos
- **Não invente libs** — verifique `go.mod`/`package.json` antes de importar
- **Não crie arquivos fora de `apps/`, `specs/`, `docs/` ou `.agent/`** sem instrução explícita
- **Não rode** `rm -rf` fora de `dist/`, `build/`, `node_modules/` ou `/tmp`
- **Não rode** migrations destrutivas (`DROP TABLE`, `TRUNCATE`) fora de bancos `*_test`
- **Não use `git push --force`** em `main` ou `release/*`
- **Não publique pacotes** (`npm publish`, `goreleaser release`) — releases são via GitHub Actions

## Quando dizer "não sei"

Se a spec é ambígua, **pare e pergunte**. Não invente comportamento. Não invente nomes de campo, códigos de erro ou contratos de API — leia do OpenAPI.

## Hooks ativos neste repo (3 camadas)

Este repositório aplica defesa em profundidade. Você não consegue ignorar nenhuma delas:

1. **Claude Code hooks** — `.claude/settings.json` registra `.agent/hooks/pre-tool-use.sh` (bloqueia comandos destrutivos antes da execução) e `.agent/hooks/post-tool-use.sh` (roda lint/format/vet em cada edição). Bloqueios chegam como `exit 2` e você vê o motivo em stderr — leia e ajuste o approach.
2. **Git hooks (lefthook)** — `lefthook.yml` roda em pre-commit (lint do staged), pre-push (testes) e commit-msg (Conventional Commits). Mesmo que você passe pelos hooks do Claude Code, o commit pode ser barrado aqui.
3. **CI (GitHub Actions)** — `.github/workflows/ci.yml` repete todas as checagens contra `main`. Última barreira antes do merge.

Para flags de bypass (raras, para casos específicos), veja `.agent/rules/99-forbidden.md` — sempre exigem aprovação humana explícita no chat.

## Contexto

- Este repositório segue o relatório `relatorio-boas-praticas-projeto-ai-spec-driven.md` (raiz)
- A constituição (este arquivo) é a única fonte de regras universais. Detalhes específicos vão em `.agent/rules/` ou skills.
