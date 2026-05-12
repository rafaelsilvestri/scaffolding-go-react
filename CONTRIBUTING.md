# Contribuindo

Este repositório segue Spec-Driven Development. Antes de qualquer mudança
não-trivial:

1. **Leia a constituição** em `.agent/CONSTITUTION.md`
2. **Crie ou abra a spec** em `specs/<id>-<slug>/spec.md`
3. **Plan mode** antes de codificar (humano ou agente)
4. **Implemente contra a spec**, com testes
5. **Subagent `spec-verifier`** antes de marcar PR como ready
6. **PR com template preenchido** — ver `.github/pull_request_template.md`

## Fluxo de feature

```
ideia → issue (feature_request) → spec (specs/) → plan → tasks → impl → review → merge
```

Para correções triviais e prototipação descartável, spec não é obrigatória —
mas registre o "porquê" no PR.

## Trabalhando com o agente de AI

- Use **plan mode** quando a mudança toca > 1 arquivo
- Use **subagents** (`reviewer`, `security-auditor`, `spec-verifier`) para
  isolar contexto de tarefas pesadas
- **Confirme antes de ações irreversíveis** (deploy, migration em
  staging/prod, deleção de dados)
- **Hooks bloqueiam** comandos perigosos por design — não desative

## Mudanças que exigem ADR

- Stack (linguagem, framework, banco)
- Contrato (forma do envelope de erro, versionamento de API)
- Segurança (cripto, auth, autorização)
- Estrutura de pastas em `apps/`

## Sinais de PR pronto

- [ ] Spec referenciada
- [ ] CI verde (api, web, contract)
- [ ] Subagent `spec-verifier` reporta `CONFORMS`
- [ ] Aprovação do CODEOWNER da área
- [ ] Sem rebases que reescrevem commits revisados sem nova revisão

## Rituais sugeridos

- **Toda terça:** review aberto de specs em draft
- **Toda quinta:** "Drift Friday" — agente roda `spec-verifier` em todas as specs ativas
- **Mensal:** revisão de `.agent/rules/` e skills à luz dos erros recentes
