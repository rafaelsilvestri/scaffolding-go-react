# 20 — Security

## Principles

1. **Inputs are hostile until proven otherwise**. Validate at the HTTP boundary, before reaching the service.
2. **Secrets never in code.** Always via env vars, validated in `internal/config/`.
3. **Defense in depth.** Do not trust a single layer (e.g., frontend-only validation).
4. **Logs do not leak secrets.** Never log `Authorization` headers, tokens, passwords, card numbers.

## Backend (Go)

### Validation

- Every request DTO struct has `validate:"..."` tags (go-playground/validator) or manual validation in the handler
- Never pass `req.Body` directly to the service — always structure and validate it

### SQL

- **Always parameterize.** sqlc generates safe queries by default.
- **Never concatenate strings in SQL.** If you are tempted, it is wrong.
- Destructive migrations (`DROP`, `TRUNCATE`) require human approval — blocked in the hook (`pre-tool-use.sh`).

### Authentication and authorization

- OAuth2 + PKCE. No custom opaque sessions.
- Tokens validated in middleware (`internal/http/middleware/auth.go`)
- Every handler declares which scope/role it requires — never trust "is logged in"
- Rate limiting on auth endpoints (login, signup, reset)

### Headers

- `Content-Security-Policy`, `X-Frame-Options: DENY`, `Strict-Transport-Security`, `X-Content-Type-Options: nosniff` — mandatory middleware
- CORS configured by env var, never `*` in production

### Crypto

- Never implement custom crypto. Use `crypto/...` from stdlib or audited libraries.
- Passwords: argon2id or bcrypt cost ≥ 12
- Reset/verification tokens: `crypto/rand`, never `math/rand`

## Frontend (React)

- **Never** store tokens in `localStorage` if possible. Prefer httpOnly + SameSite cookies.
- **Never** use `dangerouslySetInnerHTML` except in audited cases (sanitize with DOMPurify)
- Client-side input validation is **UX**, not security. The backend revalidates everything.
- `import` only packages in `package.json`. No CDNs in production.

## Dependencies

- Every new dependency goes through human review (PR message explaining why)
- `pnpm audit` and `govulncheck` run in weekly CI
- Major update of a critical dependency (auth, crypto, HTTP framework) requires an ADR

## Sensitive data

| Category | Examples | Rule |
|---|---|---|
| Critical | passwords, API tokens, private keys | never log, never persist as plain text, always encrypt at rest |
| Personal (PII) | email, CPF, phone | log only a hash when correlation is needed |
| Public | name, public photo | no special restriction |

## Incident response

- Suspected leaked credential: run `scripts/rotate-secrets.sh` and open an issue
- Logs with PII: `internal/http/middleware/logger.go` must redact at the source
- Vulnerable dependency: open a security PR, run `govulncheck`/`pnpm audit`, cite CVE/GHSA
