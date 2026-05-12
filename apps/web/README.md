# apps/web — Frontend React

SPA em React 18 + TypeScript estrito, build com Vite, estado de servidor via TanStack Query.

## Estrutura

```
apps/web/
├── src/
│   ├── api/                # cliente HTTP gerado a partir do OpenAPI + hooks
│   ├── components/         # componentes reutilizáveis (sem fetch direto)
│   ├── features/           # uma pasta por feature de produto (a criar)
│   ├── lib/                # utilities puras
│   ├── styles/             # CSS global / tokens
│   ├── test/setup.ts       # vitest setup
│   ├── App.tsx
│   └── main.tsx
├── eslint.config.js
├── tsconfig.json
├── vite.config.ts
├── package.json
├── Dockerfile
└── nginx.conf
```

## Scripts

```bash
pnpm dev          # :5173, proxy para :8080
pnpm build        # produção
pnpm test         # vitest
pnpm test:e2e     # playwright
pnpm typecheck    # tsc --noEmit
pnpm lint         # eslint
pnpm gen:api      # regenera src/api/generated.ts a partir de docs/api/openapi.yaml
```

## Convenções

- **Sem `any`.** Use `unknown` + narrowing.
- **Sem `useEffect` para data fetching.** Use TanStack Query.
- **Sem fetch direto em componentes.** Sempre via hook em `api/` ou `features/<f>/hooks/`.
- **Acessibilidade primeiro:** `getByRole` em testes, semântica HTML correta.
- **Tipos via OpenAPI.** Não invente shapes — `pnpm gen:api` é a fonte da verdade.

## Adicionando um componente

Use a skill `criar-componente-react` (ver `.agent/skills/criar-componente-react/SKILL.md`).
