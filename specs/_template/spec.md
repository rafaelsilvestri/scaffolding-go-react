# Spec: <feature>

> Use este template para toda feature não-trivial. Copie para
> `specs/<NNNN-slug>/spec.md` e preencha. Ver §13 do relatório.

**ID:** NNNN
**Status:** draft | approved | implemented | archived
**Owner:** <nome>
**Última revisão:** YYYY-MM-DD

---

## Contexto

2-3 parágrafos sobre o problema, por que resolver agora, e qual o usuário
afetado.

## Outcomes

- [ ] Usuário consegue X em < Y segundos
- [ ] Métrica Z melhora em N%
- [ ] (sempre mensurável; nunca "experiência melhor" sem critério)

## In scope

- ...
- ...

## Out of scope (explícito)

- ...
- ...

## Restrições

- Backward-compat com clientes v1
- p95 < 200ms para o endpoint principal
- Compatível com PostgreSQL 16+

## Decisões já tomadas

- ADR-XXXX: <título>
- ADR-XXXX: <título>

## Tarefas

1. Atualizar `docs/api/openapi.yaml`
2. Criar migration
3. Implementar handler + service
4. Testes de integração
5. Atualizar frontend

## Critérios de aceitação

- [ ] AC1: <descrição testável>
- [ ] AC2: <descrição testável>
- [ ] AC3: <descrição testável>

## Edge cases conhecidos

- O que acontece se Y for nulo?
- O que acontece sob carga > 1000 RPS?
- O que acontece se o DB estiver inacessível?

## Eventos / Logs / Métricas

- `feature.<nome>.created` — emit quando ...
- métrica `<nome>_duration_seconds` (histogram)

## Notas para o agente de AI

- Use a skill `criar-endpoint-rest`
- O Result envelope exige códigos de erro definidos em `domain/errors.go`
- Não invente novos códigos — reuse ou adicione em ADR

## Referências

- <link interno / externo>
