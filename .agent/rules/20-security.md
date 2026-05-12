# 20 — Segurança

## Princípios

1. **Inputs são hostis até prova em contrário**. Valide na borda HTTP, antes de chegar ao serviço.
2. **Secrets nunca no código.** Sempre via env vars, validadas em `internal/config/`.
3. **Defesa em profundidade.** Não confie em uma única camada (ex.: validação só no frontend).
4. **Logs não vazam secrets.** Nunca logar `Authorization` headers, tokens, senhas, números de cartão.

## Backend (Go)

### Validação

- Toda struct de request DTO tem tags `validate:"..."` (go-playground/validator) ou validação manual no handler
- Nunca passe `req.Body` direto para o serviço — sempre estruture e valide

### SQL

- **Sempre parametrize.** sqlc gera queries seguras por padrão.
- **Jamais concatene strings em SQL.** Se você está tentado, está errado.
- Migrations destrutivas (`DROP`, `TRUNCATE`) requerem aprovação humana — bloqueadas no hook (`pre-tool-use.sh`).

### Autenticação e autorização

- OAuth2 + PKCE. Sem sessões opacas próprias.
- Tokens validados em middleware (`internal/http/middleware/auth.go`)
- Cada handler declara qual scope/role exige — nunca confie em "está logado"
- Rate limiting em endpoints de auth (login, signup, reset)

### Headers

- `Content-Security-Policy`, `X-Frame-Options: DENY`, `Strict-Transport-Security`, `X-Content-Type-Options: nosniff` — middleware obrigatório
- CORS configurado por env var, nunca `*` em produção

### Cripto

- Nunca implemente cripto própria. Use `crypto/...` da stdlib ou bibliotecas auditadas.
- Senhas: argon2id ou bcrypt cost ≥ 12
- Tokens de reset/verificação: `crypto/rand`, nunca `math/rand`

## Frontend (React)

- **Nunca** armazene tokens em `localStorage` se possível. Prefira cookies httpOnly + SameSite.
- **Nunca** use `dangerouslySetInnerHTML` salvo em casos auditados (sanitize com DOMPurify)
- Validação de input client-side é **UX**, não segurança. O backend revalida tudo.
- `import` apenas de pacotes em `package.json`. Sem CDNs em produção.

## Dependências

- Toda nova dep passa por revisão humana (mensagem no PR explicando por quê)
- `pnpm audit` e `govulncheck` rodam em CI semanal
- Atualização major de dep crítica (auth, crypto, framework HTTP) requer ADR

## Dados sensíveis

| Categoria | Exemplos | Regra |
|---|---|---|
| Críticos | senhas, tokens de API, chaves privadas | nunca logar, nunca persistir em texto, sempre cifrar em repouso |
| Pessoais (PII) | email, CPF, telefone | logar apenas hash quando preciso correlacionar |
| Públicos | nome, foto pública | sem restrição especial |

## Resposta a incidentes

- Suspeita de credencial vazada: rode `scripts/rotate-secrets.sh` e abra issue
- Logs com PII: `internal/http/middleware/logger.go` redacta campos por allowlist
