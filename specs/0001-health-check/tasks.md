# Tasks — Health Check Endpoint

## Concluídas

- [x] T0 — `docs/api/openapi.yaml` adiciona `/healthz` e schema `HealthStatus`
- [x] T1 — `apps/api/internal/http/handlers/health.go` com lógica
- [x] T2 — Rota registrada em `apps/api/internal/http/router.go`
- [x] T3 — Teste em `apps/api/internal/http/handlers/health_test.go` cobrindo AC1, AC2, AC3, AC4
- [x] T4 — Frontend: hook `useHealth()` em `apps/web/src/api/health.ts`
- [x] T5 — Componente `<HealthBadge />` em `apps/web/src/components/HealthBadge.tsx`

## Verificação

- [x] `make test` verde
- [x] `spec-verifier` reporta `CONFORMS`
- [ ] Teste de carga local mostra p95 < 50ms (deferred — quando houver infraestrutura de CI dedicada)

## Notas

A tarefa T6 (teste de carga formal) ficou para próxima iteração. Documentado
em ADR-0004 (a criar) caso a equipe queira institucionalizar SLO testing.
