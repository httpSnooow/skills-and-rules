# Performance e Escala — Anti-patterns Proibidos

> **Prioridade:** Esta rule se aplica a qualquer código que acesse banco de dados,
> processe coleções em memória, ou faça chamadas a serviços externos em loop.
> Escreva código que escale desde o início — "vai ser rápido com poucos dados" é uma dívida silenciosa.

## 1. Proibição Absoluta: Query N+1

Nunca gerar código que executa uma query dentro de um loop sobre resultados de outra query.
N+1 é o anti-pattern de performance mais comum introduzido silenciosamente por IAs ao gerar código.

**SIM / NÃO:**

```
// NÃO — N+1: 1 query para pedidos + N queries para usuários (1 por pedido)
const pedidos = await db.pedidos.findAll();
for (const pedido of pedidos) {
  pedido.usuario = await db.usuarios.findById(pedido.userId); // ← N queries
}

// SIM — 1 query com JOIN ou eager loading
const pedidos = await db.pedidos.findAll({ include: ['usuario'] });

// SIM — alternativa com batch load (DataLoader pattern)
const userIds = pedidos.map(p => p.userId);
const usuarios = await db.usuarios.findAll({ where: { id: { $in: userIds } } });
const usuarioMap = Object.fromEntries(usuarios.map(u => [u.id, u]));
const pedidosComUsuario = pedidos.map(p => ({ ...p, usuario: usuarioMap[p.userId] }));
```

Ao detectar um N+1 no código sendo gerado ou revisado, **sinalizar imediatamente** antes de continuar.

## 2. Paginação: Cursores em vez de Offsets grandes

Para paginação em tabelas que crescem (>10k linhas), usar **cursor-based pagination**.
`LIMIT 20 OFFSET 100000` força um full table scan nos 100.000 primeiros registros mesmo com índice.

**SIM / NÃO:**

```sql
-- NÃO — offset degrada linearmente com escala
SELECT * FROM pedidos ORDER BY id LIMIT 20 OFFSET 100000;
-- Tempo: O(n) — escaneia 100k registros para pular

-- SIM — cursor: escala O(log n) com índice no id
SELECT * FROM pedidos WHERE id > :lastSeenId ORDER BY id LIMIT 20;
-- Tempo: O(log n) — usa o índice diretamente
```

**Payload de resposta padronizado:**
```json
{
  "data": [...],
  "nextCursor": "eyJpZCI6MTAwMH0=",
  "hasMore": true
}
```

Nunca usar `page`/`totalPages` em coleções grandes — `COUNT(*)` trava a tabela.

## 3. Índices: nunca filtrar colunas sem índice em produção

Ao gerar queries com `WHERE`, `ORDER BY`, `JOIN ON`, ou `GROUP BY`, verificar se a coluna
tem índice. Se não houver, **mencionar explicitamente** ao usuário.

**Formato de sinalização:**

```
⚠️ Performance: A coluna `userId` na tabela `pedidos` não tem índice. Para tabelas
com >10k linhas isso resulta em full table scan. Sugestão:
CREATE INDEX CONCURRENTLY idx_pedidos_userId ON pedidos(userId);
(CONCURRENTLY evita travar leituras em produção durante a criação)
```

**Regra de ouro:** sempre usar `CREATE INDEX CONCURRENTLY` em produção — a versão sem
`CONCURRENTLY` trava toda a tabela para escrita durante a criação do índice.

## 4. Processamento em Batch, não Item a Item

Evitar loops que fazem I/O (banco, HTTP, file system) por item individual.

**SIM / NÃO:**

```javascript
// NÃO — 1 INSERT por iteração (N round-trips ao banco)
for (const item of items) {
  await db.execute('INSERT INTO logs (data) VALUES (?)', [item]);
}

// SIM — 1 INSERT bulk (1 round-trip)
const values = items.map(item => [item]);
await db.execute(
  `INSERT INTO logs (data) VALUES ${items.map(() => '(?)').join(',')}`,
  values.flat()
);

// NÃO — busca um a um
const results = [];
for (const id of ids) {
  results.push(await db.findById(id));
}

// SIM — batch fetch
const results = await db.findAll({ where: { id: { $in: ids } } });
```

**Tamanho máximo de batch:** nunca inserir >1000 registros em um único statement.
Para volumes maiores, dividir em chunks de 500-1000 e processar em sequência com retry.

## 5. Nunca Carregar Coleção Inteira em Memória

Para processar grandes volumes de dados, usar streaming ou processamento em chunks.

**SIM / NÃO:**

```javascript
// NÃO — carrega toda a tabela em memória (OOM em produção)
const todosPedidos = await db.pedidos.findAll(); // 2M registros
todosPedidos.forEach(processar);

// SIM — processa em chunks com cursor
let cursor = 0;
while (true) {
  const batch = await db.pedidos.findAll({
    where: { id: { $gt: cursor } },
    limit: 500,
    order: [['id', 'ASC']],
  });
  if (batch.length === 0) break;
  await Promise.all(batch.map(processar));
  cursor = batch[batch.length - 1].id;
}
```

## 6. SELECT * é Proibido em Código de Produção

`SELECT *` seleciona colunas desnecessárias, aumenta tráfego de rede e memória,
e pode expor campos sensíveis adicionados futuramente.

```sql
-- NÃO
SELECT * FROM usuarios WHERE id = $1;

-- SIM — listar apenas o necessário
SELECT id, nome, email, plan FROM usuarios WHERE id = $1;
```

## 7. Cache: TTL e Invalidação Explícitos

Ao adicionar cache, sempre definir:
- **TTL máximo:** tempo máximo que o dado pode estar stale
- **Estratégia de invalidação:** qual evento invalida o cache (write-through, event-driven, etc.)

Cache sem invalidação é bug latente. Dado stale em cache de autorização ou preço é incidente.

```javascript
// NÃO — cache sem TTL e sem invalidação explícita
cache.set(`user:${userId}`, userData);

// SIM — TTL definido + invalidação no evento de escrita
cache.set(`user:${userId}`, userData, { ttl: 300 }); // 5min máximo
// E no update do usuário:
async function updateUser(userId, data) {
  await db.usuarios.update(data, { where: { id: userId } });
  await cache.del(`user:${userId}`); // ← invalidação explícita
}
```

## O que evitar

- "Vai ser rápido com poucos dados" — escreva código que escale desde o início.
- Ignorar `EXPLAIN ANALYZE` antes de considerar uma query otimizada para produção.
- Usar `SELECT *` quando apenas 2-3 colunas são necessárias.
- Criar índices em colunas de baixa cardinalidade (ex: coluna booleana `ativo`) — não ajuda.
- Usar `ORDER BY RAND()` ou equivalente em tabelas grandes — full table scan garantido.
