import { Component, type ErrorInfo, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: (err: Error, reset: () => void) => ReactNode;
}

interface State {
  error: Error | null;
}

/**
 * ErrorBoundary global. React não tem versão funcional; mantemos isolado.
 * Em produção, integre com Sentry/Datadog em `componentDidCatch`.
 */
export class ErrorBoundary extends Component<Props, State> {
  override state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  override componentDidCatch(error: Error, info: ErrorInfo): void {
    // eslint-disable-next-line no-console
    console.error('[ErrorBoundary]', error, info.componentStack);
  }

  reset = (): void => this.setState({ error: null });

  override render(): ReactNode {
    if (this.state.error) {
      if (this.props.fallback) {
        return this.props.fallback(this.state.error, this.reset);
      }
      return (
        <div role="alert" style={{ padding: 24 }}>
          <h2>Algo deu errado</h2>
          <p>
            Recarregue a página ou tente novamente.
            {' '}
            <button type="button" onClick={this.reset}>
              Tentar novamente
            </button>
          </p>
        </div>
      );
    }
    return this.props.children;
  }
}
