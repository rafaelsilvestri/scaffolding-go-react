---
name: adicionar-migration
description: Use quando o usuário pedir para criar uma nova migration de banco
  de dados (PostgreSQL) no backend Go. Cobre nomenclatura, criação dos pares
  up/down, geração de queries sqlc, atualização do code generation e teste
  contra o banco local.
tools: [view, create_file, str_replace, bash_tool]
---

# Adicionar migration neste projeto

## Princípios

- **Forward-only.** Em produção, nunca rebobinamos. `down.sql` existe para emergências locais.
- **Nunca edite uma migration aplicada.** Se está errada, crie uma nova que corrige.
- **Migrations destrutivas requerem aprovação humana.** O hook `pre-tool-use.sh` bloqueia `DROP TABLE`/`TRUNCATE` sem flag explícita.

## Pré-condições

- Você sabe **por que** essa migration existe (link para spec ou ADR)
- O DB local está rodando (`make db-up`)
- Você não está editando uma migration que já está em `main`

## Passo a passo

### 1. Criar o par up/down

```bash
make migrate-create NAME=add_users_email_index
```

Isso cria:

```
apps/api/migrations/
  20260509143012_add_users_email_index.up.sql
  20260509143012_add_users_email_index.down.sql
```

### 2. Escrever o SQL

Um exemplo seguro:

```sql
-- 20260509143012_add_users_email_index.up.sql
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS users_email_unique_idx
  ON users (lower(email));
```

```sql
-- 20260509143012_add_users_email_index.down.sql
DROP INDEX IF EXISTS users_email_unique_idx;
```

**Regras**:

- `IF NOT EXISTS` / `IF EXISTS` quando seguro — torna re-execução idempotente
- `CREATE INDEX CONCURRENTLY` em tabelas grandes para não travar
- Defaults para colunas novas que não permitem null
- Se renomeia coluna: faça em duas migrations (adiciona nova → backfill → remove antiga) para não quebrar deploys rolling
- **Nunca** `DROP COLUMN` sem antes confirmar que não há código usando — peça aprovação humana

### 3. Aplicar localmente

```bash
make migrate-up
```

### 4. Atualizar queries sqlc (se aplicável)

Edite `apps/api/db/queries/<recurso>.sql`:

```sql
-- name: GetUserByEmail :one
SELECT * FROM users WHERE lower(email) = lower($1);
```

Regenere:

```bash
make sqlc
```

Isso atualiza `apps/api/internal/storage/queries.sql.go`.

### 5. Atualizar repositório

Em `apps/api/internal/storage/<recurso>.go`, exponha o novo método se ele for usado pelo serviço.

### 6. Testes

- Adicione teste de integração que cobre o caminho novo
- Os testes rodam contra um DB `*_test` que aplica todas as migrations no setup

## Migrations destrutivas (aprovação obrigatória)

Antes de `DROP COLUMN`, `DROP TABLE`, `TRUNCATE`, ou `ALTER COLUMN ... TYPE` que perde precisão:

1. Pare e explique ao humano:
   - O que será removido
   - Quem usa hoje (busca em `internal/`, em queries sqlc, no frontend)
   - Plano de deploy (zero-downtime?)
2. Aguarde "ok, prossiga"
3. Defina a env var `AGENT_DESTRUCTIVE_MIGRATION=1` antes de criar o arquivo
4. Após mergear, abra issue de follow-up para validar em staging

## Verificação final

```bash
make migrate-down    # confere que down funciona localmente
make migrate-up
make test-integration
```

## Anti-padrões

- ❌ Editar uma migration que já está em `main`
- ❌ Migration que faz tanto schema quanto data backfill em uma transação gigante
- ❌ `DROP TABLE` sem janela de manutenção combinada
- ❌ Mudanças de tipo (`varchar(50) → varchar(40)`) sem checar dados existentes
