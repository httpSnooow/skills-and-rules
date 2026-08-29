---
name: otimizar-performance-web
description: >-
  Diagnoses and eliminates web performance bottlenecks: N+1 queries, missing
  indexes, SELECT *, OFFSET pagination on large tables, absent connection pools,
  sequential async I/O, missing HTTP timeouts, and cache without TTL or
  invalidation. Activate whenever writing or reviewing any code that touches a
  database, makes HTTP calls to external services, or designs a caching layer —
  even when the user does not explicitly ask about performance. Subsumes the
  performande-e-escala rule for environments where that rule is not present.
  Does not cover frontend bundle optimization or Core Web Vitals; combine with
  observabilidade-e-telemetria to instrument the resulting fixes.
---

# Otimizar Performance Web

## Quando aplicar

Ativar **imediatamente** ao identificar qualquer um destes sinais no código sendo gerado ou revisado:

- Query SQL ou chamada ORM (Prisma, JPA, Hibernate, Exposed, JOOQ)
- Loop sobre resultados de banco de dados
- Chamada HTTP a serviço externo (`fetch`, `axios`, `HttpClient`, `OkHttp`, Ktor)
- Criação de conexão com banco de dados
- Leitura ou escrita em cache (Redis, Memcached, in-memory)
- Endpoint que retorna lista paginada
- Processamento em batch ou importação de dados

**Não aplicar para:** pure algorithms sem I/O, migrações de schema (ver `migracoes-zero-downtime`), instrumentação de métricas (ver `observabilidade-e-telemetria`), bundle JS/CSS (ver `engenharia-de-ui-ux`).

---

## Fluxo de Diagnóstico

Execute cada verificação na ordem abaixo antes de finalizar qualquer código com I/O.

### 1 — Detecção de N+1

Antes de escrever código que itera sobre uma coleção de resultados de banco, verificar:
**cada iteração dispara uma nova query?**

Se sim: **parar e reescrever** usando JOIN/eager load ou batch load (padrão DataLoader). Nunca gerar N+1 e deixar para o usuário corrigir depois.

Emitir no output antes de continuar:
```
⚠️ N+1 detectado: a query dentro do loop em [trecho] causará N queries adicionais.
Reescrevendo com [JOIN / eager load / batch fetch].
```

Ver exemplos concretos por stack: `references/nodejs-patterns.md` seção 1, `references/kotlin-patterns.md` seção 1.

**SIM / NÃO:**
```
// NÃO — N+1: 1 query para pedidos + N queries para usuários
const orders = await db.order.findMany();
for (const order of orders) {
  order.user = await db.user.findUnique({ where: { id: order.userId } });
}

// SIM — eager load em uma query
const orders = await db.order.findMany({ include: { user: true } });
```

---

### 2 — SELECT * Proibido

Toda query gerada lista colunas **explicitamente**. Nunca gerar `SELECT *` em código que vai a produção.

`SELECT *` expõe colunas sensíveis adicionadas no futuro, aumenta payload de rede e impede que o banco use index-only scans.

```sql
-- NÃO
SELECT * FROM users WHERE id = $1;

-- SIM
SELECT id, name, email, plan, created_at FROM users WHERE id = $1;
```

---

### 3 — Índices Ausentes

Ao gerar qualquer query com `WHERE`, `ORDER BY`, `JOIN ON` ou `GROUP BY`, verificar se a coluna tem índice. Se não houver certeza, emitir:

```
⚠️ Índice ausente: a coluna `status` na tabela `orders` provavelmente não tem índice.
Para tabelas com >10k linhas isso resulta em Seq Scan.
DDL sugerido (ver references/sql-patterns.md seção 3):
  CREATE INDEX CONCURRENTLY idx_orders_status ON orders(status);
```

Regras obrigatórias:
- Sempre `CREATE INDEX CONCURRENTLY` em produção — sem `CONCURRENTLY` trava escritas durante a criação
- Índices em colunas de baixa cardinalidade (booleanos, enum de 2 valores) não ajudam — usar **partial index** (`WHERE status = 'active'`)
- `ORDER BY col1, col2` pode se beneficiar de índice composto — verificar antes de criar índice simples

---

### 4 — EXPLAIN ANALYZE Antes de Declarar Otimizado

Antes de afirmar que uma query está otimizada para produção, recomendar:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) <query>;
```

Para diagnóstico automatizado da saída, executar:
```bash
python scripts/explain-analyzer.py < explain_output.txt
```

O script sinaliza: Seq Scan em tabelas grandes, Nested Loop com alto row count, hash join candidato a index join, custo estimado acima de threshold.

Ver `references/sql-patterns.md` seção 4 para exemplos de output e interpretação.

---

### 5 — Paginação com Cursor, Não OFFSET

Para qualquer endpoint que retorna lista paginada de coleções que crescem (>10k linhas potenciais), usar **cursor-based pagination**:

```sql
-- NÃO — O(n) full scan, degrada linearmente
SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 100000;

-- SIM — O(log n) com índice no id
SELECT id, user_id, total, created_at
FROM orders
WHERE id > :lastSeenId
ORDER BY id
LIMIT 20;
```

Payload de resposta padronizado:
```json
{
  "data": [...],
  "nextCursor": "<opaque-id>",
  "hasMore": true
}
```

Nunca usar `page`/`totalPages` em coleções grandes — `COUNT(*)` trava a tabela. Retornar `total` só quando explicitamente necessário e com custo documentado.

---

### 6 — Connection Pool Obrigatório

Nunca criar nova conexão com banco de dados dentro de um handler de request. Isso esgota file descriptors e sockets sob carga.

Ao detectar `new Connection(...)`, `new Pool()` criado por request, ou configuração de pool ausente — sinalizar e reescrever:

```
⚠️ Conexão criada por request: isso esgota conexões sob carga.
Reescrever usando pool singleton (ver references/nodejs-patterns.md seção 5 ou references/kotlin-patterns.md seção 4).
```

Ver configuração recomendada por stack em `references/nodejs-patterns.md` e `references/kotlin-patterns.md`.

---

### 7 — I/O Assíncrono Paralelo

Chamadas independentes a banco ou serviços externos **nunca** devem ser sequenciais:

```typescript
// NÃO — 300ms + 200ms = 500ms de latência
const user = await fetchUser(id);
const orders = await fetchOrders(id);

