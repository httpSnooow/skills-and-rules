---
name: observabilidade-e-telemetria
description: >-
  Adds observability instrumentation (structured logs, metrics, distributed
  traces) to new features and services using the THREE PILLARS model
  (OpenTelemetry). Use when implementing business-critical flows, async
  operations, external API calls, or database access that needs to be
  monitored in production. If it's not observable, it's not production-ready.
---

# Observabilidade e Telemetria

## Quando aplicar

Ao implementar qualquer um dos seguintes:
- Endpoints novos ou alterações em endpoints existentes
- Workers assíncronos, filas, jobs de background
- Integrações com serviços externos (APIs de pagamento, email, SMS, storage)
- Processamento de dados de negócio (pedidos, transações, autenticação)
- Qualquer fluxo que precise de diagnóstico em produção sem acesso ao terminal

**Não aplicar** em: scripts one-off, seeds de dev, protótipos descartáveis.

## Os 3 Pilares (OpenTelemetry — padrão CNCF)

### Pilar 1 — Logs Estruturados (não texto livre)

Logs de produção devem ser JSON estruturado — nunca strings interpoladas soltas.
O objetivo é que um sistema de agregação (Datadog, Loki, CloudWatch) possa filtrar e agregar.

**SIM / NÃO:**

```
// NÃO — log de texto livre, impossível de agregar por campo
console.log(`Usuário ${user.email} fez login às ${new Date()}`);

// SIM — estruturado, filtrável, sem PII
logger.info('user.login.success', {
  userId: user.id,          // ID opaco, nunca email ou nome
  traceId: span.traceId,    // correlação com o trace distribuído
  durationMs: Date.now() - startTime,
  service: 'auth-service',
});
```

**Campos obrigatórios em logs de produção:**
- `timestamp` (ISO 8601)
- `level` (info / warn / error)
- `service` (nome do serviço)
- `traceId` (correlação com distributed trace)
- `message` (chave de evento, ex: `payment.charge.failed`)

**Proibido nos logs (ver seguranca.md):** email, CPF, token, senha, número de cartão, stack trace exposto ao cliente.

---

### Pilar 2 — Métricas (RED Method + Business Metrics)

Para cada serviço/endpoint, definir métricas usando o **Método RED**:

| Métrica | Descrição | Exemplo |
|---------|-----------|---------|
| **Rate** | Requisições por segundo | `http_requests_total{method, path, status}` |
| **Errors** | Taxa de erros | `http_errors_total{method, path, status}` |
| **Duration** | Latência (p50, p95, p99) | `http_request_duration_ms{path, quantile}` |

**Business Metrics (obrigatórias para fluxos críticos):**

Métricas de infra não substituem métricas de domínio. Adicionar counters de negócio:

```
// Pagamento processado — nunca depender só da métrica HTTP
payments_processed_total{status="success", method="credit_card"}
payments_processed_total{status="failed", reason="insufficient_funds"}

// Pedido criado
orders_created_total{channel="web", plan="premium"}

// Autenticação
auth_login_total{method="email", status="success"}
auth_login_total{method="email", status="blocked_too_many_attempts"}
```

**Regra de ouro:** Se a métrica HTTP de um endpoint cair para zero, você não consegue
distinguir "ninguém está comprando" de "o endpoint está retornando 200 mas sem processar".
As business metrics resolvem isso.

---

### Pilar 3 — Distributed Tracing (OpenTelemetry Spans)

Em qualquer chamada que cruza um boundary (serviço → banco, serviço → API externa):

**SIM / NÃO:**

```javascript
// NÃO — chamada externa sem trace
const charge = await stripe.charges.create({ amount, currency });

// SIM — chamada rastreada com span descritivo
const span = tracer.startSpan('stripe.charges.create', {
  attributes: {
    'payment.amount': amount,
    'payment.currency': currency,
    // NUNCA incluir número do cartão ou CVV nos atributos
  }
});
try {
  const charge = await stripe.charges.create({ amount, currency });
  span.setStatus({ code: SpanStatusCode.OK });
  return charge;
} catch (err) {
  span.setStatus({ code: SpanStatusCode.ERROR, message: err.message });
  span.recordException(err);
  throw err;
} finally {
  span.end();
}
```

**Nomenclatura de spans:** usar o padrão `recurso.operação` em snake_case:
- `db.query.find_user` ✅
- `stripe.charge.create` ✅
- `s3.upload.profile_image` ✅
- `operation` ❌ — sem contexto

**Context Propagation:** propagar o trace context entre serviços usando W3C TraceContext
(`traceparent` header). Sem propagação, traces ficam fragmentados e inúteis.

---

## Checklist rápido

- [ ] O novo endpoint tem métricas RED (Rate, Errors, Duration)?
- [ ] Operações de negócio críticas têm counters de domínio (além das métricas de infra)?
- [ ] Logs de produção são estruturados (JSON) com traceId?
- [ ] Chamadas a serviços externos têm spans com nome descritivo?
- [ ] Erros em integrações externas são capturados no span com status de erro?
- [ ] Nenhum dado sensível aparece em atributos de trace ou campos de log (ver seguranca.md)?
- [ ] O trace context é propagado para serviços downstream?

## O que evitar

- Usar `console.log("passou aqui")` ou `console.log("chamando API")` como substituto de trace.
- Depender apenas de métricas de infraestrutura e esquecer métricas de domínio de negócio.
- Criar spans sem nome descritivo (`span("operation")`, `span("call")`).
- Logar objetos completos de request/response sem redaction de campos sensíveis.
- Criar métricas com cardinalidade alta nos labels (ex: `userId` como label — isso explode o Prometheus).

## Referências

- [OpenTelemetry Specification](https://opentelemetry.io/docs/)
- [Google SRE Book — The Four Golden Signals](https://sre.google/sre-book/monitoring-distributed-systems/)
- [Brendan Gregg — USE Method](https://www.brendangregg.com/usemethod.html)
