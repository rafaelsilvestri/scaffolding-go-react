import { useHealth } from '@/api/health';

const labels = {
  ok: 'Saudável',
  degraded: 'Degradado',
  unknown: 'Verificando...',
  error: 'Indisponível',
} as const;

const colors = {
  ok: '#16a34a',
  degraded: '#ca8a04',
  unknown: '#6b7280',
  error: '#dc2626',
} as const;

type Variant = keyof typeof labels;

export function HealthBadge() {
  const { data, isLoading, error } = useHealth();

  let variant: Variant = 'unknown';
  if (error) variant = 'error';
  else if (data?.status === 'ok') variant = 'ok';
  else if (data?.status === 'degraded') variant = 'degraded';

  return (
    <span
      role="status"
      aria-live="polite"
      aria-label={`Status do servidor: ${labels[variant]}`}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 6,
        padding: '4px 10px',
        borderRadius: 999,
        backgroundColor: colors[variant],
        color: '#fff',
        fontSize: 12,
        fontWeight: 600,
      }}
    >
      <span
        aria-hidden="true"
        style={{
          width: 8,
          height: 8,
          borderRadius: '50%',
          backgroundColor: '#fff',
          opacity: 0.9,
        }}
      />
      {isLoading ? labels.unknown : labels[variant]}
      {data?.version ? <small>(v{data.version})</small> : null}
    </span>
  );
}
