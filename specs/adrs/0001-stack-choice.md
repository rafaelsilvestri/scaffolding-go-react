# ADR-0001: Stack Go + chi + sqlc, React + Vite + TanStack Query

**Status:** Accepted
**Data:** 2026-05-09
**Decisores:** Equipe de engenharia

## Contexto

Precisamos escolher stack para um monorepo greenfield que será desenvolvido
predominantemente com agentes de AI. Critérios:

1. Linguagens com tipagem forte (alto sinal para o agente)
2. Bibliotecas com superfície pequena e previsível (baixa "magia" para o agente entender errado)
3. Contratos explícitos entre backend e frontend (OpenAPI)
4. Setup de testes simples (Go test + Vitest)

## Decisão

**Backend:**

- Go 1.22+
- Router: [chi](https://github.com/go-chi/chi) — minimalista, padrão `net/http`
- SQL: [sqlc](https://sqlc.dev) — gera Go type-safe a partir de SQL puro
- Migrations: [golang-migrate](https://github.com/golang-migrate/migrate)
- DB: PostgreSQL 16
- Logs: `log/slog` (stdlib, estruturado)

**Frontend:**

- React 18 + TypeScript estrito
- Build: Vite 5
- Estado de servidor: TanStack Query
- Cliente HTTP: `openapi-fetch` + tipos gerados de `openapi-typescript`
- Testes: Vitest + React Testing Library + MSW + Playwright

## Alternativas consideradas

### Backend

| Alternativa | Por que rejeitada |
|---|---|
| Echo + GORM | GORM tem comportamento implícito (lazy loading, hooks) que confunde agentes |
| Gin + sqlx | Boa, mas chi é mais idiomático em relação a `net/http` |
| Fiber | API divergente do `net/http` — perde compatibilidade com middlewares stdlib |
| stdlib pura | Plausível, mas chi adiciona patterns de routing minimalistas e expressivos |

### Frontend

| Alternativa | Por que rejeitada |
|---|---|
| Next.js 15 | SSR/RSC não é necessário aqui — adiciona complexidade |
| Remix | Bom, mas TanStack Query + Vite é mais simples e amplamente adotado |
| Redux Toolkit Query | Mais código boilerplate; TanStack Query tem ergonomia melhor |
| SWR | Funciona, mas TanStack Query tem ecossistema mais maduro |

## Consequências

**Positivas:**

- Cada parte do stack é "lê o código e entendi" — bom para agentes
- Zero magia de runtime — toda transformação é em build/codegen
- Tipagem ponta a ponta via OpenAPI

**Negativas:**

- Mais boilerplate inicial que frameworks "full-service"
- Decisões adicionais necessárias (routing front-end, validation library, etc.) — registradas em ADRs subsequentes

## Implicações para o agente de AI

- Quando criar endpoint, sempre passe pelo gerador sqlc — não escreva código de DB à mão
- Quando consumir API no front, use o cliente gerado — não invente paths
- A skill `criar-endpoint-rest` cobre o procedimento completo
