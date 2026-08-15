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

## Pirâmide de Testes (quando usar cada tipo)

- **Unitários:** lógica de domínio pura, funções sem side-effects, validações — a maioria dos testes deve ser aqui. Rápidos, baratos, determinísticos.
- **Integração:** I/O real (banco, file system, HTTP interno) — menos testes, mais valor por teste. Usam containers ou serviços reais em ambiente controlado.
- **E2E:** fluxos críticos de negócio do ponto de vista do usuário — poucos, caros, só para o que não pode quebrar silenciosamente.
- **Regra de ouro:** se um teste unitário obriga um mock de 5+ dependências, provavelmente é um teste de integração disfarçado — promova-o em vez de empilhar mocks.

## TDD para Correção de Bugs (Obrigatório)

Ao corrigir qualquer bug não-trivial, seguir esta ordem estrita — **nunca inverter**:

1. **Escreva o teste que falha PRIMEIRO**, reproduzindo o bug no menor contexto possível.
   Confirme que ele falha **antes** de qualquer mudança no código de produção.
2. **Escreva o mínimo de código** para fazer o teste passar.
3. **Refatore** se necessário, mantendo o teste verde.

> Jamais escreva um teste de regressão *após* já ter corrigido o código — você nunca
> saberá se o teste teria detectado o bug ou se é apenas um teste que sempre passou.

**SIM / NÃO:**

```
// NÃO — fix sem teste prévio (invalida a regressão)
function calcularDesconto(valor, tipo) {
  return tipo === 'percentual' ? valor * 0.9 : valor - 10; // já corrigido
}
test('desconto percentual', () => expect(calcularDesconto(100, 'percentual')).toBe(90)); // sempre passa

// SIM — teste que falha primeiro, depois o fix
test('desconto percentual aplica 10%', () => {
  // Esse teste FALHA antes do fix — isso prova que é um bom teste de regressão
  expect(calcularDesconto(100, 'percentual')).toBe(90);
});
// Agora escreva o fix até o teste passar.
```

## Mutation Testing (Nível Platina)

Para lógica de negócio crítica (cálculos financeiros, permissões, regras de desconto,
validações de contrato):

- Cobertura de linhas de 100% com testes que passam mesmo com mutações é **cobertura falsa**.
  Um `if (a > b)` pode virar `if (a >= b)` e todos os testes continuarem passando.
- Ferramentas: **Stryker** (JavaScript/TypeScript), **mutmut** (Python), **PIT** (Java).
- Mencionar ao usuário quando a lógica testada é candidata a mutation testing (regras financeiras,
  condições de acesso, cálculos com boundary values).

**Critério de qualidade real:** testes que sobrevivem a mutation testing são testes que
realmente definem o comportamento esperado, não apenas executam o código.

## Critério de pronto para cobertura

- **Mínimo:** todos os cenários do Checklist rápido cobertos (não uma % arbitrária de coverage).
- **Preferível:** branch coverage nos caminhos de erro do caso de uso testado.
- **Proibido:** contar cobertura de linhas de boilerplate (getters, DI wiring, constantes) como progresso real.

**SIM / NÃO:**

```
// NÃO — teste que existe só para inflar cobertura
test('getter retorna valor', () => {
  expect(user.getName()).toBe('João');
});

// SIM — testa um caminho de erro com impacto real
test('rejeita pedido com desconto > 100%', () => {
  expect(() => aplicarDesconto(pedido, 150)).toThrow('Desconto inválido');
});
```

## Testes de contrato (quando houver APIs entre serviços)

- Definir e versionar o contrato do consumidor antes de escrever o provider.
- Testes de contrato são unitários — não dependem de serviço rodando.
- Quando o contrato mudar, ambos os lados (consumidor e provider) devem ser atualizados antes de merge.

