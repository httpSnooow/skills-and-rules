---
name: mapeamento-de-armadilhas
description: >-
  Highlights common production pitfalls, edge cases, and anti-patterns associated 
  with the implemented code. Use when writing core business logic, asynchronous operations, or DB access.
---

# Mapeamento de Armadilhas (Gotchas & Anti-patterns)

## Quando aplicar

Após implementar ou refatorar qualquer lógica que envolva assincronismo, manipulação de estado, chamadas de banco de dados ou integração com APIs externas.

## Fluxo

No final da explicação do código, adicione uma seção chamada **"⚠️ Armadilhas Comuns neste Padrão"**, cobrindo:

1. **Gargalos de Performance:** Ex: "Se esta função for chamada dentro de um `.map()`, causará uma query N+1".
2. **Concorrência e Assincronismo:** Ex: "Falta um `await` aqui que poderia gerar *race condition* se duas requisições chegarem ao mesmo tempo".
3. **Casos de Borda (Edge Cases):** Ex: "O que acontece se o payload vier como `null` ou array vazio?".
4. **Como Evitar:** Aponte a linha exata no código onde a proteção contra essa armadilha foi colocada.

## Checklist rápido

- [ ] A explicação aponta ao menos 1 erro comum que desenvolvedores cometem nessa estrutura?
- [ ] Os limites de concorrência ou falhas de rede foram mencionados?
- [ ] O código gerado já inclui a proteção contra essa armadilha?
