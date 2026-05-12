# Spec: Health Check Endpoint

**ID:** 0001
**Status:** approved
**Owner:** @rafael
**Última revisão:** 2026-05-09

---

## Contexto

Como primeira feature deste scaffolding, precisamos de um endpoint `/healthz`
que load balancers e ferramentas de orquestração possam consultar para saber
se a aplicação está saudável. Este é também o exemplo de referência para
todas as features futuras — ele exercita o stack de ponta a ponta (router,
handler, response envelope, teste, OpenAPI, frontend client).

## Outcomes

- [ ] Operadores podem checar saúde da aplicação via HTTP em < 50ms p95
- [ ] Endpoint reporta status do banco de dados (degraded vs unhealthy)
- [ ] Frontend mostra um indicador de status na home

## In scope

- Endpoint `GET /healthz` retornando JSON com `status`, `version`, `uptime_seconds`, `checks.database`
- Página `/` no frontend que consome o endpoint a cada 30s
- Documentação no OpenAPI

## Out of scope (explícito)

- Métricas Prometheus em `/metrics` (próxima spec)
- Liveness vs readiness separados (próxima spec se Kubernetes for usado)
- Alarmes / paging (responsabilidade da plataforma, fora do código)

## Restrições

- p95 < 50ms (timeout em check de DB de 100ms)
- Funciona mesmo com DB caindo — retorna `degraded`, não falha
- Sem autenticação (público para load balancer)

## Decisões já tomadas

- ADR-0001: Stack Go + chi + sqlc
- ADR-0002: REST com OpenAPI 3.1
- ADR-0003: Result envelope para erros (mas sucesso vai direto)

## Tarefas

1. Atualizar `docs/api/openapi.yaml` com `/healthz`
2. Implementar `apps/api/internal/http/handlers/health.go`
3. Registrar rota em `internal/http/router.go`
4. Teste de integração `health_test.go`
5. Atualizar `apps/web/src/api/health.ts` com hook `useHealth()`
6. Componente `<HealthBadge />` no frontend

## Critérios de aceitação

- [ ] **AC1**: `GET /healthz` retorna 200 com JSON contendo `status: "ok" | "degraded"`
- [ ] **AC2**: Quando DB está OK, `status: "ok"` e `checks.database: true`
- [ ] **AC3**: Quando DB está inacessível, `status: "degraded"` e `checks.database: false`, **mas ainda retorna 200** (load balancer mantém o pod por X tentativas)
- [ ] **AC4**: Response inclui `version` (do build) e `uptime_seconds`
- [ ] **AC5**: Frontend mostra badge verde quando `ok`, amarela em `degraded`
- [ ] **AC6**: p95 do endpoint < 50ms (medido em teste de carga local)

## Edge cases conhecidos

- DB demora > 100ms → timeout interno, retornar `degraded`
- Build sem version embedded → reportar `version: "dev"`
- Múltiplas chamadas concorrentes → handler é stateless, sem problema

## Eventos / Logs / Métricas

- log info: `health.check status=<status>` em cada chamada (sample 1%)
- métrica `health_check_duration_seconds` (histograma)

## Notas para o agente de AI

- Use a skill `criar-endpoint-rest`
- Este é o **exemplo de referência** — o código aqui deve ser limpo e copiável
- Status "degraded" não é erro do envelope `Result` — é resposta legítima

## Referências

- ADRs em `specs/adrs/`
- OpenAPI em `docs/api/openapi.yaml`