// SIM — max(300ms, 200ms) = 300ms
const [user, orders] = await Promise.all([fetchUser(id), fetchOrders(id)]);
```

Em Kotlin com coroutines: usar `async { }` + `await()` dentro de `coroutineScope { }`. Ver `references/kotlin-patterns.md` seção 5.

---

### 8 — HTTP Timeouts + Retry com Jitter

Toda chamada a serviço externo tem:
1. **Timeout** configurado (connect + read separados quando possível)
2. **Retry** com exponential backoff + jitter para erros transientes (5xx, timeout)
3. **Circuit breaker** sinalizado quando o serviço é crítico

Chamada sem timeout = candidato a thread starvation sob falha do serviço externo.

```typescript
// NÃO — sem timeout, bloqueia indefinidamente se o serviço travar
const resp = await fetch(url);

// SIM
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 5000);
try {
  const resp = await fetch(url, { signal: controller.signal });
} finally {
  clearTimeout(timeout);
}
```

Ver padrões de retry com jitter em `references/nodejs-patterns.md` seção 6 e `references/kotlin-patterns.md` seção 6.

---

### 9 — Bulk Writes, Não Loop de Inserts

Operações de escrita em loop → reescrever como bulk. Nunca gerar `INSERT` individual por iteração.

```typescript
// NÃO — N round-trips ao banco
for (const item of items) {
  await db.log.create({ data: item });
}

// SIM — 1 round-trip
await db.log.createMany({ data: items });
```

Tamanho máximo de batch: **500–1000 registros** por statement. Para volumes maiores, dividir em chunks e processar em sequência com retry por chunk.

---

### 10 — Cache: TTL Explícito + Invalidação

Cache **nunca** é gerado sem:
- **TTL máximo** explícito — quanto tempo o dado pode ficar stale?
- **Estratégia de invalidação** — qual evento invalida esse cache?

Dados de autorização, preços e saldo: TTL máximo de **60s**. Dados de configuração: até 5min. Dados estáticos (países, categorias): até 1h.

```typescript
// NÃO — cache sem TTL e sem invalidação
await redis.set(`user:${id}`, JSON.stringify(user));

// SIM
await redis.set(`user:${id}`, JSON.stringify(user), { EX: 300 }); // 5min
// E no update:
async function updateUser(id: string, data: UpdateUserDto) {
  await db.user.update({ where: { id }, data });
  await redis.del(`user:${id}`);
}
```

Ver padrões completos (cache aside, write-through, stampede prevention) em `references/caching-strategies.md`.

---

## Checklist rápido — executar antes de finalizar qualquer código com I/O

- [ ] Nenhum loop dispara query por iteração (N+1 ausente)?
- [ ] Todas as queries listam colunas explicitamente (sem `SELECT *`)?
- [ ] Colunas em `WHERE`/`ORDER BY`/`JOIN ON` têm índice ou warning foi emitido?
- [ ] Listas paginadas usam cursor em vez de OFFSET?
- [ ] Conexão com banco usa pool singleton, não criação por request?
- [ ] Chamadas independentes são paralelas (`Promise.all`, coroutines paralelas)?
- [ ] Toda chamada HTTP externa tem timeout configurado?
- [ ] Writes em loop foram reescritos como bulk (chunks de 500-1000)?
- [ ] Cache tem TTL explícito e estratégia de invalidação documentada?
- [ ] Query de produção foi marcada para revisão com `EXPLAIN ANALYZE`?

---

## O que evitar

- "Vai ser rápido com poucos dados" — escrever código que escale desde o início
- `ORDER BY RAND()` ou equivalente em tabelas grandes — full scan garantido
- Índices em colunas booleanas isoladas — baixa cardinalidade não ajuda; usar partial index
- Cache com `ttl = 0` ou sem TTL — bug latente de dado infinitamente stale
- `SELECT *` argumentando que "facilita manutenção" — colunas futuras vazam a produção sem aviso
- Criar conexão de banco dentro de Lambda/Cloud Function sem proxy externo (RDS Proxy, PgBouncer) — cold start esgota conexões
- Retry sem jitter — sincronização de retries amplifica thundering herd

---

## Referências

- `references/sql-patterns.md` — índices (simples, composto, parcial, covering), cursor pagination SQL, bulk insert, EXPLAIN ANALYZE output e interpretação
- `references/nodejs-patterns.md` — pool (pg, Prisma), DataLoader, Promise.all, fetch com timeout, retry com jitter, Redis cache
- `references/kotlin-patterns.md` — HikariCP, JPA @EntityGraph, JOOQ explicit select, coroutines paralelas, Ktor timeout, Spring Cache
- `references/caching-strategies.md` — TTL por tipo de dado, cache aside, write-through, invalidação, stampede prevention
- `references/activation-evals.md` — casos de ativação positivos e negativos para validar a description
- `scripts/explain-analyzer.py` — parser de `EXPLAIN ANALYZE` com diagnóstico de Seq Scan, custo alto e índice ausente
