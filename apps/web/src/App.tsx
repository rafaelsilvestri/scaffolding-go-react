import { HealthBadge } from './components/HealthBadge';

export function App() {
  return (
    <main>
      <header>
        <h1>Scaffolding Go + React</h1>
        <HealthBadge />
      </header>

      <section aria-labelledby="welcome-heading">
        <h2 id="welcome-heading">Bem-vindo</h2>
        <p>
          Este é o scaffolding de exemplo. Veja <code>specs/</code> para a feature
          de referência (<code>0001-health-check</code>) e <code>.agent/</code>{' '}
          para regras, skills, hooks e subagents que orientam o agente de AI.
        </p>
      </section>
    </main>
  );
}
