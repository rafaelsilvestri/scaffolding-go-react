# Pull Request

## Resumo
<!-- 1-3 frases. O que mudou e por quê. -->

## Spec
<!-- Link para specs/<id>-<slug>/spec.md. Se não há spec, justifique abaixo. -->

- Spec: `specs/...`
- ADRs aplicáveis: ADR-XXXX

## Tipo de mudança
- [ ] feat — nova feature (atualiza spec)
- [ ] fix — correção de bug (atualiza spec se mudou requisito)
- [ ] refactor — mudança interna sem alterar comportamento
- [ ] docs — apenas documentação
- [ ] chore — build, deps, infra
- [ ] breaking — quebra de contrato (exige ADR)

## Critérios de aceitação cobertos
<!-- Cite cada AC da spec e o teste correspondente. -->
- [ ] AC1 — `arquivo:linha` do teste
- [ ] AC2 — ...

## Checklist do autor

### Sempre
- [ ] Constituição (`.agent/CONSTITUTION.md`) lida nos últimos 30 dias
- [ ] `make test` verde local
- [ ] `make lint` verde local
- [ ] `make typecheck` verde local
- [ ] Sem `any` em TS, sem `interface{}` injustificado em Go
- [ ] Sem secrets em código

### Se mudou superfície de API
- [ ] `docs/api/openapi.yaml` atualizado **antes** do código
- [ ] `make gen-api-types` rodado e tipos do frontend regenerados
- [ ] `make validate-openapi` passa

### Se mudou schema de DB
- [ ] Migration nova em `apps/api/migrations/` (não editou existente)
- [ ] `make migrate-up` e `make migrate-down` testados localmente
- [ ] Se destrutiva: `AGENT_DESTRUCTIVE_MIGRATION=1` documentado e aprovado

### Se adicionou dependência
- [ ] Justificativa abaixo
- [ ] `make vuln` sem novas vulnerabilidades

### Se gerado por agente de AI
- [ ] Subagent `spec-verifier` rodado — relatório em comentário
- [ ] Subagent `reviewer` rodado para mudanças não-triviais
- [ ] `security-auditor` rodado se tocou auth/SQL/uploads

## Riscos / pontos para revisor focar

<!-- O que você pediria para um colega olhar com cuidado? -->

## Como testar manualmente
<!-- Passos para o revisor reproduzir. -->

```bash
# exemplos
make dev
curl http://localhost:8080/healthz
```
