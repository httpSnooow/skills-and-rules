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

5. **Armadilhas de Segurança (OWASP Top 10 aplicado ao contexto):**
   - **Injeção:** se há montagem dinâmica de query SQL, comando shell, ou expressão de template — sinalizar imediatamente. Queries devem usar parâmetros/prepared statements.
   - **PII em logs:** verificar se dados pessoais (email, CPF, token, senha) aparecem em `console.log`, `logger.info`, ou similares. Log de ID é OK; log de valor sensível nunca.
   - **Hardcoded secrets:** nenhuma chave, token, senha ou URL com credencial no código. Usar variáveis de ambiente.
   - **XSS:** se o código renderiza HTML dinâmico com input de usuário — verificar sanitização. `innerHTML` com dado não sanitizado é vulnerabilidade imediata.
   - **Dependência vulnerável:** se a task introduz um novo pacote, mencionar que o usuário deve verificar o histórico de CVEs.

## Checklist rápido

- [ ] A explicação aponta ao menos 1 erro comum que desenvolvedores cometem nessa estrutura?
- [ ] Os limites de concorrência ou falhas de rede foram mencionados?
- [ ] O código gerado já inclui a proteção contra essa armadilha?
- [ ] O código manipula input de usuário? Se sim, há sanitização/validação antes de usar?
- [ ] Há dados sensíveis sendo logados ou expostos em mensagens de erro para o cliente?
