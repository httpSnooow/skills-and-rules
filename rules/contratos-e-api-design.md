# Contratos e API Design — Princípios de Contrato Imutável

> **APIs públicas são contratos, não implementações.** Uma vez que um cliente depende
> de um campo, removê-lo ou renomeá-lo é uma breaking change — independentemente de
> quão "óbvio" seja o erro de design original.

## 1. Versionamento Obrigatório para Breaking Changes

Nunca modificar uma API pública de forma que quebre clientes existentes sem versionar.

**O que é uma breaking change:**
- Remover um campo da resposta
- Renomear um campo (`userId` → `user_id`)
- Mudar o tipo de um campo (string → number)
- Tornar um campo obrigatório que era opcional
- Mudar a semântica de um campo (valor muda de significado)

**O que NÃO é breaking change (sempre seguro):**
- Adicionar um campo novo opcional na resposta
- Adicionar um parâmetro opcional novo na request
- Adicionar um novo endpoint
- Adicionar novos valores em um enum (com cautela — clientes devem tolerar valores desconhecidos)

**Estratégia de versionamento:**
```
/api/v1/pedidos  ← versão atual, nunca quebrar
/api/v2/pedidos  ← nova versão com breaking changes
```

Manter versões antigas por tempo mínimo definido (ex: 6 meses) antes de deprecar.

## 2. Envelope de Resposta Consistente

Todas as APIs devem retornar um envelope consistente — nunca retornar tipos diferentes
dependendo do status.

**SIM / NÃO:**

```json
// NÃO — tipos diferentes de resposta quebram clientes
// Sucesso: { "id": 1, "nome": "João" }
// Erro: { "message": "Not found" }
// Outro erro: "Unauthorized"  ← string pura

// SIM — envelope consistente sempre
// Sucesso
{
  "data": { "id": 1, "nome": "João" },
  "meta": { "requestId": "abc-123" }
}

// Erro (sempre o mesmo formato)
{
  "error": {
    "code": "USER_NOT_FOUND",      // código de máquina, estável
    "message": "Usuário não encontrado",  // mensagem humana, pode mudar
    "details": []                   // detalhes adicionais (validações, etc.)
  },
  "meta": { "requestId": "abc-123" }
}
```

**Nunca** expor stack traces, queries SQL, caminhos de arquivo ou detalhes de implementação
em mensagens de erro para o cliente (ver `seguranca.md`).

## 3. IDs Opacos — Nunca Expor IDs Sequenciais de Banco

IDs sequenciais expõem volume de negócio (concorrência pode enumerar recursos) e
facilitam ataques de enumeração (IDOR).

```
// NÃO — expõe que existe um recurso de ID 1, 2, 3...
GET /pedidos/1
GET /pedidos/2

// SIM — IDs opacos (UUID v4 ou nanoid)
GET /pedidos/01ARZ3NDEKTSV4RRFFQ69G5FAV
```

Usar UUID v4 ou um gerador de ID curto e opaco (ex: `nanoid`, `cuid2`) para IDs expostos
publicamente. Manter IDs sequenciais internamente no banco se necessário (melhor performance
de índice), mas nunca expô-los na API.

## 4. Paginação Padronizada

Usar cursor-based pagination — detalhes, exemplos e justificativa de complexidade em `performance-e-escala.md`, Seção 2.

Regras de contrato:
- O payload de cursor deve usar o campo `nextCursor` (string opaca, base64) e `hasMore` (boolean).
- Nunca expor `page`/`totalPages` — incompatível com coleções que crescem e inserções concorrentes.
- `total` só quando explicitamente pedido pelo cliente — `COUNT(*)` é caro e não escala.

## 5. Campos Obrigatórios vs Opcionais na Request

- **Campos de criação (POST):** listar explicitamente quais são obrigatórios e quais têm default.
- **Campos de atualização (PATCH):** todos os campos são opcionais — atualizar apenas o que foi enviado (PATCH semântico, não PUT completo).
- **Nunca** silenciosamente ignorar campos desconhecidos enviados pelo cliente — ou rejeitar com erro claro (strict mode) ou documentar que campos extras são ignorados.

