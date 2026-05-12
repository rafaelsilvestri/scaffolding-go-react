# Prompt template — Plan mode

Use **antes** de qualquer mudança que toque mais de um arquivo.

---

## Você

Você está em plan mode. **Não edite arquivos.** Sua saída é um plano que será
revisado por um humano antes de você executar.

## Contexto que você DEVE carregar

1. `.agent/CONSTITUTION.md`
2. A spec da feature: `specs/<id>-<slug>/spec.md`
3. ADRs relevantes (cite os IDs no plano)
4. Resultado do `research.md` se já houver

## Tarefa

<descrição da mudança>

## Output esperado

```markdown
# Plano: <título>

## Spec referenciada
specs/<id>-<slug>/spec.md (criadores dos critérios de aceitação)

## ADRs aplicáveis
- ADR-XXXX: <razão>

## Mudanças por arquivo
| Arquivo | Tipo | Descrição |
|---|---|---|
| docs/api/openapi.yaml | edit | adiciona POST /users |
| apps/api/internal/http/handlers/users.go | new | handler create |
| apps/api/db/queries/users.sql | edit | nova query InsertUser |
| apps/api/migrations/<timestamp>_users.up.sql | new | tabela users |
| apps/web/src/api/users.ts | new | hook useCreateUser |

## Ordem de execução
1. OpenAPI
2. Migration + sqlc
3. Handler + service
4. Testes de integração
5. Frontend
6. Testes de componente

## Riscos
- <risco> → <mitigação>

## Out of scope (explicitamente)
- <coisa que não vai ser feita aqui>

## Critérios de aceitação cobertos
- AC1: ...
- AC2: ...

## Aprovação humana esperada antes de executar
SIM/NÃO — explique
```

## Princípios

- Plano antes de código. **Sempre.**
- Se você descobre que a spec é insuficiente, **pare** e atualize a spec primeiro.
- Não decida sozinho mudanças que afetam contrato (OpenAPI), schema (DB),
  ou nomes em domínio (`internal/domain/`). Sinalize necessidade de ADR.
