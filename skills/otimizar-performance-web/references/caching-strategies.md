# Caching Strategies — Referência Técnica

Índice:
1. TTL por tipo de dado
2. Cache Aside (padrão default)
3. Write-Through
4. Cache Stampede Prevention
5. Invalidação por eventos
6. O que nunca cachear

---

## 1. TTL por Tipo de Dado

| Tipo de dado | TTL máximo | Justificativa |
|---|---|---|
| Sessão / token de autenticação | Tempo de expiração do token | Revogar imediatamente ao logout |
| Dados de autorização (roles, permissões) | 60s | Usuário pode perder acesso e ainda ter permissão por 1 min — aceitável |
| Preço / saldo / limite de crédito | 60s | Dado financeiro — stale por mais que 1 min é risco de negócio |
| Perfil de usuário (nome, email, foto) | 5 min | Mudanças são raras; stale tolerável por curto período |
| Configurações do produto (feature flags) | 5 min | Alterar no painel deve propagar em minutos |
| Dados de catálogo (produtos, categorias) | 15–60 min | Mudanças editoriais — tolerância alta |
| Conteúdo estático (países, moedas, CEPs) | 1–24h | Raramente muda |
| Resultado de query agregada (relatório) | Definido pelo domínio | Documentar explicitamente quando o dado fica stale |

**Regra de ouro:** quanto mais o dado afeta dinheiro, segurança ou decisões irreversíveis, menor o TTL.

---

## 2. Cache Aside (Padrão Default)

O padrão mais seguro e portável. A aplicação gerencia o cache explicitamente.

```
Leitura:
  1. Buscar no cache
  2. Se hit → retornar
  3. Se miss → buscar no banco → escrever no cache com TTL → retornar

Escrita:
  1. Escrever no banco
  2. Invalidar (DEL) a chave no cache — nunca escrever no cache primeiro
```

### Quando usar Cache Aside
- Leituras muito mais frequentes que escritas
- Tolerância a miss na primeira leitura após invalidação
- Dado pode ser regenerado facilmente a partir do banco

### Armadilha: escrever no cache no path de escrita
```
// NÃO — se o banco falhar após o cache ser atualizado, os dados ficam inconsistentes
await cache.set(key, newValue);
await db.update(id, newValue);  // se falhar aqui, cache tem valor que não existe no banco

// SIM — banco é a fonte de verdade; cache é derivado
await db.update(id, newValue);
await cache.del(key);           // próximo read vai ao banco e reconstrói o cache
```

---

## 3. Write-Through

Escrita no banco e no cache acontecem **juntas**, de forma síncrona.

```
Escrita:
  1. Escrever no banco
  2. Escrever no cache (com TTL)

Leitura:
  1. Buscar no cache
  2. Se miss → buscar no banco (não deveria acontecer com frequência)
```

### Quando usar Write-Through
- Leituras muito frequentes logo após escritas (ex: feed de atividades)
- Dado caro de recomputar e sempre atualizado após escrita
- Não usar quando: volumes de escrita são altos e a maioria das chaves nunca é lida após escrita (popula cache desnecessariamente)

### Implementação
```typescript
async function updateUserWriteThrough(id: string, data: UpdateUserDto): Promise<User> {
  const user = await db.user.update({ where: { id }, data });
  await redis.set(`user:${id}`, JSON.stringify(user), { EX: 300 });
  return user;
}
```

---

## 4. Cache Stampede Prevention

Quando o TTL de uma chave popular expira, múltiplas requisições simultâneas podem ir ao banco ao mesmo tempo — thundering herd localizado.

### Estratégia 1: Mutex com Redis (redlock)
```
1. Verificar cache → miss
2. Tentar adquirir lock distribuído
3. Se conseguiu o lock:
   a. Verificar cache novamente (double-check)
   b. Se ainda miss → buscar no banco → escrever no cache → liberar lock
4. Se não conseguiu o lock → aguardar e tentar cache novamente
```