## 6. Idempotência em Operações Mutantes

Operações que mudam estado devem ser idempotentes — implementação com Idempotency-Key em `resiliencia-e-fallback.md`, Seção 5.

Regras de contrato:
- Campos sensíveis obrigatórios: operações financeiras, envio de email/SMS, criação de recursos únicos, webhooks recebidos de terceiros.
- O cliente gera a chave uma vez por operação (não por retry) — deve ser UUID v4 ou equivalente.
- O servidor retorna o resultado original sem reprocessar se a chave já foi processada.

## 7. Tolerância a Novos Valores (Postel's Law)

Clientes devem ser **liberais no que aceitam** (tolerar campos novos, valores desconhecidos em enums)
e **conservadores no que enviam** (enviar apenas o mínimo necessário).

```typescript
// NÃO — quebra se a API adicionar um status novo
if (status === 'pendente' || status === 'processando') {
  // ignora outros status silenciosamente — bug latente
}

// SIM — tolerante a novos valores
if (status === 'pendente' || status === 'processando') {
  // lógica para esses casos
} else {
  logger.warn('status.desconhecido', { status }); // log mas não quebra
}
```

## O que evitar

- Retornar HTTP 200 para erros de negócio — usar 4xx/5xx adequados.
- Usar verbos HTTP errados: GET que modifica estado, POST que só lê.
- Retornar arrays vazios `[]` e objetos nulos `null` de forma inconsistente para "sem dados".
- Datas em formato não-padronizado — sempre ISO 8601 UTC (`2024-01-15T10:30:00Z`).
- Misturar snake_case e camelCase na mesma API.

## 8. GraphQL — Contratos de Schema

Quando a API usa GraphQL:
- **Nunca remover um campo do schema** sem deprecar primeiro com `@deprecated(reason: "Use X em vez disso")`.
- **Erros de negócio** vão no array `errors` da response — nunca HTTP 200 com `data: null` sem explicação no `errors`.
- **N+1 em resolvers:** cada resolver que acessa banco deve usar DataLoader — ver `performance-e-escala.md` Seção 1.
- **Mutações** seguem as mesmas regras de idempotência de REST (Seção 6 desta rule).

## 9. Webhooks — Receptor Seguro e Assimíncrono

Ao implementar endpoints receptores de webhook:

```typescript
// SIM — verificar assinatura HMAC antes de processar
async function receberWebhook(req: Request, res: Response) {
  const assinatura = req.headers['x-signature-256'];
  const payload = req.body;

  if (!verificarHmac(payload, assinatura, process.env.WEBHOOK_SECRET)) {
    return res.status(401).end();
  }

  res.status(200).end(); // responder 200 imediatamente
  await fila.publicar('webhook.recebido', payload); // processar de forma assíncrona
}

// NÃO — processar sincronamente: o provider vai retentar se não receber 200 rápido
```

**Regras de webhook:**
- Verificar assinatura HMAC antes de qualquer processamento (`X-Signature-256` ou equiv.).
- Responder HTTP 200 imediatamente e processar de forma assíncrona.
- Implementar idempotência no receptor — o mesmo evento pode ser entregue mais de uma vez.

## 10. Deprecation de Versão de API

Ao descontinuar uma versão de API:
- Adicionar o header `Sunset: <data ISO 8601>` nas respostas da versão deprecated (RFC 8594).
- Adicionar `Deprecation: true` como header adicional de sinalização.
- Manter a versão antiga funcionando pelo período mínimo declarado antes do sunset.
- Nunca remover uma versão sem o header `Sunset` ter ficado ativo por pelo menos 30 dias.

## Referências

- [Google API Design Guide](https://cloud.google.com/apis/design)
- [Stripe API Design Principles](https://stripe.com/blog/payment-api-design)
- [API Improvement Proposals — aip.dev](https://aip.dev/)
- [RFC 8594 — Sunset HTTP Header](https://www.rfc-editor.org/rfc/rfc8594)

