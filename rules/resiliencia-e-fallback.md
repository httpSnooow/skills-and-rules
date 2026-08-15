# Resiliência e Fallback — Sistemas que Falham com Graciosidade

> **Assuma que tudo vai falhar.** Redes caem, bancos travam, APIs externas retornam 503.
> O código que não tem estratégia de falha vai derrubar o usuário em produção.
> Resiliência não é opcional — é parte do critério de pronto de qualquer integração.

## 1. Timeout Obrigatório em Toda Chamada Externa

Nunca fazer uma chamada de rede ou I/O sem timeout definido.
Sem timeout, uma dependência lenta pode segurar todas as threads/workers e derrubar o serviço.

**SIM / NÃO:**

```javascript
// NÃO — sem timeout, pende indefinidamente se o serviço externo travar
const response = await fetch('https://api.externa.com/dados');

// SIM — timeout explícito
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 5000); // 5s máximo
try {
  const response = await fetch('https://api.externa.com/dados', {
    signal: controller.signal,
  });
  return response.json();
} catch (err) {
  if (err.name === 'AbortError') throw new TimeoutError('api.externa timeout após 5s');
  throw err;
} finally {
  clearTimeout(timeout);
}
```

**Timeouts recomendados por tipo de operação:**

| Operação | Timeout sugerido |
|----------|-----------------|
| Query de banco simples | 2-5s |
| API interna (mesma rede) | 2-3s |
| API externa (internet) | 5-10s |
| Upload de arquivo grande | Definir por tamanho, não fixo |
| Job de background | Sem limite fixo, mas com deadletter |

## 2. Retry com Exponential Backoff e Jitter

Falhas transitórias (rede instável, rate limit, serviço reiniciando) se resolvem com retry.
Falhas permanentes (404, 400, autenticação inválida) **não devem ser retriadas**.

**SIM / NÃO:**

```javascript
// NÃO — retry imediato que amplifica a carga em um serviço já sobrecarregado
for (let i = 0; i < 3; i++) {
  try {
    return await callExternalService();
  } catch (err) {
    // retry imediato — thundering herd problem
  }
}

// SIM — exponential backoff com jitter (evita thundering herd)
async function withRetry(fn, maxAttempts = 3) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (!isRetryable(err) || attempt === maxAttempts) throw err;

      // Exponential backoff: 1s, 2s, 4s + jitter aleatório
      const baseDelay = Math.pow(2, attempt - 1) * 1000;
      const jitter = Math.random() * 500; // evita thundering herd
      await sleep(baseDelay + jitter);
    }
  }
}

function isRetryable(err) {
  // Retriar apenas: timeout, 429, 503, 502, erros de rede
  // Não retriar: 400, 401, 403, 404, 422 — são erros do cliente
  return err instanceof TimeoutError
    || [429, 503, 502, 504].includes(err.status);
}
```

## 3. Circuit Breaker — Parar de Tentar Quando a Dependência Está Caída

Retry sem circuit breaker pode amplificar a carga em um serviço já sobrecarregado.
O Circuit Breaker detecta quando uma dependência está consistentemente falhando e
para de chamar temporariamente, retornando o fallback imediatamente.

```
Estados do Circuit Breaker:

CLOSED (normal)    → chamadas passam normalmente
   ↓ N falhas em M segundos
OPEN (disparado)   → chamadas falham imediatamente com fallback (sem tentar)
   ↓ após T segundos
HALF-OPEN (teste)  → uma chamada de teste passa
   ↓ se sucesso
CLOSED (recuperado)
   ↓ se falha
OPEN (volta a bloquear)
```

**Configuração sugerida para APIs externas:** abrir após 5 falhas em 60s, testar após 30s.

