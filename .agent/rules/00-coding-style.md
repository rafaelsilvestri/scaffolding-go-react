# 00 — Estilo de código

> Regras de estilo aplicáveis a todo código deste repo. Lidas em toda sessão.

## Princípios universais

- **Nomes claros > comentários longos**. Se você precisa de um comentário para explicar o nome, renomeie.
- **Funções pequenas**. Idealmente < 30 linhas. Se passou disso, geralmente há um conceito implícito que merece ser extraído.
- **Erros como dados, não controle de fluxo**. Em Go, retorne `error`. Em TS, retorne `Result<T, E>` ou descriminated unions; lance exception apenas para bugs de programador (invariantes violados).
- **Imutabilidade por padrão**. `const` em TS sempre que possível. Em Go, evite ponteiros que sugerem mutação se não for necessário.
- **Não há "TODO sem owner"**. Todo `TODO` no código tem nome de pessoa e link para issue.

## Go

- `gofmt`, `goimports` são obrigatórios — rodam em pre-commit
- `golangci-lint` com config em `apps/api/.golangci.yml`
- Pacote = uma responsabilidade clara. Sem `utils/`, `helpers/`, `common/`
- `internal/` para tudo que não deve ser importado por outros módulos
- Erros: use `fmt.Errorf("contexto: %w", err)` para preservar chain. Não use `errors.New` quando há contexto a adicionar
- Logs: `log/slog` estruturado. Nada de `fmt.Println` em código de produção
- Não use `interface{}` (ou `any`) salvo em casos de plumbing genuíno
- Generics quando reduz duplicação **e** clarifica a assinatura. Se requer comentário para entender, não use
- Testes: `_test.go` na mesma pasta. Use `testify/require` ou `testing` puro — escolha um por pacote

## TypeScript

- `"strict": true` em `tsconfig.json` — não negocie
- `"noUncheckedIndexedAccess": true` — força narrowing após `arr[i]`
- **Sem `any`**. Use `unknown` e narrow. Se a lib não tem tipos, escreva o `.d.ts` no projeto.
- `interface` para shape de dados, `type` para uniões e composição
- Componentes funcionais com hooks. Sem class components
- Props com `interface` nomeada (`UserCardProps`), não inline
- Evite `useEffect` para data fetching — use TanStack Query
- Nome do arquivo bate com o export default (ou principal): `UserCard.tsx` exporta `UserCard`

## Imports

- Ordem: stdlib → third-party → workspace → relative
- Imports absolutos via alias `@/` no frontend (configurado no `vite.config.ts`)
- No backend, sempre o path completo do módulo (`github.com/example/scaffolding/apps/api/...`)

## Comentários

- **Documente "por quê", não "o quê"**. O código já mostra o que faz.
- Funções públicas sempre têm doc comment (Go: começando com o nome da função; TS: JSDoc)
- `// TODO(rafael, #123): ...` — sempre com owner e issue
