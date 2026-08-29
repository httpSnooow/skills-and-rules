# SQL Patterns — Referência Técnica

Índice:
1. N+1 com SQL puro
2. Cursor pagination
3. Índices: DDL e quando usar cada tipo
4. EXPLAIN ANALYZE — output e interpretação
5. Bulk insert/update
6. Partial index e covering index

---

## 1. N+1 com SQL Puro

### Problema
```sql
-- Aplicação faz 1 query + N queries adicionais
SELECT id, user_id FROM orders LIMIT 100;
-- Para cada order:
SELECT id, name FROM users WHERE id = $1;  -- executado 100x
```

### Solução: JOIN
```sql
SELECT
  o.id        AS order_id,
  o.total,
  o.created_at,
  u.id        AS user_id,
  u.name      AS user_name,
  u.email     AS user_email
FROM orders o
INNER JOIN users u ON u.id = o.user_id
WHERE o.created_at > NOW() - INTERVAL '30 days'
ORDER BY o.created_at DESC
LIMIT 100;
```

### Solução: Batch Fetch (quando JOIN não é viável)
```sql
-- 1. Buscar os IDs de usuário dos pedidos
SELECT DISTINCT user_id FROM orders WHERE id = ANY($1::uuid[]);

-- 2. Buscar todos os usuários em uma query
SELECT id, name, email FROM users WHERE id = ANY($1::uuid[]);
```

---

## 2. Cursor Pagination

### Cursor simples (por id monotônico)
```sql
-- Primeira página
SELECT id, user_id, total, created_at
FROM orders
ORDER BY id
LIMIT 20;

-- Páginas seguintes (lastSeenId = último id da página anterior)
SELECT id, user_id, total, created_at
FROM orders
WHERE id > :lastSeenId
ORDER BY id
LIMIT 20;
```

### Cursor composto (ordenação por coluna não-única)
Quando `ORDER BY created_at` e `created_at` pode ter duplicatas, usar cursor composto:
```sql
-- Cursor = (created_at, id) para garantir unicidade
SELECT id, user_id, total, created_at
FROM orders
WHERE (created_at, id) > (:lastCreatedAt, :lastId)
ORDER BY created_at, id
LIMIT 20;
```

O cursor enviado ao cliente é o par `(created_at, id)` serializado (ex: base64 de JSON).

### Por que não OFFSET
```
OFFSET 100000 com LIMIT 20:
  → banco lê e descarta 100.000 linhas antes de retornar 20
  → O(n) — custo cresce linearmente com a página
  → Insere/deletes concorrentes fazem linhas "pular" ou "repetir" entre páginas
```

---

## 3. Índices: DDL e Quando Usar Cada Tipo

### Regra de criação em produção
```sql
-- SEMPRE usar CONCURRENTLY — evita lock de escrita durante criação
-- Sem CONCURRENTLY: trava UPDATE/INSERT/DELETE até completar (minutos em tabelas grandes)
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);
```

### Índice simples — coluna de alta cardinalidade
```sql
-- Bom para: id, email, uuid, created_at, foreign key
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);
CREATE INDEX CONCURRENTLY idx_users_email    ON users(email);
```

### Índice composto — múltiplas colunas em conjunto
```sql
-- ORDER BY status, created_at DESC → índice composto na mesma ordem
-- A ordem das colunas importa: (status, created_at) serve para WHERE status = X ORDER BY created_at
-- mas NÃO serve para WHERE created_at > X sem o prefixo status
CREATE INDEX CONCURRENTLY idx_orders_status_created
  ON orders(status, created_at DESC);
```

### Partial Index — coluna de baixa cardinalidade
```sql
-- Coluna booleana ou enum: índice simples tem baixa seletividade
-- Partial index indexa apenas o subconjunto relevante → menor, mais rápido
CREATE INDEX CONCURRENTLY idx_orders_pending
  ON orders(created_at)
  WHERE status = 'pending';

-- Uso: SELECT id FROM orders WHERE status = 'pending' ORDER BY created_at
-- O planner usa o partial index se a condição WHERE status = 'pending' estiver presente
```

### Covering Index (INCLUDE) — index-only scan
```sql
-- Inclui colunas extras no índice para evitar heap fetch
-- Usado quando a query seleciona apenas as colunas cobertas
CREATE INDEX CONCURRENTLY idx_users_email_covering
  ON users(email)
  INCLUDE (id, name, plan);

-- Query: SELECT id, name, plan FROM users WHERE email = $1
-- → index-only scan: nenhum acesso ao heap, apenas ao índice
```

