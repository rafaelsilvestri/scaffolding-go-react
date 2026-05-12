#!/usr/bin/env bash
# DEPRECATED — substituído por post-tool-use.sh
#
# Este nome (post-edit.sh) era um placeholder genérico do relatório. Claude
# Code expõe o evento como PostToolUse com matcher de tool — a implementação
# real está em .agent/hooks/post-tool-use.sh.
#
# Mantido como redirect para evitar quebrar referências antigas.

exec "$(dirname "$0")/post-tool-use.sh" "$@"
