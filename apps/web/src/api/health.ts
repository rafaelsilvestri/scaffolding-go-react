/**
 * Hook para o endpoint /healthz.
 *
 * Refresca a cada 30s. Não retenta agressivamente: status do health check
 * deve refletir o estado real, não uma media móvel.
 */
import { useQuery } from '@tanstack/react-query';
import { client } from './client';
import type { components } from './generated';

export type HealthStatus = components['schemas']['HealthStatus'];

export function useHealth() {
  return useQuery<HealthStatus, Error>({
    queryKey: ['health'],
    queryFn: async () => {
      const { data, error, response } = await client.GET('/healthz', {});
      if (error || !data) {
        throw new Error(`health check failed (status ${response.status})`);
      }
      return data;
    },
    refetchInterval: 30_000,
    retry: 0,
  });
}