Ver implementação em Node.js: `references/nodejs-patterns.md` seção 7.
Ver implementação em Kotlin: usar `RedissonClient` com `RLock`.

### Estratégia 2: Probabilistic Early Recompute

Recomputar o cache antes do TTL expirar, com probabilidade crescente conforme o TTL se aproxima.

```
// Recomputa mais cedo com probabilidade 1/TTL_restante
// Evita stampede sem lock, ao custo de ocasionalmente recomputar antes do necessário
```

Útil para dados caros de computar onde o lock causaria latência perceptível.

### Estratégia 3: Cache com TTL estendido + background refresh

```typescript
interface CacheEntry<T> {
  data: T;
  expiresAt: number;    // timestamp de expiração "lógica"
  hardExpiresAt: number; // timestamp de expiração real (expiresAt + buffer)
}

async function getWithBackgroundRefresh<T>(key: string, fetcher: () => Promise<T>): Promise<T> {
  const cached = await redis.get(key);
  if (cached) {
    const entry = JSON.parse(cached) as CacheEntry<T>;
    if (Date.now() > entry.expiresAt) {
      // TTL lógico expirou, mas dado ainda está disponível — refresh em background
      fetcher().then((fresh) => {
        redis.set(key, JSON.stringify({
          data: fresh,
          expiresAt: Date.now() + 300_000,
          hardExpiresAt: Date.now() + 360_000,
        }), { EX: 360 });
      });
    }
    return entry.data;
  }

  const data = await fetcher();
  await redis.set(key, JSON.stringify({
    data,
    expiresAt: Date.now() + 300_000,
    hardExpiresAt: Date.now() + 360_000,
  }), { EX: 360 });
  return data;
}
```

---

## 5. Invalidação por Eventos

A invalidação orientada a eventos é mais precisa que TTL puro e evita dados stale desnecessários.

### Padrões de invalidação

| Evento | Chaves a invalidar |
|---|---|
| `user.updated` | `user:{id}`, `user:profile:{id}` |
| `order.created` | `orders:user:{userId}`, `dashboard:{userId}` |
| `product.price_changed` | `product:{id}`, `catalog:category:{categoryId}` |
| `permission.revoked` | `auth:permissions:{userId}` (TTL já é curto — 60s) |

### Tag-based invalidation (para invalidar grupos de chaves)

```typescript
// Ao escrever: associar a chave ao tag
await redis.sadd(`tag:user:${userId}`, cacheKey);
await redis.set(cacheKey, data, { EX: 300 });

// Ao invalidar: buscar todas as chaves do tag e deletar em bulk
async function invalidateUserTags(userId: string): Promise<void> {
  const tagKey = `tag:user:${userId}`;
  const keys = await redis.smembers(tagKey);
  if (keys.length > 0) {
    await redis.del(...keys, tagKey);
  }
}
```

---

## 6. O Que Nunca Cachear

| Dado | Motivo |
|---|---|
| Tokens de autenticação não expirados | Cache adiciona vetor de vazamento; o próprio token já é um cache de sessão |
| Dados com escrita concorrente alta e leitura rara | Overhead de manter cache > benefício |
| Resultados de queries que variam por permissão de usuário | Cache por usuário explode cardinalidade; cache global vaza dados entre usuários |
| Stack traces e mensagens de erro detalhadas | Exposição de dados internos via cache compartilhado |
| Dados de PII sem criptografia no cache | Violação de LGPD/GDPR — dados pessoais em cache devem ser criptografados ou evitados |

### Cache de autorização — risco especial

Nunca cachear "este usuário TEM permissão X" por mais de 60s sem mecanismo de invalidação imediata para revogação. Um usuário desativado pode continuar com acesso por TTL inteiro.

Solução: TTL curto (30–60s) + invalidação ativa no evento de revogação/desativação.
