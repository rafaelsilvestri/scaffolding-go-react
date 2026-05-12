#!/usr/bin/env bash
# .agent/hooks/pre-tool-use.sh
#
# Hook PreToolUse para Claude Code.
#
# Protocolo (Claude Code):
#   - Recebe JSON via STDIN com schema (campos relevantes):
#       {
#         "session_id": "...",
#         "hook_event_name": "PreToolUse",
#         "tool_name": "Bash" | "Edit" | "Write" | "MultiEdit" | ...,
#         "tool_input": { ...payload específico da tool... }
#       }
#   - Para BLOQUEAR a chamada: exit 2 + mensagem em STDERR
#   - Para permitir: exit 0
#   - exit 1 = erro não-bloqueante (o agente vê o stderr mas a tool roda)
#
# Registro: .claude/settings.json (chave hooks.PreToolUse)

set -euo pipefail

# ---------------------------------------------------------------------------
# Parsing do stdin
# ---------------------------------------------------------------------------
if ! command -v jq >/dev/null 2>&1; then
    echo "pre-tool-use: jq não instalado — hook degradado (instale com 'brew install jq' ou 'apt install jq')" >&2
    exit 0
fi

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
tool_input=$(echo "$input" | jq -c '.tool_input // {}')

block() {
    # Mensagem fica visível ao agente — seja específico para que ele saiba como reagir.
    printf 'BLOCKED by pre-tool-use: %s\n' "$1" >&2
    exit 2
}

# ---------------------------------------------------------------------------
# 1. Bash — comandos perigosos
# ---------------------------------------------------------------------------
if [[ "$tool_name" == "Bash" ]]; then
    cmd=$(echo "$tool_input" | jq -r '.command // ""')

    # rm -rf fora de pastas seguras
    if echo "$cmd" | grep -Eq 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f'; then
        if ! echo "$cmd" | grep -Eq 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f[[:space:]]+([./]*)?(dist|build|node_modules|coverage|\.next|/tmp/|\.vite)'; then
            block "rm -rf permitido apenas em dist/, build/, node_modules/, coverage/, .next/, /tmp/, .vite/"
        fi
    fi

    # git push --force em branches protegidos
    if echo "$cmd" | grep -Eq 'git[[:space:]]+push.*(--force|-f)\b'; then
        if echo "$cmd" | grep -Eq '(\b|/)(main|develop|release/)'; then
            block "git push --force proibido em main/develop/release/*"
        fi
        if [[ -z "${AGENT_FORCE_PUSH_APPROVED:-}" ]]; then
            block "git push --force exige env var AGENT_FORCE_PUSH_APPROVED=1"
        fi
    fi

    # Publicação manual de pacotes
    if echo "$cmd" | grep -Eq '(^|[^a-z])(npm|pnpm|yarn)[[:space:]]+publish'; then
        block "publish manual proibido — releases via GitHub Actions"
    fi
    if echo "$cmd" | grep -Eq '(^|[^a-z])goreleaser[[:space:]]+release'; then
        block "release manual proibido — releases via GitHub Actions"
    fi

    # Sudo
    if echo "$cmd" | grep -Eq '(^|[[:space:]])sudo([[:space:]]|$)'; then
        block "sudo proibido em ambiente local do agente"
    fi

    # curl|sh / wget|sh
    if echo "$cmd" | grep -Eq '(curl|wget)[^|]*\|[[:space:]]*(sh|bash)'; then
        block "curl|sh proibido — adicione dependência via package.json/go.mod"
    fi

    # SQL destrutivo fora de DB de teste
    if echo "$cmd" | grep -Eqi '(drop[[:space:]]+(table|database)|truncate)'; then
        if [[ -z "${AGENT_DESTRUCTIVE_MIGRATION:-}" ]]; then
            if ! echo "$cmd" | grep -Eq '_test\b'; then
                block "DROP/TRUNCATE em DB não-test exige AGENT_DESTRUCTIVE_MIGRATION=1"
            fi
        fi
    fi

    # chmod 777
    if echo "$cmd" | grep -Eq 'chmod[[:space:]]+(-[a-zA-Z]+[[:space:]]+)?777'; then
        block "chmod 777 proibido"
    fi

    # git operations que reescrevem histórico em main/release
    if echo "$cmd" | grep -Eq 'git[[:space:]]+(filter-branch|reset[[:space:]]+--hard.*\b(main|develop|release/))'; then
        if [[ -z "${AGENT_HISTORY_REWRITE:-}" ]]; then
            block "reescrita de histórico em branch protegido exige AGENT_HISTORY_REWRITE=1"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 2. Edit / Write / MultiEdit — paths sensíveis
# ---------------------------------------------------------------------------
if [[ "$tool_name" == "Edit" || "$tool_name" == "Write" || "$tool_name" == "MultiEdit" ]]; then
    file_path=$(echo "$tool_input" | jq -r '.file_path // ""')

    # arquivos *.local.* não devem ser criados versionados
    if [[ "$file_path" == *.local.* ]]; then
        block "arquivos *.local.* não devem ser criados — use *.example e adicione ao .gitignore"
    fi

    # Infraestrutura de produção
    if [[ "$file_path" == *"infrastructure/production/"* ]]; then
        block "edição em infrastructure/production/ exige aprovação humana fora do agente"
    fi

    # Constituição / ADRs / CODEOWNERS / workflows — exigem flag
    case "$file_path" in
        */.agent/CONSTITUTION.md|*/specs/adrs/*|*/.github/CODEOWNERS|*/.github/workflows/*|*/.claude/settings.json)
            if [[ -z "${AGENT_GOVERNANCE_EDIT:-}" ]]; then
                block "edição de governance ($file_path) exige AGENT_GOVERNANCE_EDIT=1 + PR revisado por CODEOWNER"
            fi
            ;;
    esac

    # Migrations já versionadas (no índice do git): não editar in-place
    if [[ "$file_path" == *"/migrations/"* && "$tool_name" == "Edit" ]]; then
        if git ls-files --error-unmatch "$file_path" >/dev/null 2>&1; then
            if [[ -z "${AGENT_MIGRATION_EDIT_APPROVED:-}" ]]; then
                block "edição de migration já versionada exige AGENT_MIGRATION_EDIT_APPROVED=1 (preferível: criar nova migration)"
            fi
        fi
    fi
fi

exit 0
