# Código Operacional — Estrutura e Abstração com Critério

## Tamanho e responsabilidade de funções

- Uma função faz **uma coisa**. Se a descrição da função contém mais de um "e" (ex: "valida o input **e** salva no banco **e** envia o email"), ela faz coisa demais — quebre.
- Referência de tamanho: ~30 linhas de lógica (não contando imports, tipos e linhas em branco). Se não cabe em uma tela sem scroll, provavelmente faz demais.
- Funções maiores são aceitáveis quando a complexidade é inerentemente sequencial (ex: um pipeline de transformação com 10 etapas claras) — desde que cada etapa tenha nome legível.
- Funções menores que 3 linhas são aceitáveis apenas quando: (1) encapsulam uma regra de negócio com nome expressivo, ou (2) são callbacks de uma única expressão. Fragmentar código em dezenas de funções de 1 linha por obsessão com SRP prejudica a legibilidade tanto quanto funções gigantes.

**SIM / NÃO:**

```
// NÃO — faz demais
function processarPedido(pedido) {
  // valida... 15 linhas
  // calcula desconto... 20 linhas
  // salva no banco... 10 linhas
  // envia email... 10 linhas
}

// SIM — cada responsabilidade isolada
function processarPedido(pedido) {
  validarPedido(pedido);
  const total = calcularDesconto(pedido);
  await salvarPedido(pedido, total);
  await notificarCliente(pedido);
}
```

## Quando extrair abstração (Rule of Three)

- **Só extraia** quando o mesmo padrão aparece **3+ vezes** no código, OU quando a testabilidade exige isolamento (ex: separar I/O de lógica pura para testar sem mock pesado).
- **NÃO extraia** em: one-off scripts, protótipos, código com prazo de vida < 1 sprint, ou quando a "abstração" tem 1 único consumidor e não melhora legibilidade.
- Abstrações prematuras são dívida técnica — custam manutenção sem entregar valor.

**SIM / NÃO:**

```
// NÃO — abstração prematura com 1 consumidor
class DescontoStrategyFactory { ... }  // usado em 1 lugar

// SIM — padrão repetido 3+ vezes, vale extrair
function formatarMoeda(valor, locale) { ... }  // usado em 8 componentes
```

## Ordem de construção (Inside-Out)

Ao criar funcionalidade do zero, siga a sequência lógica:
1. **Domínio / Entidade:** Regras de negócio puras, tipos, validações
2. **Contrato / Repositório:** Interfaces de persistência/comunicação antes da implementação
3. **Caso de Uso / Serviço:** Lógica de aplicação orquestrando entidades e repositórios
4. **Interface Externa (Controller / Endpoint):** Exposição via HTTP, eventos ou CLI
5. **Visão / Frontend (quando aplicável):** Componentes e telas consumindo a API

## Explicabilidade

- Antes de gerar código de uma funcionalidade complexa, exiba um **Mapa de Passos** em tópicos mostrando a ordem de implementação.
- Em cada etapa, explique em **uma frase** a motivação (ex: "Começando pela Entidade X para garantir que as regras de desconto fiquem isoladas do banco de dados").

## O que evitar

- "Favoreça SOLID" sem especificar qual princípio e onde — isso é ruído, não orientação.
- Extrair interface/abstração por antecipação ("talvez alguém precise trocar isso no futuro") sem evidência concreta.
- Refatorar código estável e correto só porque não segue um padrão estético preferido.
