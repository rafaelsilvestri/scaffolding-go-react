---
name: qa-cycle
description: Use quando o usuário pedir para validar uma feature, "rodar QA",
  "fechar o ciclo", "testar e corrigir", ou após implementar uma feature
  nova. Orquestra os 4 subagents do ciclo (test-planner → test-runner →
  bug-reporter → bug-fixer) em sequência, com gates entre cada fase.
  Tudo escrito em specs/<id>-<slug>/qa/.
tools: [view, bash_tool, grep_tool, glob_tool]
---

# Ciclo de QA neste projeto

Procedimento canônico para validar uma feature após implementação. Fecha o
loop: **plano de testes → execução → relatório de bugs → correção → PR**.

## Pré-condições

- Existe `specs/<id>-<slug>/spec.md` (a feature está especificada)
- A feature foi implementada (código de produção existe)
- `make setup` foi executado pelo menos uma vez
- Banco de teste local disponível
- Working tree limpa (`git status` sem mudanças não commitadas)

## Disparo automático

Esta skill é invocada automaticamente pelo hook `.agent/hooks/post-tool-use.sh`
quando `specs/<id>/tasks.md` é editado de forma que **todos** os checkboxes
ficam marcados (`- [x]`) e `specs/<id>/qa/test-plan.md` ainda não existe.

O hook emite uma mensagem com prefixo `[QA-CYCLE-TRIGGER]` em stderr e usa
`exit 2` para garantir que o agente leia e reaja. Não é falha de edição —
é o sinal de que a implementação fechou e o ciclo precisa rodar antes de
qualquer commit/push.

### Opt-out (raro)

Se a feature legitimamente não precisa do ciclo (ex.: spike, mudança apenas
de docs, refator puro sem mudança de comportamento testável), crie:

```bash
mkdir -p specs/<id>-<slug>/qa
echo "razão: <justificativa em uma linha>" > specs/<id>-<slug>/qa/.skip-qa-cycle
```

O hook detecta o arquivo, registra a justificativa em stderr e libera o
agente. Use com parcimônia — a justificativa fica versionada e revisores
veem.

## Inputs

- `SPEC_ID`: ID da feature (ex.: `0001-health-check`)
- `BRANCH`: branch que implementa (default: branch atual)
- `MIN_SEVERITY` (opcional): piso para o bug-fixer (`critical|high|medium|low`). Default: `low`.

## Passo a passo

### 0. Sanity check

```bash
test -d specs/$SPEC_ID || { echo "Spec não encontrada"; exit 1; }
git status --porcelain || { echo "Working tree suja"; exit 1; }
mkdir -p specs/$SPEC_ID/qa/logs
```

### 1. Planejar — `test-planner`

Subagent: `test-planner`

Inputs:
- `SPEC_ID`
- `BRANCH`

Output esperado: `specs/$SPEC_ID/qa/test-plan.md`

Gate de avanço:
- Existe o arquivo
- Veredito = `PLAN_READY` **ou** `PLAN_HAS_GAPS` (gaps **não** bloqueiam, são informativos)

Se gaps detectados: mostre o bloco `## Gaps detectados na spec` ao humano e
**pergunte** se quer continuar mesmo assim ou pausar para atualizar a spec.

### 2. Executar — `test-runner`

Subagent: `test-runner`

Inputs:
- `SPEC_ID`
- `BRANCH`
- `LEVELS` (default: todos — unit, integration, contract, e2e, security)

Output esperado: `specs/$SPEC_ID/qa/test-results.md` + logs em `qa/logs/`

Gate de avanço:
- Veredito = `ALL_PASS` → **encerre o ciclo aqui**. Não invoque bug-reporter.
- Veredito = `FAILURES_DETECTED` → siga para passo 3.
- Veredito = `EXECUTION_ERROR` → **pare e escale**. Não é bug de feature, é build quebrado.

### 3. Reportar — `bug-reporter`

Subagent: `bug-reporter`

Inputs:
- `SPEC_ID`
- `BRANCH`

Output esperado: `specs/$SPEC_ID/qa/bug-report.md`

Gate de avanço:
- Veredito = `NO_BUGS` → cenário anômalo (test-runner viu falhas mas reporter não): pare e escale.
- Veredito = `BUGS_TO_FIX` → siga para passo 4.
- Veredito = `ESCALATE_TO_HUMAN` → pare. Mostre o relatório ao humano.

### 4. Corrigir — `bug-fixer`

Subagent: `bug-fixer`

Inputs:
- `SPEC_ID`
- `BRANCH`
- `MIN_SEVERITY` (do input do ciclo)

Output esperado: `specs/$SPEC_ID/qa/fix-log.md` + PR aberto

Gate de avanço:
- Se algum bug foi marcado `ESCALATED` ou `ATTEMPTED_FAILED`: re-rode passos 2–4 **no máximo 2 vezes a mais** (total 3 iterações). Se ainda há bugs não corrigidos após 3 ciclos, pare e escale ao humano com o `fix-log.md` consolidado.

### 5. Re-verificar — `test-runner` novamente

Re-execute o passo 2 contra a branch de fix. Espere:
- `ALL_PASS` → ciclo fechado
- Falhas remanescentes → todas devem ser **as mesmas** que o `bug-fixer` marcou como escaladas. Se aparecem **novas** falhas, é regressão introduzida pelo fix — pare e escale.