Bibliotecas: `opossum` (Node.js), `resilience4j` (Java), `polly` (C#), `pybreaker` (Python).

## 4. Graceful Degradation — Fallback Útil, não Erro Catastrófico

Quando uma dependência não-crítica falha, não derrubar toda a experiência do usuário.
Retornar uma resposta degradada mas funcional.

**SIM / NÃO:**

```javascript
// NÃO — serviço de recomendações caindo derruba toda a página
async function getHomePage(userId) {
  const recomendacoes = await recommendationService.get(userId); // pode falhar
  return renderPage({ recomendacoes }); // falha junto se o serviço cair
}

// SIM — falha silenciosa com fallback gracioso
async function getHomePage(userId) {
  let recomendacoes = [];
  try {
    recomendacoes = await withTimeout(recommendationService.get(userId), 2000);
  } catch (err) {
    // serviço não-crítico — logar, não propagar
    logger.warn('recommendation.service.unavailable', { userId });
    metrics.increment('recommendation.fallback.total');
    // recomendacoes permanece [] — UI mostra lista vazia ou produtos populares
  }
  return renderPage({ recomendacoes });
}
```

**Regra de prioridade:** classificar cada dependência como:
- **Crítica** (a feature não faz sentido sem ela) → falha propaga, alertar imediatamente
- **Importante** (degrada a experiência mas não impede o fluxo principal) → fallback
- **Opcional** (enriquecimento) → silenciar falha, usar cache ou default

## 5. Idempotência — Operações Seguras para Retry

Operações que mudam estado devem ser seguras para retentar sem causar efeitos colaterais duplos.

**Padrão de idempotency key:**

```javascript
// Cliente gera um ID único por operação (não por retry)
const idempotencyKey = crypto.randomUUID(); // gerado uma vez, reutilizado nos retries

// Chamada retentável com segurança
await fetch('/api/pagamentos', {
  method: 'POST',
  headers: {
    'Idempotency-Key': idempotencyKey, // mesma chave em todos os retries
  },
  body: JSON.stringify({ valor: 100, moeda: 'BRL' }),
});

// Servidor: se já processou essa chave, retornar o resultado original sem reprocessar
```

**Operações que SEMPRE devem ser idempotentes:** cobranças, envio de email/SMS,
criação de recursos únicos, webhooks recebidos de terceiros.

## 6. Deadletter e Auditoria para Jobs Assíncronos

Mensagens de fila que falham repetidamente não devem ser perdidas silenciosamente.

```javascript
// Configurar Dead Letter Queue (DLQ) para mensagens que excedem maxAttempts
// AWS SQS, RabbitMQ, Kafka — todos têm suporte nativo

// Após mover para DLQ:
// 1. Alertar (não deixar a mensagem apodrecer em silêncio)
// 2. Ter processo de replay manual para re-processar após o fix
// 3. Logar o motivo da falha com contexto suficiente para debug
```

## Checklist rápido

- [ ] Toda chamada a serviço externo tem timeout definido?
- [ ] Retries usam exponential backoff com jitter (não retry imediato)?
- [ ] A lógica de retry distingue erros retriáveis (503, timeout) de não-retriáveis (400, 404)?
- [ ] Dependências não-críticas têm fallback gracioso (não derrubam a feature principal)?
- [ ] Operações mutantes (pagamentos, emails) são idempotentes?
- [ ] Jobs assíncronos têm Dead Letter Queue configurada?

## O que evitar

- Retry sem limite de tentativas — pode gerar loop infinito.
- Retry em erros 4xx do cliente — são erros permanentes, não transitórios.
- Fallback que silencia erros críticos — log e métrica são obrigatórios mesmo no fallback.
- "Vou adicionar circuit breaker depois" — adicione na primeira versão; o custo de adicionar depois é 10x maior.

## Referências

- [Netflix Hystrix — Latency and Fault Tolerance](https://github.com/Netflix/Hystrix/wiki)
- [AWS Well-Architected Framework — Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/)
- [Release It! — Michael Nygard (livro)](https://pragprog.com/titles/mnee2/release-it-second-edition/)
