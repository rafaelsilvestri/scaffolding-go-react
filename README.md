# Scaffolding Go + React (Spec-Driven)

Monorepo de exemplo demonstrando como aplicar **Spec-Driven Development** com agentes de AI em um projeto Go (backend) + React (frontend), seguindo o relatório de boas práticas em `../relatorio-boas-praticas-projeto-ai-spec-driven.md`.

## Stack

- **Backend** (`apps/api`): Go 1.22, [chi](https://github.com/go-chi/chi) router, [sqlc](https://sqlc.dev) para SQL type-safe, PostgreSQL 16
- **Frontend** (`apps/web`): React 18, TypeScript estrito, Vite, TanStack Query
- **Orquestração**: Makefile + pnpm workspaces
- **Contrato**: OpenAPI 3.1 em `docs/api/openapi.yaml` — fonte da verdade para tipos e testes
- **CI**: GitHub Actions com validação spec ↔ código

## Estrutura

```
.
├── .agent/                # Tudo que orienta o agente de AI
│   ├── CONSTITUTION.md    # Missão, decisões irreversíveis
│   ├── rules/             # Regras lidas em toda sessão
│   ├── skills/            # Procedimentos carregados sob demanda
│   ├── agents/            # Subagents especializados
│   ├── hooks/             # Guardrails determinísticos
│   └── prompts/           # Templates reutilizáveis
├── specs/                 # Specs vivas (uma pasta por feature)
│   ├── _template/
│   ├── 0001-health-check/ # Feature de exemplo
│   └── adrs/              # Architecture Decision Records
├── docs/
│   ├── api/openapi.yaml   # Contrato REST
│   └── domain/glossary.md
├── apps/
│   ├── api/               # Backend Go
│   └── web/               # Frontend React
├── AGENTS.md              # → .agent/CONSTITUTION.md (convenção universal)
├── CLAUDE.md              # → .agent/CONSTITUTION.md (convenção Anthropic)
├── .mcp.json              # MCPs versionados
└── Makefile               # Orquestração do monorepo
```

## Quickstart

```bash
make setup        # instala deps de api + web + ativa hooks (Claude Code + lefthook)
make dev          # sobe backend (:8080) e frontend (:5173)
make test         # roda testes Go + Vitest
make lint         # golangci-lint + eslint
make validate     # contrato OpenAPI ↔ código
make hooks-test   # smoke test dos hooks do agente
```

## Camadas de guardrail (defesa em profundidade)

| Camada | Onde | Quando roda | Como bloqueia |
|---|---|---|---|
| **Claude Code hooks** | `.claude/settings.json` + `.agent/hooks/*.sh` | Antes/depois de cada tool call do agente | `exit 2` + stderr |
| **Git hooks (lefthook)** | `lefthook.yml` | `pre-commit`, `pre-push`, `commit-msg` | exit ≠ 0 aborta o git |
| **CI (GitHub Actions)** | `.github/workflows/{ci,security}.yml` | Push/PR para `main` | bloqueia merge |
| **Code review humano** | `.github/CODEOWNERS` + PR template | Antes de merge | aprovação obrigatória |

Os primeiros dois exemplos em git (`.claude/settings.json` e `.mcp.json`) ficaram como `claude-settings.json.example` e `mcp.json.example` no repo — `make setup` copia para o lugar certo. Isso é uma limitação do ambiente que gerou o scaffolding; em um clone humano você pode versionar `.claude/settings.json` diretamente.

## Como o agente de AI deve operar neste repo

1. Ler `AGENTS.md` no início de toda conversa
2. Antes de codificar uma feature: ler a spec correspondente em `specs/`
3. Mudanças em superfície de API: atualizar `docs/api/openapi.yaml` **antes** do código
4. Plan mode antes de editar mais de um arquivo
5. Cada commit acompanha testes contra os critérios da spec
6. Usar o subagent `spec-verifier` antes de abrir PR

Detalhes em `.agent/CONSTITUTION.md` e `.agent/rules/`.

## Workflow recomendado

```
spec.md → plan.md → tasks.md → implementação → review (subagent) → PR humano
```

A spec é o contrato. O código a implementa. Drift entre os dois é detectado em CI.
