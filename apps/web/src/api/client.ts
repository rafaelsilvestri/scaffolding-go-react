/**
 * HTTP client tipado a partir do OpenAPI.
 *
 * Use SEMPRE este cliente para chamar a API — não use `fetch` direto.
 * Os tipos vêm de `./generated.ts`, gerado por `pnpm gen:api`.
 */
import createClient from 'openapi-fetch';
import type { paths } from './generated';

const baseUrl = import.meta.env.VITE_API_BASE_URL ?? '';

export const client = createClient<paths>({
  baseUrl,
  // Inclui cookies (HttpOnly) — auth via cookie, não localStorage.
  credentials: 'same-origin',
});