### Quando NÃO criar índice
- Colunas booleanas isoladas (use partial index)
- Tabelas < 1.000 linhas — Seq Scan é mais rápido
- Colunas raramente usadas em WHERE/JOIN — overhead de escrita supera benefício

---

## 4. EXPLAIN ANALYZE — Output e Interpretação

### Como executar
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id, total FROM orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT 10;
```

### Sinais de alerta no output

| Sinal | O que significa | Ação |
|---|---|---|
| `Seq Scan on <table>` | Varredura completa da tabela | Verificar se existe índice na coluna do WHERE |
| `cost=X..Y` com Y alto (>10.000) | Custo estimado alto | Rodar `EXPLAIN ANALYZE` com dados reais para confirmar |
| `rows=N` muito maior que o real | Estatísticas desatualizadas | Rodar `ANALYZE <table>` para atualizar estatísticas |
| `Nested Loop` com `loops=N` alto | Pode virar O(n²) | Avaliar Hash Join ou índice na coluna de join |
| `Buffers: shared hit=0 read=N` | Dados não estão em cache do banco | Normal na primeira execução; preocupante se persistir |
| `actual time=X..Y` com Y muito maior que estimativa | Planner subestimou o custo | Atualizar estatísticas + verificar índices |

### Exemplo anotado
```
Limit  (cost=0.56..8.72 rows=10 width=16) (actual time=0.043..0.071 rows=10 loops=1)
  ->  Index Scan using idx_orders_user_created on orders
        (cost=0.56..816.72 rows=1000 width=16) (actual time=0.041..0.067 rows=10 loops=1)
        Index Cond: (user_id = '...'::uuid)    ← usa o índice ✅
        Filter: (deleted_at IS NULL)           ← filtro pós-index — avaliar partial index se >50% descartado

Planning Time: 0.120 ms
Execution Time: 0.095 ms                      ← saudável para esta query
```

```
Seq Scan on orders  (cost=0.00..48234.00 rows=1000000 width=16)  ← ⚠️ Seq Scan
  (actual time=0.012..2341.234 rows=1000000 loops=1)             ← ⚠️ 2.3 segundos
  Filter: (status = 'active'::text)
  Rows Removed by Filter: 4200000                                ← 80% descartado
```
→ Criar `CREATE INDEX CONCURRENTLY idx_orders_status ON orders(status)` ou partial index.

---

## 5. Bulk Insert / Update

### Bulk INSERT (PostgreSQL)
```sql
-- Múltiplos valores em um statement
INSERT INTO logs (user_id, event, created_at)
VALUES
  ($1, $2, $3),
  ($4, $5, $6),
  ($7, $8, $9)
ON CONFLICT DO NOTHING;  -- ou ON CONFLICT (id) DO UPDATE SET ...
```

### Bulk UPDATE com unnest
```sql
UPDATE orders AS o
SET status = v.status
FROM (
  SELECT unnest($1::uuid[]) AS id, unnest($2::text[]) AS status
) AS v
WHERE o.id = v.id;
```

### Chunking obrigatório para volumes grandes
```
> 1.000 registros → dividir em chunks de 500
> 100.000 registros → considerar COPY para inserts, jobs de background para updates
```

---

## 6. Partial Index e Covering Index — Casos de Uso Avançados

### Partial Index em soft delete
```sql
-- Apenas registros não deletados entram no índice
-- Muito menor que um índice completo em tabelas com alta taxa de delete
CREATE INDEX CONCURRENTLY idx_orders_active_user
  ON orders(user_id, created_at DESC)
  WHERE deleted_at IS NULL;
```

### Covering Index em query de listagem
```sql
-- Query de listagem que nunca precisa ir ao heap
CREATE INDEX CONCURRENTLY idx_products_category_covering
  ON products(category_id, created_at DESC)
  INCLUDE (id, name, price, thumbnail_url)
  WHERE active = true;

-- Query correspondente — index-only scan se todas as colunas estão no INCLUDE
SELECT id, name, price, thumbnail_url
FROM products
WHERE category_id = $1 AND active = true
ORDER BY created_at DESC
LIMIT 20;
```