### 6. Revisar — `reviewer` (opcional, mas recomendado)

Subagent: `reviewer`

Inputs:
- `PR_BASE`
- `PR_HEAD`
- `SPEC_PATH=specs/$SPEC_ID`

Gera review do PR antes do humano olhar.

### 7. Verificação cruzada — `spec-verifier` (recomendado)

Subagent: `spec-verifier`

Confirma que o que ficou no branch **conforme a spec** (sem feature creep e
sem item da spec sem cobertura).

## Estrutura final de arquivos

Após um ciclo completo:

```
specs/<id>-<slug>/
├── spec.md
├── plan.md
├── tasks.md
└── qa/
    ├── test-plan.md       # do test-planner
    ├── test-results.md    # do test-runner
    ├── bug-report.md      # do bug-reporter
    ├── fix-log.md         # do bug-fixer
    └── logs/
        ├── lint.log
        ├── unit.log
        ├── integration.log
        ├── contract.log
        ├── security.log
        └── e2e.log
```

## Diagrama do fluxo

```
[implementação pronta]
        │
        ▼
┌──────────────────┐    PLAN_READY
│  test-planner    │──────────────►  test-plan.md
└──────────────────┘
        │
        ▼
┌──────────────────┐    ALL_PASS
│  test-runner     │──────────────►  ciclo encerrado ✅
│                  │
│                  │    FAILURES_DETECTED
└──────┬───────────┘──────────────►  test-results.md
       │
       │  EXECUTION_ERROR
       └──────────────────────────►  escalar 🚨
       │
       ▼
┌──────────────────┐    NO_BUGS
│  bug-reporter    │──────────────►  anomalia 🚨
│                  │
│                  │    BUGS_TO_FIX
└──────┬───────────┘──────────────►  bug-report.md
       │
       │  ESCALATE_TO_HUMAN
       └──────────────────────────►  escalar 🚨
       │
       ▼
┌──────────────────┐
│  bug-fixer       │──────────────►  fix-log.md + PR aberto
└──────┬───────────┘                       │
       │                                   │
       │  loop ≤ 3                         │
       └─────────► test-runner ◄───────────┘
                       │
                       │  ALL_PASS
                       ▼
                 ┌──────────┐
                 │ reviewer │ + spec-verifier
                 └──────────┘
                       │
                       ▼
                 ciclo encerrado ✅
```

## Gates explícitos

| De → Para | Condição para avançar |
|---|---|
| planner → runner | `test-plan.md` existe e tem casos P0 |
| runner → reporter | veredito = `FAILURES_DETECTED` |
| runner → fim | veredito = `ALL_PASS` |
| reporter → fixer | veredito = `BUGS_TO_FIX` |
| fixer → runner (re-run) | ao menos 1 bug com status `FIXED` no fix-log |
| qualquer → escalar | erro de execução, ambiguidade de spec, regressão nova, ou 3 iterações sem convergir |

## Anti-padrões neste ciclo

- **Não pule o planner.** Sem plano, o runner não tem o que executar e o bug-reporter não tem rastreabilidade.
- **Não combine agentes.** Cada um roda em contexto isolado para evitar contaminação (planner não deve ver o relatório, fixer não deve ver o plano original — só o bug-report).
- **Não rode o ciclo sem branch.** Sempre em branch isolada (`fix/<spec-id>-qa-<ts>` é gerada pelo bug-fixer).
- **Não esconda bugs escalados.** Se o ciclo termina com bugs `ESCALATED`, o PR descreve quais e o humano decide.
- **Não silencie testes flaky.** O bug-reporter marca `flaky: true`; o bug-fixer **não pode** simplesmente colocar `t.Skip()`. Flaky vira bug rastreado.

## Quando NÃO usar este ciclo

- **Spike / protótipo** sem spec: não rode o ciclo, ele depende da spec como oracle.
- **Mudança apenas de docs / ADR**: nada para testar.
- **Hotfix urgente**: rode o `bug-fixer` direto a partir de um `bug-report.md` escrito à mão (pelo humano), pulando planner e runner. Documente no commit.

## Comandos resumidos

```bash
# Rodar o ciclo manualmente, passo a passo
/spawn test-planner specs/0001-health-check
/spawn test-runner  specs/0001-health-check
/spawn bug-reporter specs/0001-health-check
/spawn bug-fixer    specs/0001-health-check MIN_SEVERITY=low

# Re-verificação
/spawn test-runner  specs/0001-health-check
/spawn reviewer     PR_BASE=main PR_HEAD=$(git branch --show-current) SPEC_PATH=specs/0001-health-check
/spawn spec-verifier specs/0001-health-check
```

## Reference

- Subagents: `.agent/agents/{test-planner,test-runner,bug-reporter,bug-fixer}.md`
- Subagents relacionados: `.agent/agents/{reviewer,spec-verifier,security-auditor}.md`
- Rules aplicáveis: `.agent/rules/30-testing.md` (pirâmide), `99-forbidden.md` (limites do fixer)
- Constituição: `.agent/CONSTITUTION.md` (workflow obrigatório)
