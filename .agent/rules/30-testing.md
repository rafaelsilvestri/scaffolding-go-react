# 30 — Testing

> Testes acompanham o commit. Sem exceções. PR sem teste = PR rejeitado pelo CI.

## Pirâmide

| Nível | Quem testa | Onde | Quanto |
|---|---|---|---|
| Unit | funções puras de domínio | `*_test.go` ao lado, `*.test.ts` ao lado | 70% |
| Integration | handler + db real ou httpmock | `internal/http/handlers/*_test.go`, `apps/web/src/**/*.integration.test.ts` | 25% |
| E2E | fluxo crítico (login, checkout) | `e2e/` (Playwright) | 5% |

## Backend (Go)

### Convenções

- Mesma pasta do código (`pkg/foo/bar.go` + `pkg/foo/bar_test.go`)
- Nome do teste descreve **comportamento**:
  - ✅ `TestCreateUser_RejectsDuplicateEmail`
  - ❌ `TestCreateUser1`
- `t.Run("subcase")` para variações. Tabela quando há muitas.
- `httptest` para handlers; banco real (com `_test` suffix) para repos.

### Mocks

- Interfaces pequenas + implementação fake escrita à mão > mocks gerados
- Se uma interface tem mais de 5 métodos, ela está grande demais para ser mockada com confiança

### Determinismo

- Sem `time.Now()` direto — injete `Clock` interface
- Sem random direto — injete `IDGen` interface
- Banco de teste limpa antes de cada teste (`TRUNCATE` em transação revertida)

## Frontend (React)

### Stack

- **Vitest** para unit + component
- **React Testing Library** — testar comportamento do usuário, não implementação
- **MSW** (Mock Service Worker) para mockar a API REST
- **Playwright** para E2E

### Princípios

- ✅ `screen.getByRole('button', { name: /enviar/i })`
- ❌ `screen.getByTestId('submit-button')` (último recurso)
- Não teste detalhes de hooks internos. Teste o que o usuário vê.
- Use `userEvent` (não `fireEvent`) — simula interação real

## Cobertura

- Não trate cobertura como métrica de qualidade — trate como sanity check
- Threshold mínimo: 70% em `domain/` e `service/` (Go), 60% global no frontend
- Caminhos de erro **devem** ser testados — bug que vaza para produção quase sempre é caminho não-feliz não testado

## Spec ↔ Teste

- Cada item em `## Critérios de aceitação` da spec vira **pelo menos** um teste
- Convenção: nome do teste cita o ID do critério (`TestUserSignup_AC1_ValidatesEmail`)

## Quando NÃO testar

- Boilerplate gerado (sqlc, openapi types) — confie no gerador
- Wiring trivial em `cmd/server/main.go`
- Mocks são código também — não teste mocks

## Performance

- Test suite local < 60s. Se passou disso, parta paralelizando ou movendo para integration
- `go test -race ./...` em CI sempre
