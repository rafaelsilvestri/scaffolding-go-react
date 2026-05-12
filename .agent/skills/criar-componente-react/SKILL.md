---
name: criar-componente-react
description: Use quando o usuário pedir para criar um novo componente React em
  apps/web. Cobre estrutura de pasta por feature, componentes acessíveis, tipos
  de props com interface, integração com TanStack Query, testes com Vitest +
  React Testing Library, e estilo via CSS modules ou Tailwind (depende do ADR).
tools: [view, create_file, str_replace, bash_tool]
---

# Criar componente React neste projeto

## Pré-condições

- Existe spec da feature em `specs/<id>-<slug>/spec.md` (se for feature de produto)
- Para componentes reutilizáveis genéricos (botão, card), spec não é obrigatória — mas atualize Storybook se existir

## Onde colocar

| Tipo | Pasta |
|---|---|
| Componente reutilizável (Button, Card, Modal) | `apps/web/src/components/` |
| Componente específico de uma feature | `apps/web/src/features/<feature>/components/` |
| Página/rota | `apps/web/src/features/<feature>/routes/` |

## Passo a passo

### 1. Criar o arquivo

Convenção: `PascalCase.tsx`. Um componente por arquivo. Default export apenas no nível de rota; nomeado em `components/`.

```tsx
// apps/web/src/features/users/components/UserCard.tsx
import { type ReactNode } from 'react';

export interface UserCardProps {
  user: {
    id: string;
    name: string;
    email: string;
  };
  onEdit?: (id: string) => void;
  children?: ReactNode;
}

export function UserCard({ user, onEdit, children }: UserCardProps) {
  return (
    <article aria-labelledby={`user-${user.id}-name`}>
      <h3 id={`user-${user.id}-name`}>{user.name}</h3>
      <p>{user.email}</p>
      {onEdit && (
        <button type="button" onClick={() => onEdit(user.id)}>
          Editar
        </button>
      )}
      {children}
    </article>
  );
}
```

**Regras**:

- Props sempre com `interface` nomeada
- Sem `React.FC` — o tipo é inferido do retorno
- Sem `any`. Sem `as` para forçar tipos.
- Acessibilidade: `aria-*` quando o role implícito não basta. Headings semânticos. `<button type="button">` para botões não-submit.

### 2. Data fetching (se aplicável)

**Não** chame `fetch` no componente. Crie um hook:

```ts
// apps/web/src/features/users/hooks/useUser.ts
import { useQuery } from '@tanstack/react-query';
import { client } from '@/api/client';

export function useUser(id: string) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: async () => {
      const { data, error } = await client.GET('/users/{id}', {
        params: { path: { id } },
      });
      if (error) throw error;
      return data;
    },
  });
}
```

E consuma:

```tsx
const { data, isLoading, error } = useUser(id);
if (isLoading) return <Spinner />;
if (error) return <ErrorState error={error} />;
return <UserCard user={data} />;
```

### 3. Estilo

- **Tailwind** se o ADR escolheu Tailwind
- **CSS Modules** caso contrário (`UserCard.module.css`)
- Sem `style={{}}` inline salvo valores dinâmicos calculados
- Sem `!important` — se você precisa, há um conflito de especificidade que merece ser resolvido

### 4. Testes

`UserCard.test.tsx` na mesma pasta:

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  const user = { id: '1', name: 'Ada', email: 'ada@example.com' };

  it('renderiza nome e email', () => {
    render(<UserCard user={user} />);
    expect(screen.getByRole('heading', { name: 'Ada' })).toBeInTheDocument();
    expect(screen.getByText('ada@example.com')).toBeInTheDocument();
  });

  it('chama onEdit ao clicar em editar', async () => {
    const onEdit = vi.fn();
    render(<UserCard user={user} onEdit={onEdit} />);
    await userEvent.click(screen.getByRole('button', { name: /editar/i }));
    expect(onEdit).toHaveBeenCalledWith('1');
  });

  it('não renderiza botão de editar quando onEdit não é fornecido', () => {
    render(<UserCard user={user} />);
    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });
});
```

**Regras**:

- Use `getByRole` em vez de `getByTestId`
- Use `userEvent`, não `fireEvent`
- Teste o comportamento visível, não detalhes de implementação
- Pelo menos um teste para o caminho de erro

### 5. Acessibilidade

Antes de considerar pronto:

- [ ] Tab passa por todos os elementos interativos em ordem lógica
- [ ] Cada input tem `<label>` associado
- [ ] Imagens têm `alt` (vazio para decorativas)
- [ ] Estados de loading/erro são anunciados (`aria-live`)
- [ ] Contraste mínimo 4.5:1 (use Lighthouse)

## Anti-padrões neste projeto

- **Não** crie componente que faz fetch e renderiza. Separe: hook busca, componente renderiza.
- **Não** use `useEffect` para data fetching. Existe TanStack Query.
- **Não** prop drill mais que 2 níveis. Considere context ou composition.
- **Não** crie um wrapper só para passar props (`<Wrapper>{children}</Wrapper>`).

## Reference

- Exemplo de componente: `apps/web/src/components/ErrorBoundary.tsx`
- Cliente HTTP: `apps/web/src/api/client.ts`
- Setup de queries: `apps/web/src/main.tsx`
