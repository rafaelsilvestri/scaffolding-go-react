# ADR-0003: Result envelope + erros de domínio tipados

**Status:** Accepted
**Data:** 2026-05-09

## Contexto

Precisamos de uma forma consistente de:

1. Comunicar erros do backend para o frontend (status code + body estruturado)
2. Mapear erros internos (domínio, infraestrutura) para erros HTTP corretos
3. Evitar que handlers vazem detalhes internos

## Decisão

### Backend

Pacote `apps/api/internal/http/response/` expõe:

```go
// Wrapper de sucesso (envelope simples — payload direto)
func OK(w http.ResponseWriter, status int, data any)

// Wrapper de erro tipado
func Error(w http.ResponseWriter, err *AppError)

// Mapeia erros do domínio (domain.ErrNotFound, etc.) para AppError
func MapServiceError(w http.ResponseWriter, err error)
```

E `apps/api/internal/domain/errors.go` define erros sentinela:

```go
var (
    ErrNotFound      = errors.New("domain: not found")
    ErrConflict      = errors.New("domain: conflict")
    ErrInvalidInput  = errors.New("domain: invalid input")
    ErrUnauthorized  = errors.New("domain: unauthorized")
    ErrForbidden     = errors.New("domain: forbidden")
)
```

Mapeamento canônico:

| Erro de domínio | HTTP | Code |
|---|---|---|
| `ErrNotFound` | 404 | `NOT_FOUND` |
| `ErrConflict` | 409 | `CONFLICT` |
| `ErrInvalidInput` | 400 | `VALIDATION_FAILED` |
| `ErrUnauthorized` | 401 | `UNAUTHORIZED` |
| `ErrForbidden` | 403 | `FORBIDDEN` |
| outros | 500 | `INTERNAL` (sem detail no body) |

### Frontend

Cliente `openapi-fetch` já retorna `{ data, error }` — o erro chega tipado
(schema `Error` do OpenAPI). Componentes consomem assim:

```ts
const { data, error, isLoading } = useUser(id);
if (error?.code === 'NOT_FOUND') return <NotFound />;
```

## Por que sucesso não usa envelope

Discutimos retornar `{ data: ... }` em sucesso e `{ error: ... }` em falha
(envelope completo). Decisão: **sucesso retorna o payload direto**, falha
retorna `Error`. Razões:

- Evita duplo aninhamento (`response.data.data.user`)
- Simplifica geração de tipos
- Status code + presença de campo `code` no body já discriminam

Trade-off aceito: em raras situações onde sucesso pode ter metadata
(paginação), usamos response com campos `items`, `next_cursor` no nível raiz.

## Implicações para o agente de AI

- **Nunca** retornar `w.Write([]byte("error: ..."))` ou JSON solto.
- Erros de validação retornam 400 com `Error.details: { fieldName: [...errors] }`.
- Internal errors (500) **nunca** vazam stack trace para o cliente.
- Logs mantêm detalhe completo (`logger.Error(...)`).
