# CLAUDE.md

Este arquivo é a entrada para o Claude Code. Ele aponta para a constituição do projeto.

> Leia primeiro: [.agent/CONSTITUTION.md](.agent/CONSTITUTION.md)

Atalhos importantes:

- Regras universais: `.agent/rules/`
- Procedimentos sob demanda: `.agent/skills/`
- Subagents: `.agent/agents/`
- Hooks (guardrails determinísticos): `.agent/hooks/`
- Specs (uma por feature): `specs/`
- ADRs (decisões arquiteturais): `specs/adrs/`
- Contrato OpenAPI: `docs/api/openapi.yaml`

## Comandos mais comuns neste repo

```bash
make setup       # instala deps
make dev         # sobe api + web
make test        # roda todos os testes
make lint        # lint Go + JS
make validate    # spec ↔ código
```

## Antes de codificar uma feature

1. Encontre a spec em `specs/<id>-<slug>/spec.md`
2. Releia a constituição se faz mais de 24h que abriu o repo
3. Use **plan mode** se a tarefa toca mais de um arquivo
4. Atualize `docs/api/openapi.yaml` **antes** do código quando mudar superfície de API

## Quando estiver em dúvida

Pergunte ao humano. Não invente. A constituição autoriza explicitamente a resposta "não sei".
