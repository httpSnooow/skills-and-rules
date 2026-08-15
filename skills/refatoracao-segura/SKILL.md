---
name: refatoracao-segura
description: >-
  Guides large-scale refactoring using the Strangler Fig and Branch by
  Abstraction patterns for zero-risk incremental migration. Use when the user
  requests a significant refactor, rewrite, library swap, or architectural
  migration that cannot be safely done in a single PR. Never do big-bang
  rewrites — always strangle, never rewrite.
---

# Refatoração Segura — Strangler Fig e Branch by Abstraction

## Quando aplicar

Quando a refatoração envolve qualquer um dos seguintes:
- Substituição de uma biblioteca central (ex: axios → fetch nativo, Mongoose → Prisma)
- Reescrita de módulo crítico com lógica de negócio complexa
- Migração arquitetural (REST → gRPC, monolito → serviços, callback → async/await)
- Qualquer mudança que não possa ser feita em 1 PR com 100% de confiança e rollback imediato

**Não aplicar** para: mudanças de 1-2 funções, renomeações, ajustes de style, refatorações
que cabem em um único PR com testes abrangentes.

## Princípio Fundamental: Nunca Big Bang

A abordagem "deletar tudo e reescrever" é proibida em código de produção. Motivos:

- Impossível testar paridade completa antes do deploy
- Rollback requer reverter toda a mudança (não incremental)
- Bugs de paridade só aparecem em produção, com usuários reais
- Merge conflicts imensos durante o período de reescrita

**Alternativa:** toda refatoração grande é uma sequência de pequenas mudanças seguras,
cada uma deployável e reversível independentemente.

---

## Padrão 1 — Strangler Fig (para módulos/serviços inteiros)

Referência: Martin Fowler. Usado no Facebook (PHP→Hack), Airbnb (monolito→microserviços),
Shopify (Rails modular).

A nova implementação "estrangula" a antiga progressivamente, como uma figueira-estranguladora
cresce ao redor de uma árvore até substituí-la completamente.

### Fluxo Obrigatório em 5 Passos

**Passo 1 — Criar a implementação nova ao lado da antiga (sem remover nada)**

```javascript
// ANTES — implementação antiga (não tocar)
// services/payment-legacy.js
export async function processPayment(order) { ... }

// NOVA — ao lado, com API idêntica
// services/payment-v2.js
export async function processPayment(order) { ... } // nova implementação
```

**Passo 2 — Criar o Router com Feature Flag**

```javascript
// services/payment.js — router que controla qual versão é usada
import { processPayment as legacyProcess } from './payment-legacy.js';
import { processPayment as v2Process } from './payment-v2.js';
import { featureFlags } from '../config/flags.js';

export async function processPayment(order) {
  if (featureFlags.isEnabled('payment-v2', order.userId)) {
    return v2Process(order);
  }
  return legacyProcess(order);
}
```

**Passo 3 — Shadow Mode (validação sem impacto em produção)**

Antes de redirecionar tráfego real, executar a nova implementação em paralelo e
comparar resultados — sem servir a resposta da nova implementação ao cliente:

```javascript
export async function processPayment(order) {
  const legacyResult = await legacyProcess(order);

  // Shadow: executa nova versão, compara, descarta a resposta
  if (featureFlags.isEnabled('payment-v2-shadow')) {
    v2Process(order)
      .then(v2Result => {
        if (!isEquivalent(legacyResult, v2Result)) {
          logger.warn('payment.v2.shadow.mismatch', {
            orderId: order.id,
            // não logar dados financeiros sensíveis
          });
          metrics.increment('payment.v2.shadow.mismatch');
        }
      })
      .catch(err => {
        metrics.increment('payment.v2.shadow.error');
        logger.error('payment.v2.shadow.error', { orderId: order.id });
      });
  }

  return legacyResult; // sempre serve a resposta da versão antiga no shadow
}
```

**Passo 4 — Rollout Progressivo (com critério de parada)**

