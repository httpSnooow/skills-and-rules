---
name: migracoes-zero-downtime
description: >-
  Generates database migrations that are safe for zero-downtime, continuous
  deployments using the Expand and Contract pattern. Use when adding, renaming,
  removing columns/tables/indexes, or changing constraints on live production
  databases. Never generate a destructive migration without signaling the risk.
---

# Migrações Zero Downtime — Expand and Contract

## Quando aplicar

Ao gerar qualquer migration de banco de dados (SQL, Prisma, Alembic, Flyway, ActiveRecord)
que altere o schema de tabelas com dados de produção ou em sistemas sem janela de manutenção.

**Não aplicar** para: bancos de desenvolvimento local, seeds descartáveis, tabelas criadas
no mesmo sprint sem dados de produção.

## Proibições absolutas (nunca gerar sem sinalizar explicitamente)

Antes de gerar qualquer uma das operações abaixo, **sinalizar o risco** e apresentar
a alternativa segura:

| Operação perigosa | Risco | Alternativa segura |
|-------------------|-------|--------------------|
| `DROP COLUMN` direto | Quebra código que ainda referencia a coluna | Expand and Contract (3 deploys) |
| `ALTER COLUMN ... NOT NULL` sem default | Trava a tabela se tiver linhas existentes | Adicionar default primeiro |
| `RENAME COLUMN` | Quebra código e queries com o nome antigo | Expand and Contract (3 deploys) |
| `ALTER TABLE ADD COLUMN NOT NULL` sem default | Falha em tabelas populadas | Adicionar nullable primeiro, backfill, depois constraint |
| `DROP TABLE` direta | Dados perdidos, rollback impossível | Rename + período de quarentena |
| `CREATE INDEX` (sem CONCURRENTLY) | Trava writes na tabela durante criação | `CREATE INDEX CONCURRENTLY` |

## O Padrão Expand and Contract (obrigatório para renomear ou remover)

Qualquer renomeação ou remoção segura requer **3 deploys independentes** — nunca 1.

### Exemplo: renomear `pedidos.valor` → `pedidos.valor_total`

**Deploy 1 — Expand (adicionar o novo, manter o antigo)**
```sql
-- Migration 001: Adicionar coluna nova com valor padrão
ALTER TABLE pedidos ADD COLUMN valor_total DECIMAL(10,2) DEFAULT 0;
```
```javascript
// Código: escrever nas DUAS colunas, ler da antiga (compatibilidade)
async function criarPedido(dados) {
  return db.pedidos.create({
    valor: dados.valor,       // antigo — mantido para rollback
    valor_total: dados.valor, // novo — começa a popular
  });
}
async function getPedido(id) {
  const p = await db.pedidos.findById(id);
  return { valorTotal: p.valor }; // lê da coluna antiga ainda
}
```

**Deploy 2 — Migrate + Swap (backfill e trocar a leitura)**
```sql
-- Migration 002: Popular coluna nova com dados da antiga
UPDATE pedidos SET valor_total = valor WHERE valor_total = 0;
-- Adicionar NOT NULL após backfill
ALTER TABLE pedidos ALTER COLUMN valor_total SET NOT NULL;
```
```javascript
// Código: ainda escreve nas duas, mas LÊ da nova agora
async function getPedido(id) {
  const p = await db.pedidos.findById(id);
  return { valorTotal: p.valor_total }; // lê da nova
}
```

**Deploy 3 — Contract (remover o antigo — rollback não é mais possível)**
```sql
-- Migration 003: Remover coluna antiga (somente após N dias sem alertas)
ALTER TABLE pedidos DROP COLUMN valor;
```
```javascript
// Código: remover toda referência à coluna antiga
// Código: escrever apenas em valor_total
```

## Criação de Índices Segura

```sql
-- NÃO — bloqueia writes durante a criação (pode durar minutos em tabelas grandes)
CREATE INDEX idx_pedidos_userId ON pedidos(userId);

-- SIM — não bloqueia, pode ser executado em produção
CREATE INDEX CONCURRENTLY idx_pedidos_userId ON pedidos(userId);
```

**Desvantagem do CONCURRENTLY:** não pode rodar dentro de uma transaction block. Executar
como statement isolado no migration script, fora do `BEGIN/COMMIT`.

## Adicionando Constraints NOT NULL com Segurança

```sql
-- NÃO — falha se existirem linhas com NULL na coluna
ALTER TABLE pedidos ALTER COLUMN status SET NOT NULL;

-- SIM — 3 passos seguros
-- Passo 1: Adicionar com default (não falha em linhas existentes)
ALTER TABLE pedidos ADD COLUMN status VARCHAR(20) DEFAULT 'pending';

-- Passo 2: Backfill (em batch para tabelas grandes)
UPDATE pedidos SET status = 'pending' WHERE status IS NULL;

-- Passo 3: Adicionar constraint NOT NULL após garantir que não há NULLs
ALTER TABLE pedidos ALTER COLUMN status SET NOT NULL;
ALTER TABLE pedidos ALTER COLUMN status DROP DEFAULT; -- se o default não fizer mais sentido
```

## Migrations Reversíveis (down obrigatório)

Toda migration deve ter um `down()` definido e testado.

```javascript
// Exemplo Knex/Node
exports.up = async (knex) => {
  await knex.schema.table('pedidos', (table) => {
    table.decimal('valor_total', 10, 2).defaultTo(0);
  });
};

exports.down = async (knex) => {
  await knex.schema.table('pedidos', (table) => {
    table.dropColumn('valor_total'); // reversível sem perda de dados (ainda estão em `valor`)
  });
};
```

**Exceção:** `DROP COLUMN` no Deploy 3 do Expand and Contract **não tem down seguro**
com dados. Documentar isso explicitamente no migration e exigir aprovação do usuário.

## Checklist rápido

- [ ] A migration é reversível (`down()` definido e testado)?
- [ ] Adição de coluna `NOT NULL` tem um `DEFAULT` definido para linhas existentes?
- [ ] Criação de índice usa `CREATE INDEX CONCURRENTLY`?
- [ ] `RENAME COLUMN` ou `DROP COLUMN` em tabelas com dados segue o Expand and Contract (3 deploys)?
- [ ] A migration foi revisada com `EXPLAIN ANALYZE` para garantir que não há full table scans no backfill?
- [ ] Backfills de volume grande são feitos em chunks (nunca `UPDATE ... SET` em toda a tabela de uma vez)?

## O que evitar

- `DROP COLUMN` como primeiro passo — sempre o último, após todos os deploys.
- `RENAME COLUMN` direta — incompatível com rollback de código.
- Migrations que misturam schema change + backfill de dados em grande volume na mesma transaction.
- Executar migration de schema e deploy de código simultaneamente — sempre migrar primeiro, depois deployar.

## Referências

- [Evolutionary Database Design — Martin Fowler](https://martinfowler.com/articles/evodb.html)
- [Expand and Contract Pattern — ThoughtWorks](https://martinfowler.com/bliki/ParallelChange.html)
- [Safe Schema Migrations — GitHub Engineering Blog](https://github.blog/engineering/safe-schema-migrations/)
