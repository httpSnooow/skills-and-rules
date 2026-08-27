# Token Budget — Disciplina de Execução por Sessão

## 1. Pense antes de codar

Antes de qualquer implementação não trivial, exiba um plano de 3-5 bullet points do que vai ser feito e aguarde confirmação. Não inicie código sem alinhamento em tarefas com escopo ambíguo.

**Trivial (pode ir direto):** fix de typo, renomear variável, adicionar import, ajustar valor de constante.
**Não trivial (exige plano):** nova funcionalidade, refatoração, mudança de contrato, correção de bug com causa incerta.

**Formato esperado do plano:**
- Criar entidade `Pedido` com regras de validação de desconto
- Criar `PedidoRepository` com query de busca por usuário
- Criar `PedidoService` orquestrando domínio e repositório
- Criar endpoint `POST /pedidos` com validação de input e tratamento de erro

**Não incluir no plano:** detalhes de implementação, escolha de nomes, imports — isso vem na implementação.

## 2. Solução mais simples primeiro

A solução correta é a mais simples que satisfaz os critérios. Abstrações, generalizações e flexibilidades não pedidas são dívida técnica prematura.

**Regra prática:** se existir uma solução de 10 linhas e uma de 50 linhas para o mesmo problema, a de 10 linhas é a candidata certa — a menos que os 10 linhas ocultem complexidade que vai explodir em manutenção.

**SIM / NÃO:**

```
// NÃO — over-engineering para um problema simples
class DiscountStrategyFactory {
  static create(type) { ... }
}
class PercentageDiscount extends BaseDiscount { ... }
class FixedDiscount extends BaseDiscount { ... }
// usado em 1 lugar, com 2 tipos

// SIM — resolve o problema diretamente
function calcularDesconto(tipo, valor) {
  return tipo === 'percentual' ? valor * 0.9 : valor - 10;
}
```

## 3. Mudanças cirúrgicas

Altere **apenas o que foi pedido**. Se a task é "corrigir o cálculo de desconto na função X", não refatore a função Y adjacente mesmo que ela pareça melhorável.

Mudanças fora do escopo pedido entram em um bloco `## Observações fora do escopo` no final da resposta — nunca no código gerado.

## 4. Critério de pronto antes de começar

Se a tarefa não tem um critério de pronto claro ("como vou saber que está funcionando?"), **pergunte antes de codar**. Uma tarefa sem critério de pronto gera código sem fim.

**Exemplos de critério de pronto:**
- "O endpoint retorna 200 com o payload X quando chamado com Y"
- "O teste `describe('desconto')` passa com os 3 cenários definidos"
- "O componente renderiza sem erro com dados vazios"

## 5. Orçamento de contexto

Se a resposta está ficando muito longa ou a task cresceu além do escopo original, **pare e sinalize**. É melhor entregar incrementos verificáveis do que uma mudança grande e não auditável.

Sinais de que o orçamento estourou:
- A resposta tem mais de 3 arquivos sendo alterados simultaneamente
- Surgiu uma dependência de refatoração que não estava no plano original
- O usuário adicionou requisitos durante a implementação que mudam o escopo
