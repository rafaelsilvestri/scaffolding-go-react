#!/usr/bin/env bash
# .agent/hooks/post-tool-use.sh
#
# Hook PostToolUse para Claude Code. Roda após Edit/Write/MultiEdit completar.
#
# Protocolo (Claude Code):
#   JSON via STDIN contendo, além dos campos de PreToolUse, também:
#     "tool_response": { ...resultado da tool... }
#
#   - exit 0: ok
#   - exit 2: comunica ao agente que a edição introduziu problema (não desfaz, mas
#             o agente vê a mensagem em stderr e pode reagir corrigindo)
#   - exit 1: erro interno do hook (logado, não-bloqueante)

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    echo "post-tool-use: jq ausente — pulando" >&2
    exit 0
fi

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
tool_input=$(echo "$input" | jq -c '.tool_input // {}')
file_path=$(echo "$tool_input" | jq -r '.file_path // ""')

# Sem path ou tool não relevante → ignora
[[ -z "$file_path" ]] && exit 0
[[ ! -f "$file_path" ]] && exit 0

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

report() {
    # mensagem ao agente para que ele corrija sem esperar CI
    printf 'post-tool-use: %s\n' "$1" >&2
    exit 2
}

# ---------------------------------------------------------------------------
# Go
# ---------------------------------------------------------------------------
if [[ "$file_path" == *.go ]]; then
    pkg_dir=$(dirname "$file_path")
    rel_pkg=$(realpath --relative-to="$REPO_ROOT/apps/api" "$pkg_dir" 2>/dev/null || true)

    # gofmt
    if ! gofmt -l "$file_path" | tee /dev/stderr | (! grep -q .); then
        # Aplica fmt e segue (mudança trivial, não bloqueia)
        gofmt -w "$file_path"
    fi

    # goimports se disponível
    if command -v goimports >/dev/null 2>&1; then
        goimports -w -local "github.com/example/scaffolding" "$file_path" || true
    fi

    # go vet só na package modificada
    if [[ -n "$rel_pkg" && -d "$REPO_ROOT/apps/api/$rel_pkg" ]]; then
        if ! (cd "$REPO_ROOT/apps/api" && go vet "./$rel_pkg" 2>&1); then
            report "go vet falhou em $rel_pkg — corrija antes de continuar"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# TypeScript / JS
# ---------------------------------------------------------------------------
if [[ "$file_path" =~ \.(ts|tsx|js|jsx)$ ]]; then
    if [[ -x "$REPO_ROOT/apps/web/node_modules/.bin/eslint" ]]; then
        if ! (cd "$REPO_ROOT/apps/web" && ./node_modules/.bin/eslint --fix "$file_path" 2>&1); then
            report "eslint reportou erros em $file_path"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# OpenAPI
# ---------------------------------------------------------------------------
if [[ "$file_path" == *"docs/api/openapi.yaml" ]]; then
    if command -v spectral >/dev/null 2>&1; then
        if ! spectral lint "$file_path" 2>&1; then
            report "spectral reportou erros — corrija o contrato antes de prosseguir"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# SQL (queries sqlc)
# ---------------------------------------------------------------------------
if [[ "$file_path" == *"apps/api/db/queries/"*.sql ]]; then
    if command -v sqlc >/dev/null 2>&1; then
        if ! (cd "$REPO_ROOT/apps/api" && sqlc compile 2>&1); then
            report "sqlc compile falhou após editar $file_path"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Migrations — alerta se editou arquivo já versionado (defesa em profundidade)
# ---------------------------------------------------------------------------
if [[ "$file_path" == *"/migrations/"* ]]; then
    if git ls-files --error-unmatch "$file_path" >/dev/null 2>&1; then
        printf 'post-tool-use: AVISO — migration já versionada foi editada. Considere criar nova migration.\n' >&2
    fi
fi

# ---------------------------------------------------------------------------
# QA cycle trigger — detecta fim de implementação de spec
#
# Quando specs/<id>-<slug>/tasks.md é editado e fica com todos os checkboxes
# marcados, dispara nudge para o agente rodar a skill `qa-cycle`.
#
# Skip condições:
#   - Já existe qa/test-plan.md (ciclo em curso ou concluído)
#   - tasks.md sem nenhum checkbox (template vazio)
#   - Algum checkbox ainda aberto (- [ ])
# ---------------------------------------------------------------------------
if [[ "$file_path" =~ /specs/([^/]+)/tasks\.md$ ]]; then
    spec_dir=$(dirname "$file_path")
    spec_id=$(basename "$spec_dir")

    # Conta checkboxes — só linhas começando com "- [" para evitar falsos positivos
    closed_count=$(grep -cE '^[[:space:]]*-[[:space:]]+\[[xX]\]' "$file_path" || true)
    open_count=$(grep -cE '^[[:space:]]*-[[:space:]]+\[[[:space:]]\]' "$file_path" || true)

    if [[ "$open_count" -eq 0 && "$closed_count" -gt 0 ]]; then
        # Opt-out explícito (ver CONSTITUTION § workflow item 5)
        if [[ -f "$spec_dir/qa/.skip-qa-cycle" ]]; then
            printf 'post-tool-use: QA cycle pulado para %s (.skip-qa-cycle presente).\n' "$spec_id" >&2
            exit 0
        fi

        # Tudo concluído. Verifica se o ciclo já rodou.
        if [[ ! -f "$spec_dir/qa/test-plan.md" ]]; then
            cat >&2 <<EOF
[QA-CYCLE-TRIGGER] Implementação detectada como completa.

  spec: $spec_id
  arquivo: $file_path
  tarefas concluídas: $closed_count
  tarefas pendentes: 0
  qa/test-plan.md: ausente

Próximo passo OBRIGATÓRIO (CONSTITUTION §workflow item 5):

  Invoque a skill \`qa-cycle\` com SPEC_ID=$spec_id

Isto orquestra: test-planner → test-runner → bug-reporter → bug-fixer.
Não faça commit ou push até o ciclo fechar com ALL_PASS ou bugs explicitamente
escalados. Para pular este trigger (raro, exige justificativa no commit), crie
manualmente $spec_dir/qa/.skip-qa-cycle com a razão.
EOF
            # exit 2: convenção deste repo para que o agente leia a mensagem
            # e reaja. Não desfaz a edição.
            exit 2
        fi
    fi
fi

exit 0
