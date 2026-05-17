---
name: create-rest-endpoint
description: Use when the user asks to add a new REST endpoint in the Go
  backend (apps/api). Covers updating the OpenAPI contract, type generation,
  handler implementation with validation, Result envelope responses,
  integration tests with httptest, and frontend client updates.
tools: [view, create_file, str_replace, bash_tool]
---

# Create a REST endpoint in this project

Canonical procedure for adding a new endpoint. Follow it in order.

## Preconditions

- A feature spec exists in `specs/<id>-<slug>/spec.md`
- You read the constitution (`.agent/CONSTITUTION.md`)
- The DB migration (if any) has already been created and applied locally

## Step by step

### 1. Update the contract (OpenAPI **before** code)

Edit `docs/api/openapi.yaml`:

- Add the path under `paths:`
- Define request body and response under `components/schemas/`
- Use `$ref` to reuse existing schemas
- Always define `400`, `401`, `403`, `404`, `500` when applicable, using `#/components/schemas/Error`

Run:

```bash
make validate-openapi    # spectral lint
```

### 2. Implement the handler

Create `apps/api/internal/http/handlers/<resource>.go`:

```go
package handlers

import (
    "encoding/json"
    "net/http"

    "github.com/example/scaffolding/apps/api/internal/http/response"
    "github.com/example/scaffolding/apps/api/internal/service"
)

type <Resource>Handler struct {
    svc *service.<Resource>Service
}

func New<Resource>Handler(svc *service.<Resource>Service) *<Resource>Handler {
    return &<Resource>Handler{svc: svc}
}

func (h *<Resource>Handler) Create(w http.ResponseWriter, r *http.Request) {
    var req Create<Resource>Request
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

**Rules**:

- Never read `r.Body` directly — always structure and validate it
- Never return the raw service error — use `response.MapServiceError`, which knows the domain → HTTP mapping
- Use `r.Context()` in every service call

### 3. Register the route

In `apps/api/internal/http/router.go`:

```go
r.Route("/<resource>", func(r chi.Router) {
    r.Use(authMiddleware)  // if authenticated
    r.Post("/", resourceHandler.Create)
})
```

### 4. Implement the service (if it does not exist)

`apps/api/internal/service/<resource>.go`:

- Receives `context.Context` + domain DTO
- Returns `(<Resource>, error)`
- Domain errors: use `domain.ErrNotFound`, `domain.ErrConflict`, etc., **never** loose strings

### 5. Integration tests

`apps/api/internal/http/handlers/<resource>_test.go`:

Minimum coverage:

- ✅ Happy path (201 + correct body)
- ✅ Malformed body (400)
- ✅ Validation failure (400 with detail)
- ✅ Service error maps correctly (404, 409, 500)
- ✅ No auth (401) if protected endpoint

Use `httptest.NewServer` + real `chi`. Do not mock the router.

### 6. Update frontend client

```bash
make gen-api-types    # generates apps/web/src/api/generated.ts
```

Create hook in `apps/web/src/api/<resource>.ts`:

```ts
import { useMutation } from '@tanstack/react-query';
import { client } from './client';

export function useCreate<Resource>() {
  return useMutation({
    mutationFn: (body: Create<Resource>Request) =>
      client.POST('/<resource>', { body }),
  });
}
```

### 7. Final validation

```bash
make test         # backend + frontend
make lint
make validate     # spec ↔ code
```

## Anti-patterns in this project

- **Do not** return a loose `{"error": "..."}`. Always use the `Result` envelope.
- **Do not** validate only in the frontend. The backend is the trust boundary.
- **Do not** fetch directly in the component — always through a hook in `api/` or `features/<f>/hooks/`.
- **Do not** introduce an inconsistent Result envelope — always go through `response.OK` / `response.Error`.

## Verification against the spec

Before opening a PR, run the `spec-verifier` subagent:

```
/spawn spec-verifier specs/<id>-<slug>
```

It reads **only** the spec and the code, without your history, and reports drift.

## Reference

- Error pattern: `apps/api/internal/http/response/response.go`
- Full example: `apps/api/internal/http/handlers/health.go` + `health_test.go`
- ADR-0003: why we use the Result envelope
