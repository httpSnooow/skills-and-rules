# Node.js Performance Patterns — Referência Técnica

Índice:
1. N+1 com Prisma e DataLoader
2. Cursor pagination com Prisma
3. Bulk writes com Prisma e `pg`
4. Connection pool (`pg`, Prisma)
5. I/O assíncrono paralelo
6. HTTP timeout e retry com jitter
7. Redis cache (ioredis)

---

## 1. N+1 com Prisma e DataLoader

### Prisma: eager loading
```typescript
// NÃO — N+1
const orders = await prisma.order.findMany({ take: 100 });
for (const order of orders) {
  order.user = await prisma.user.findUnique({ where: { id: order.userId } });
}

// SIM — eager load em uma query (JOIN interno)
const orders = await prisma.order.findMany({
  take: 100,
  include: {
    user: { select: { id: true, name: true, email: true } },
  },
});
```

### DataLoader — batch automático para resolvers GraphQL ou acesso granular
```typescript
import DataLoader from 'dataloader';

const userLoader = new DataLoader<string, User>(async (userIds) => {
  const users = await prisma.user.findMany({
    where: { id: { in: [...userIds] } },
    select: { id: true, name: true, email: true },
  });
  const userMap = new Map(users.map((u) => [u.id, u]));
  return userIds.map((id) => userMap.get(id) ?? new Error(`User ${id} not found`));
});

// Uso (DataLoader bate os ids e faz 1 query por tick de event loop)
const user = await userLoader.load(order.userId);
```

**Atenção:** criar o DataLoader por request (não como singleton global) — o batch é por tick de event loop, não por cache global.

---

## 2. Cursor Pagination com Prisma

```typescript
interface PaginatedResult<T> {
  data: T[];
  nextCursor: string | null;
  hasMore: boolean;
}

async function listOrders(
  userId: string,
  cursor?: string,
  limit = 20,
): Promise<PaginatedResult<Order>> {
  const take = limit + 1;

  const orders = await prisma.order.findMany({
    where: { userId },
    take,
    ...(cursor && { cursor: { id: cursor }, skip: 1 }),
    orderBy: { id: 'asc' },
    select: { id: true, total: true, status: true, createdAt: true },
  });

  const hasMore = orders.length === take;
  const data = hasMore ? orders.slice(0, -1) : orders;

  return {
    data,
    nextCursor: hasMore ? data[data.length - 1].id : null,
    hasMore,
  };
}
```

---

## 3. Bulk Writes

### Prisma: createMany / updateMany
```typescript
// NÃO — N round-trips
for (const item of items) {
  await prisma.log.create({ data: item });
}

// SIM — 1 round-trip (Prisma usa INSERT com múltiplos values)
await prisma.log.createMany({
  data: items,
  skipDuplicates: true,
});
```

### Chunking para volumes grandes
```typescript
async function bulkCreateInChunks<T>(
  items: T[],
  createFn: (chunk: T[]) => Promise<void>,
  chunkSize = 500,
): Promise<void> {
  for (let i = 0; i < items.length; i += chunkSize) {
    const chunk = items.slice(i, i + chunkSize);
    await createFn(chunk);
  }
}

// Uso
await bulkCreateInChunks(
  allLogs,
  (chunk) => prisma.log.createMany({ data: chunk }),
);
```

### pg: INSERT bulk com pg-format ou unnest
```typescript
import { Pool } from 'pg';
import format from 'pg-format';

async function bulkInsertLogs(pool: Pool, logs: Log[]): Promise<void> {
  const values = logs.map((l) => [l.userId, l.event, l.createdAt]);
  const query = format(
    'INSERT INTO logs (user_id, event, created_at) VALUES %L ON CONFLICT DO NOTHING',
    values,
  );
  await pool.query(query);
}
```

---

## 4. Connection Pool

### pg — pool singleton
```typescript
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                // máximo de conexões simultâneas
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 2_000,
});

// Exportar o pool — nunca criar new Pool() dentro de handler de request
export { pool };
```

### Limites de pool recomendados
| Cenário | `max` sugerido |
|---|---|
| API single-instance, banco local | 10–20 |
| API multi-instance (k8s, ECS) | `(total_db_connections / n_instances) * 0.8` |
| Lambda / Serverless | Usar PgBouncer ou RDS Proxy — pool por instância não funciona |

### Prisma — datasource com pool
```
// schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  // Prisma usa pool interno; configurar via connection_limit na URL:
  // postgresql://...?connection_limit=20&pool_timeout=10
}
```

