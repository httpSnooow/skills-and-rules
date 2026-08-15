---
name: engenharia-de-testes
description: >-
  Designs and implements robust tests focusing on edge cases, negative paths, 
  and error handling. Use when creating or updating test files to ensure 
  resilience beyond the happy path.
---

# Engenharia de Testes

## Quando aplicar

Ao escrever testes unitários, de integração ou E2E para novas funcionalidades ou ao corrigir bugs.

## Fluxo

1. **Mapear Cenários Ocultos**: Além do "caminho feliz", listar explicitamente: fluxos de erro, timeouts, dados nulos/indefinidos, limites máximos/mínimos (boundary values).
2. **Definir Mocks Inteligentes**: Isolar dependências externas (APIs, DBs, relógios) de forma determinística, simulando falhas (ex: rede caiu, banco retornou 500).
3. **Garantir Isolamento**: Certificar-se de que cada teste limpa seu próprio estado (teardown) e não interfere nos testes seguintes.
4. **Implementar Asserções Precisas**: Não testar apenas se "não deu erro". Verificar o payload exato de retorno, mensagens de exceção e side-effects (ex: quantas vezes uma função foi chamada).

## Checklist rápido

- [ ] Os testes cobrem entradas inválidas, vazias ou maliciosas (Edge Cases e Negative Paths)?
- [ ] O comportamento de erro (Exceptions/Rejects) está sendo testado e validado?
- [ ] Mocks e Stubs estão restaurando seus estados após cada teste (ex: `jest.clearAllMocks()`)?
- [ ] Nomes dos testes explicam claramente [Contexto] + [Ação] + [Resultado Esperado]?

## O que evitar

- Escrever testes frágeis que testam detalhes de implementação (ex: nome de variáveis internas) em vez de comportamento.
- Criar mocks vazios que sempre retornam sucesso absoluto.
