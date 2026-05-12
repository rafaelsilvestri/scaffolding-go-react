import { render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { HealthBadge } from './HealthBadge';

vi.mock('@/api/client', () => ({
  client: {
    GET: vi.fn(),
  },
}));

import { client } from '@/api/client';

function renderWithClient() {
  const qc = new QueryClient({
    defaultOptions: { queries: { retry: false, refetchInterval: false } },
  });
  return render(
    <QueryClientProvider client={qc}>
      <HealthBadge />
    </QueryClientProvider>,
  );
}

describe('HealthBadge', () => {
  beforeEach(() => vi.clearAllMocks());

  it('mostra "Saudável" quando status=ok', async () => {
    (client.GET as ReturnType<typeof vi.fn>).mockResolvedValue({
      data: {
        status: 'ok',
        version: '1.2.3',
        uptime_seconds: 30,
        checks: { database: true },
      },
      error: undefined,
      response: { status: 200 },
    });

    renderWithClient();

    await waitFor(() => {
      expect(screen.getByRole('status')).toHaveTextContent(/Saud[áa]vel/i);
    });
    expect(screen.getByRole('status')).toHaveAccessibleName(/Status do servidor/i);
  });

  it('mostra "Degradado" quando status=degraded', async () => {
    (client.GET as ReturnType<typeof vi.fn>).mockResolvedValue({
      data: {
        status: 'degraded',
        version: 'dev',
        uptime_seconds: 10,
        checks: { database: false },
      },
      error: undefined,
      response: { status: 200 },
    });

    renderWithClient();

    await waitFor(() => {
      expect(screen.getByRole('status')).toHaveTextContent(/Degradado/i);
    });
  });

  it('mostra "Indisponível" quando o fetch falha', async () => {
    (client.GET as ReturnType<typeof vi.fn>).mockResolvedValue({
      data: undefined,
      error: { code: 'INTERNAL', message: 'fail' },
      response: { status: 500 },
    });

    renderWithClient();

    await waitFor(() => {
      expect(screen.getByRole('status')).toHaveTextContent(/Indispon[íi]vel/i);
    });
  });
});