### ATENÇÃO — Serverless (Lambda, Vercel, Cloud Functions)
Cada instância cria seu próprio pool. 1.000 instâncias concorrentes = 1.000 × `max` conexões.
Solução obrigatória: **PgBouncer** (self-hosted) ou **RDS Proxy** (AWS) — um proxy que multiplexar conexões do banco.

---

## 5. I/O Assíncrono Paralelo

```typescript
// NÃO — sequencial: latência total = soma das latências
async function getDashboardData(userId: string) {
  const user = await fetchUser(userId);
  const orders = await fetchOrders(userId);
  const balance = await fetchBalance(userId);
  return { user, orders, balance };
}

// SIM — paralelo: latência total = max das latências
async function getDashboardData(userId: string) {
  const [user, orders, balance] = await Promise.all([
    fetchUser(userId),
    fetchOrders(userId),
    fetchBalance(userId),
  ]);
  return { user, orders, balance };
}
```

### Promise.allSettled — quando falha parcial é aceitável
```typescript
const results = await Promise.allSettled([fetchUser(id), fetchOrders(id)]);

const user = results[0].status === 'fulfilled' ? results[0].value : null;
const orders = results[1].status === 'fulfilled' ? results[1].value : [];
```

### Concorrência limitada — evitar sobrecarregar o banco
```typescript
import pLimit from 'p-limit';

const limit = pLimit(10);

const results = await Promise.all(
  userIds.map((id) => limit(() => processUser(id))),
);
```

---

## 6. HTTP Timeout e Retry com Jitter

### fetch nativo com AbortController
```typescript
async function fetchWithTimeout(url: string, timeoutMs = 5_000): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}
```

### Retry com exponential backoff e jitter
```typescript
interface RetryOptions {
  maxAttempts?: number;
  baseDelayMs?: number;
  maxDelayMs?: number;
}

async function withRetry<T>(
  fn: () => Promise<T>,
  { maxAttempts = 3, baseDelayMs = 100, maxDelayMs = 5_000 }: RetryOptions = {},
): Promise<T> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxAttempts) throw err;
      const exponential = baseDelayMs * 2 ** (attempt - 1);
      const jitter = Math.random() * exponential;
      await new Promise((r) => setTimeout(r, Math.min(exponential + jitter, maxDelayMs)));
    }
  }
  throw new Error('unreachable');
}

// Uso
const data = await withRetry(
  () => fetchWithTimeout('https://api.example.com/data'),
  { maxAttempts: 3, baseDelayMs: 200 },
);
```

**Jitter obrigatório:** sem jitter, todas as instâncias retentar ao mesmo tempo → thundering herd.

### Erros que devem ser retentados vs. não retentados
```typescript
function isRetryable(err: unknown): boolean {
  if (err instanceof DOMException && err.name === 'AbortError') return true; // timeout
  if (err instanceof TypeError) return true; // network error
  if (err instanceof Response) return err.status >= 500; // 5xx
  return false;
}
```

---

## 7. Redis Cache (ioredis)

### Padrão Cache Aside
```typescript
import { Redis } from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

async function getUserCached(id: string): Promise<User> {
  const cached = await redis.get(`user:${id}`);
  if (cached) return JSON.parse(cached) as User;

  const user = await prisma.user.findUniqueOrThrow({
    where: { id },
    select: { id: true, name: true, email: true, plan: true },
  });

  await redis.set(`user:${id}`, JSON.stringify(user), 'EX', 300); // 5 min
  return user;
}

async function updateUser(id: string, data: UpdateUserDto): Promise<User> {
  const user = await prisma.user.update({ where: { id }, data });
  await redis.del(`user:${id}`);
  return user;
}
```

### TTL por tipo de dado
Ver `references/caching-strategies.md` para a tabela completa.

### Cache Stampede Prevention (mutex)
```typescript
import Redlock from 'redlock';

const redlock = new Redlock([redis]);

async function getUserWithLock(id: string): Promise<User> {
  const cacheKey = `user:${id}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const lock = await redlock.acquire([`lock:${cacheKey}`], 5_000);
  try {
    const doubleCheck = await redis.get(cacheKey);
    if (doubleCheck) return JSON.parse(doubleCheck);

    const user = await prisma.user.findUniqueOrThrow({ where: { id } });
    await redis.set(cacheKey, JSON.stringify(user), 'EX', 300);
    return user;
  } finally {
    await lock.release();
  }
}
```
