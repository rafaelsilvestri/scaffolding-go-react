# Glossário do domínio

> Vocabulário compartilhado entre humanos e agentes. Termos novos passam por
> revisão; mudanças de definição passam por ADR.

## Termos

### Endpoint
Combinação de método HTTP + path em `docs/api/openapi.yaml`. Cada endpoint
tem `operationId` único.

### Handler
Função Go em `apps/api/internal/http/handlers/` que processa uma requisição
HTTP. Não contém regra de negócio — delega ao serviço.

### Service (camada)
Camada em `apps/api/internal/service/` que orquestra regras de negócio. Recebe
DTOs do handler, chama `domain` e `storage`. Retorna entidades de domínio.

### Domain
Pacote `apps/api/internal/domain/`. Contém **apenas** entidades, regras de
negócio puras e erros sentinela. Sem I/O, sem framework.

### Storage / Repository
Pacote `apps/api/internal/storage/`. Persistência. Esconde SQL atrás de
métodos (`UserStorage.GetByID(...)`).

### Result envelope
Não. Veja ADR-0003: sucesso retorna payload direto, falha retorna schema
`Error` do OpenAPI.

### Migration
Arquivo SQL em `apps/api/migrations/` que altera o schema do banco. Forward-only.

### Spec
Documento em `specs/<id>-<slug>/spec.md` que descreve uma feature antes da
implementação. Fonte da verdade do "o quê construir".

### ADR (Architecture Decision Record)
Documento em `specs/adrs/` que registra uma decisão arquitetural com contexto
e alternativas. Imutável após `Accepted`.

### Spec drift
Divergência entre o que a spec descreve e o que o código implementa. Detectada
pelo subagent `spec-verifier` ou em CI.

### Plan mode
Estado do agente em que ele propõe mudanças mas **não** edita arquivos.
Obrigatório antes de qualquer mudança que toca > 1 arquivo.

### Subagent
Agente spawnado em contexto fresco para tarefa específica (review, research,
verificação). Retorna relatório enxuto.

### Hook
Script em `.agent/hooks/` que roda fora do loop do agente em pontos
determinísticos (pre-tool-use, post-edit). Não pode ser ignorado.

### Skill
Arquivo `SKILL.md` em `.agent/skills/<nome>/` com procedimento carregado sob
demanda quando a descrição bate com a tarefa.

### MCP (Model Context Protocol)
Protocolo para o agente acessar ferramentas externas. Versionado em `.mcp.json`.

## Convenções de nomenclatura

| Caso | Padrão | Exemplo |
|---|---|---|
| Pacote Go | lowercase, sem underscore | `apps/api/internal/http/handlers` |
| Tipo Go | PascalCase | `UserService` |
| Função/método Go | PascalCase (público) / camelCase (privado) | `CreateUser`, `validateEmail` |
| Tipo TS | PascalCase | `UserCardProps` |
| Hook React | `use` + PascalCase | `useUser` |
| Endpoint REST | kebab-case nos paths | `/users/{id}/account-details` |
| Operation ID OpenAPI | camelCase | `createUser`, `listUsers` |
| Código de erro | SCREAMING_SNAKE_CASE | `VALIDATION_FAILED` |
| Migration | `YYYYMMDDHHMM_descricao_em_snake.up.sql` | `20260509143012_add_users_email_index.up.sql` |
