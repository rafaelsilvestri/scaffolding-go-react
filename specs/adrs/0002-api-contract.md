# ADR-0002: REST com OpenAPI 3.1 como contrato

**Status:** Accepted
**Data:** 2026-05-09

## Contexto

Backend Go e frontend React precisam compartilhar a definição de endpoints,
schemas e códigos de erro. O contrato é fundamental para:

- Reduzir alucinação dos agentes (não inventam paths/campos)
- CI poder validar drift entre spec e código
- Frontend poder gerar tipos automaticamente

## Decisão

- **Contrato**: OpenAPI 3.1 em `docs/api/openapi.yaml`
- **Estilo**: REST (recursos + verbos HTTP). Sem GraphQL nesta fase.
- **Geração de tipos no frontend**: `openapi-typescript` + `openapi-fetch`
- **Validação no backend**: `kin-openapi` ou `oapi-codegen` (escolher na primeira feature que precisar)
- **Lint**: [Spectral](https://stoplight.io/open-source/spectral) com regras padrão + customizadas em `.spectral.yaml`

## Regras

1. **Toda mudança de superfície de API atualiza `openapi.yaml` ANTES do código.**
2. **Breaking changes (remoção de campo, mudança de tipo) exigem ADR e versionamento `/v2`.**
3. **Erros sempre usam o schema `Error`** definido no OpenAPI:

```yaml
Error:
  type: object
  required: [code, message]
  properties:
    code: { type: string, example: VALIDATION_FAILED }
    message: { type: string }
    details: { type: object, additionalProperties: true }
    request_id: { type: string }
```

4. **Códigos de erro são string em `SCREAMING_SNAKE_CASE`**, não números.

## Alternativas consideradas

| Alternativa | Por que rejeitada |
|---|---|
| GraphQL | Mais flexível, mas overkill para o tamanho atual; complexa governança de schema |
| gRPC | Bom para microsserviços internos; pior para frontend web |
| JSON-RPC | Sem ferramental maduro de spec |
| Sem contrato (apenas TS shared lib) | Acopla os dois apps; quebra premissa de monorepo desacoplado |

## Implicações para o agente de AI

- O agente lê códigos de erro do `openapi.yaml`. Não inventa.
- Quando o usuário pede "novo endpoint", o agente edita YAML antes de Go.
- A skill `criar-endpoint-rest` codifica esse fluxo.
