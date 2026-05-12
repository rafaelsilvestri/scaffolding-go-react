/**
 * Tipos gerados a partir de `docs/api/openapi.yaml`.
 *
 * Esta é uma versão MANUAL inicial — assim que `openapi-typescript` rodar via
 * `pnpm gen:api`, este arquivo é sobrescrito automaticamente. Não edite à
 * mão fora do scaffolding inicial.
 */

export interface paths {
  '/healthz': {
    get: {
      responses: {
        200: {
          content: {
            'application/json': components['schemas']['HealthStatus'];
          };
        };
      };
    };
  };
}

export interface components {
  schemas: {
    HealthStatus: {
      status: 'ok' | 'degraded';
      version: string;
      uptime_seconds: number;
      checks: {
        database: boolean;
      };
    };
    Error: {
      code: string;
      message: string;
      details?: Record<string, unknown>;
      request_id?: string;
    };
  };
}

export type operations = Record<string, never>;
