# 99 — Ações proibidas

> Lista canônica do que o agente **nunca** faz neste repo. O hook `pre-tool-use.sh` força os itens críticos.

## Comandos jamais executar

- `rm -rf` em qualquer caminho fora de `dist/`, `build/`, `node_modules/`, `.next/`, `coverage/`, `/tmp/`
- `DROP TABLE`, `TRUNCATE`, `DROP DATABASE` em qualquer banco que não termine em `_test`
- `git push --force` ou `git push -f` em `main`, `develop`, `release/*`
- `git reset --hard` em branch que não é a do agente (`agent/*`)
- `npm publish`, `pnpm publish`, `goreleaser release` — releases são **só** via GitHub Actions
- `chmod 777` em qualquer arquivo
- `curl ... | sh` ou `wget ... | bash` — instale dependências via `package.json`/`go.mod`
- `sudo` em qualquer contexto local

## Padrões jamais introduzir no código

- `eval()` em JS/TS, `os/exec` com input do usuário em Go
- Concatenação de strings em SQL — sempre parametrize via sqlc
- `dangerouslySetInnerHTML` sem sanitização (DOMPurify) explícita
- `process.env.X` direto em código de aplicação — passe por `internal/config/` ou `import.meta.env` validado
- `any` em TypeScript
- `interface{}` ou `any` em Go fora de plumbing genuíno
- `panic()` em Go fora de `main` ou inicialização não-recuperável
- Hardcoded URLs de produção, secrets, tokens
- Arquivos `*.local.*` versionados (esses devem ir para `.gitignore`)

## Sempre confirmar com o humano antes de

- Modificar `infrastructure/`, `terraform/`, ou qualquer pasta com config de cloud
- Rodar migrations em qualquer ambiente que não seja local
- Adicionar nova dependência a `go.mod` ou `package.json` — explicar **por quê** no PR
- Mudanças que alterem `docs/api/openapi.yaml` retirando campos (breaking change)
- Renomear ou deletar arquivos em `apps/api/internal/domain/` (regras de negócio)
- Mudanças em `.agent/CONSTITUTION.md` ou em qualquer ADR
- Operações git que reescrevam histórico (`rebase -i`, `filter-branch`, `commit --amend` em commit já pushed)
- Mudanças em `.github/workflows/` que removam steps de validação
- Acesso a serviços externos não declarados em `.mcp.json`

## Caminho ascendente

Se uma regra acima entra em conflito com uma necessidade real:

1. Pare. Explique o conflito ao humano em prosa.
2. Proponha alternativas.
3. Aguarde decisão explícita no chat.
4. Se aprovado, registre em ADR antes de executar.

> A regra é: na dúvida, **não execute**. Pergunte.