```
0% → shadow mode (dias/semanas dependendo da criticidade)
  ↓ Zero mismatches + zero erros no shadow
1% → habilitar para 1% dos usuários (canary)
  ↓ Monitorar métricas RED + business metrics por 24h
10% → expandir para 10%
  ↓ Monitorar por 48h
50% → expandir para 50%
  ↓ Monitorar por 72h
100% → tráfego total para nova implementação
  ↓ Manter feature flag por N dias como killswitch
```

**Critério de parada (reverter imediatamente se):**
- Taxa de erro aumenta >0.1% na nova versão
- Latência p99 aumenta >20%
- Business metric (ex: `payments_processed_total`) cai

**Passo 5 — Deletar a implementação antiga (somente após critério de estabilidade)**

Critério mínimo antes de deletar:
- 100% do tráfego na nova por N dias definidos (ex: 14 dias para código financeiro)
- Zero alertas relacionados
- Feature flag mantida por esse período como killswitch

---

## Padrão 2 — Branch by Abstraction (para dependências internas)

Referência: Paul Hammant. Usado no Google para substituição de bibliotecas internas.
Ideal quando o código que precisa mudar é uma dependência usada em muitos lugares.

### Fluxo em 4 Passos

**Passo 1 — Criar uma abstração (interface/adapter) sobre a implementação atual**

```typescript
// ANTES — código acoplado diretamente ao Axios
import axios from 'axios';
export async function fetchUser(id: string) {
  const response = await axios.get(`/users/${id}`);
  return response.data;
}

// PASSO 1 — criar interface
interface HttpClient {
  get<T>(url: string): Promise<T>;
  post<T>(url: string, body: unknown): Promise<T>;
}

// Adapter que envolve o Axios atual na interface
class AxiosHttpClient implements HttpClient {
  async get<T>(url: string): Promise<T> {
    const response = await axios.get(url);
    return response.data;
  }
  async post<T>(url: string, body: unknown): Promise<T> {
    const response = await axios.post(url, body);
    return response.data;
  }
}
```

**Passo 2 — Fazer o código existente depender da abstração**

```typescript
// Código refatorado para usar a interface, não o Axios diretamente
export async function fetchUser(id: string, http: HttpClient = new AxiosHttpClient()) {
  return http.get<User>(`/users/${id}`);
}
```

**Passo 3 — Criar a nova implementação por trás da mesma interface**

```typescript
// Nova implementação usando fetch nativo
class NativeFetchHttpClient implements HttpClient {
  async get<T>(url: string): Promise<T> {
    const response = await fetch(url);
    if (!response.ok) throw new HttpError(response.status);
    return response.json() as Promise<T>;
  }
  // ...
}
```

**Passo 4 — Feature flag para trocar, depois deletar a antiga**

```typescript
const httpClient = featureFlags.isEnabled('native-fetch')
  ? new NativeFetchHttpClient()
  : new AxiosHttpClient();
```

---

## Checklist rápido

- [ ] Existe uma feature flag controlando qual implementação está ativa?
- [ ] As duas implementações têm testes cobrindo o mesmo comportamento esperado?
- [ ] O shadow mode foi ativado e monitorado antes do rollout progressivo?
- [ ] O critério de parada está definido (qual métrica dispara rollback)?
- [ ] O critério de "pronto para deletar a versão antiga" está documentado?
- [ ] O rollout é incremental (1% → 10% → 50% → 100%), não imediato?

## O que evitar

- `// TODO: remover a versão antiga depois` sem data/critério definido — a versão antiga nunca é removida.
- Fazer shadow mode com dados financeiros reais sem redação — respeitar `seguranca.md`.
- Deletar a implementação antiga antes do período de estabilidade mínimo.
- "Só essa parte é simples, posso reescrever tudo de uma vez" — não existe refatoração simples em produção.

## Referências

- [Strangler Fig Application — Martin Fowler](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [Branch by Abstraction — Paul Hammant](https://martinfowler.com/bliki/BranchByAbstraction.html)
- [Feature Flags: The Toggle Types — Pete Hodgson](https://martinfowler.com/articles/feature-toggles.html)
