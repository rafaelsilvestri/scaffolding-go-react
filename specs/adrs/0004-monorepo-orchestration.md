# ADR-0004: Monorepo orquestrado por Makefile + pnpm workspaces simples

**Status:** Accepted
**Data:** 2026-05-09

## Contexto

Precisamos de uma forma de orquestrar comandos entre `apps/api` (Go) e
`apps/web` (React) sem adicionar uma ferramenta de monorepo pesada.

## Decisão

- **Make** na raiz orquestra os dois apps (`make test`, `make dev`, `make lint`).
- **pnpm** gerencia o JS (`apps/web`) — não há `apps/web/web2/` no horizonte.
- **Cada app tem seu próprio Makefile** (`apps/api/Makefile`) com targets específicos.
- **Sem Turborepo, Nx ou Rush** nesta fase.

## Por quê

- O agente lê Makefile facilmente — texto declarativo
- Sem cache distribuído / mágica de pipeline para entender
- Sem custo de manutenção de outra ferramenta

## Quando reconsiderar

- Mais de 4 apps simultaneamente
- Tempo de CI > 15min sem cache
- Equipe > 30 pessoas com PRs paralelos

## Implicações

- Targets do Makefile são parte do contrato com o agente — ver constituição
- Mudanças em targets que mudam comando (`make test` deixa de existir) requerem PR + atualização da constituição
