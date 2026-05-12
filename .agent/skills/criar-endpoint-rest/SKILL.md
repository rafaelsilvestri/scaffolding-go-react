---
name: criar-endpoint-rest
description: Use quando o usuário pedir para adicionar um novo endpoint REST no
  backend Go (apps/api). Cobre atualização do contrato OpenAPI, geração de
  tipos, implementação do handler com validação, retorno via Result envelope,
  testes de integração com httptest e atualização do cliente do frontend.
tools: [view, create_file, str_replace, bash_tool]
---

# Criar endpoint REST neste projeto

Procedimento canônico para adicionar um endpoint novo. Siga em ordem.

## Pré-condições

- Existe spec da feature em `specs/<id>-<slug>/spec.md`
- Você leu a constituição (`.agent/CONSTITUTION.md`)
- A migration de DB (se houver) já foi criada e aplicada localmente

## Passo a passo

### 1. Atualizar o contrato (OpenAPI **antes** do código)

Edite `docs/api/openapi.yaml`:

- Adicione o path em `paths:`
- Defina request body e response em `components/schemas/`
- Use `$ref` para reaproveitar schemas existentes
- Sempre defina `400`, `401`, `403`, `404`, `500` quando aplicável, usando `#/components/schemas/Error`

Rode:

```bash
make validate-openapi    # spectral lint
```

### 2. Implementar o handler

Crie `apps/api/internal/http/handlers/<recurso>.go`:

```go
package handlers

import (
    "encoding/json"
    "net/http"

    "github.com/example/scaffolding/apps/api/internal/http/response"
    "github.com/example/scaffolding/apps/api/internal/service"
)

type <Recurso>Handler struct {
    svc *service.<Recurso>Service
}

func New<Recurso>Handler(svc *service.<Recurso>Service) *<Recurso>Handler {
    return &<Recurso>Handler{svc: svc}
}

func (h *<Recurso>Handler) Create(w http.ResponseWriter, r *http.Request) {
    var req Create<Recurso>Request
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        response.Error(w, response.ErrInvalidJSON)
        return
    }
    if err := req.Validate(); err != nil {
        response.Error(w, response.ErrValidation(err))
        return
    }

    out, err := h.svc.Create(r.Context(), req.ToDomain())
    if err != nil {
        response.MapServiceError(w, err)
        return
    }
    response.OK(w, http.StatusCreated, out)
}
```

**Regras**:

- Nunca leia `r.Body` direto — sempre estruture e valide
- Nunca retorne erro do serviço bruto — use `response.MapServiceError` que conhece o mapeamento domínio → HTTP
- Use `r.Context()` em todas as chamadas para o serviço

### 3. Registrar a rota

Em `apps/api/internal/http/router.go`:

```go
r.Route("/<recurso>", func(r chi.Router) {
    r.Use(authMiddleware)  // se autenticado
    r.Post("/", recursoHandler.Create)
})
```

### 4. Implementar serviço (se não existir)

`apps/api/internal/service/<recurso>.go`:

- Recebe `context.Context` + DTO de domínio
- Retorna `(<Recurso>, error)`
- Erros do domínio: usar `domain.ErrNotFound`, `domain.ErrConflict`, etc., **nunca** strings soltas

### 5. Testes de integração

`apps/api/internal/http/handlers/<recurso>_test.go`:

Cobertura mínima:

- ✅ Caso feliz (201 + body correto)
- ✅ Body malformado (400)
- ✅ Validação falha (400 com detalhe)
- ✅ Erro do serviço mapeia certo (404, 409, 500)
- ✅ Sem auth (401) se endpoint protegido

Use `httptest.NewServer` + `chi` real. Não mocke o router.

### 6. Atualizar cliente do frontend

```bash
make gen-api-types    # gera apps/web/src/api/generated.ts
```

Crie hook em `apps/web/src/api/<recurso>.ts`:

```ts
import { useMutation } from '@tanstack/react-query';
import { client } from './client';

export function useCreate<Recurso>() {
  return useMutation({
    mutationFn: (body: Create<Recurso>Request) =>
      client.POST('/<recurso>', { body }),
  });
}
```

### 7. Validação final

```bash
make test         # backend + frontend
make lint
make validate     # spec ↔ código
```

## Anti-padrões neste projeto

- **Não** retornar `{"error": "..."}` solto. Sempre use o envelope `Result`.
- **Não** validar só no frontend. O backend é a borda de confiança.
- **Não** fazer fetch direto no componente — sempre via hook em `api/` ou `features/<f>/hooks/`.
- **Não** introduzir Result envelope inconsistente — sempre passe pelo `response.OK` / `response.Error`.

## Verificação contra a spec

Antes de abrir PR, rode o subagent `spec-verifier`:

```
/spawn spec-verifier specs/<id>-<slug>
```

Ele lê **só** a spec e o código, sem seu histórico, e reporta drift.

## Reference

- Padrão de erro: `apps/api/internal/http/response/response.go`
- Exemplo completo: `apps/api/internal/http/handlers/health.go` + `health_test.go`
- ADR-0003: por que usamos Result envelope
