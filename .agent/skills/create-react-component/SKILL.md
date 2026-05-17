---
name: create-react-component
description: Use when the user asks to create a new React component in
  apps/web. Covers feature folder structure, accessible components, prop types
  with interface, TanStack Query integration, tests with Vitest + React Testing
  Library, and styling via CSS modules or Tailwind (depends on the ADR).
tools: [view, create_file, str_replace, bash_tool]
---

# Create a React component in this project

## Preconditions

- A feature spec exists in `specs/<id>-<slug>/spec.md` (if it is a product feature)
- For generic reusable components (button, card), a spec is not required — but update Storybook if it exists

## Where to place it

| Type | Folder |
|---|---|
| Reusable component (Button, Card, Modal) | `apps/web/src/components/` |
| Feature-specific component | `apps/web/src/features/<feature>/components/` |
| Page/route | `apps/web/src/features/<feature>/routes/` |

## Step by step

### 1. Create the file

Convention: `PascalCase.tsx`. One component per file. Default export only at route level; named exports in `components/`.

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
          Edit
        </button>
      )}
      {children}
    </article>
  );
}
```

**Rules**:

- Props always use a named `interface`
- No `React.FC` — the type is inferred from the return value
- No `any`. No `as` to force types.
- Accessibility: `aria-*` when the implicit role is not enough. Semantic headings. `<button type="button">` for non-submit buttons.

### 2. Data fetching (if applicable)

**Do not** call `fetch` in the component. Create a hook:

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

And consume it:

```tsx
const { data, isLoading, error } = useUser(id);
if (isLoading) return <Spinner />;
if (error) return <ErrorState error={error} />;
return <UserCard user={data} />;
```

### 3. Styling

- **Tailwind** if the ADR chose Tailwind
- **CSS Modules** otherwise (`UserCard.module.css`)
- No inline `style={{}}` except calculated dynamic values
- No `!important` — if you need it, there is a specificity conflict worth resolving

### 4. Tests

`UserCard.test.tsx` in the same folder:

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  const user = { id: '1', name: 'Ada', email: 'ada@example.com' };

  it('renders name and email', () => {
    render(<UserCard user={user} />);
    expect(screen.getByRole('heading', { name: 'Ada' })).toBeInTheDocument();
    expect(screen.getByText('ada@example.com')).toBeInTheDocument();
  });

  it('calls onEdit when edit is clicked', async () => {
    const onEdit = vi.fn();
    render(<UserCard user={user} onEdit={onEdit} />);
    await userEvent.click(screen.getByRole('button', { name: /edit/i }));
    expect(onEdit).toHaveBeenCalledWith('1');
  });

  it('does not render the edit button when onEdit is not provided', () => {
    render(<UserCard user={user} />);
    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });
});
```

**Rules**:

- Use `getByRole` instead of `getByTestId`
- Use `userEvent`, not `fireEvent`
- Test visible behavior, not implementation details
- At least one test for the error path

### 5. Accessibility

Before considering it done:

- [ ] Tab moves through all interactive elements in a logical order
- [ ] Every input has an associated `<label>`
- [ ] Images have `alt` (empty for decorative images)
- [ ] Loading/error states are announced (`aria-live`)
- [ ] Minimum contrast 4.5:1 (use Lighthouse)

## Anti-patterns in this project

- **Do not** create a component that fetches and renders. Separate: hook fetches, component renders.
- **Do not** use `useEffect` for data fetching. TanStack Query exists.
- **Do not** prop drill more than 2 levels. Consider context or composition.
- **Do not** create a wrapper only to pass props (`<Wrapper>{children}</Wrapper>`).

## Reference

- Component example: `apps/web/src/components/ErrorBoundary.tsx`
- HTTP client: `apps/web/src/api/client.ts`
- Query setup: `apps/web/src/main.tsx`
