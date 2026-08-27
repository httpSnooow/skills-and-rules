# Lidar com Ambiguidade

## Regra principal

**Nunca assuma.** Se um prompt exige adivinhar regra de negócio complexa, falta informação
estrutural, ou tem múltiplas interpretações igualmente válidas: pare e pergunte antes de gerar código.

## Quando parar e perguntar (critérios objetivos)

- O comportamento esperado varia dependendo de uma regra de negócio não declarada
  (ex: "o que acontece se o usuário cancela um pedido já parcialmente enviado?")
- Há dois designs de implementação igualmente razoáveis com trade-offs opostos
  (ex: campo nullable na tabela vs. tabela de relacionamento separada)
- Falta definição de entidade central do domínio que afeta o schema ou contratos de API
- A tarefa envolve regra financeira, de autorização ou de compliance — domínios de alto risco
  onde uma suposição incorreta tem consequência real

## Quando avançar sem perguntar

- A ambiguidade é de implementação (como fazer), não de requisito (o que fazer) — escolha a
  mais simples, documente a decisão, e sinalize no final
- A convenção do projeto já cobre o caso (ver `convencoes-projeto.md`)
- É uma tarefa trivial: fix de typo, renomear variável, adicionar import, ajustar constante

## Formato de entrega quando há ambiguidade parcial

Implemente até onde tem certeza. Para o trecho incerto, use um `TODO` rastreável e entregue o
que tem. Ao final da resposta, adicione a seção:

```
## Pontos a confirmar
1. [Pergunta objetiva e específica — não "como quer fazer?" mas "o desconto se aplica antes ou depois dos impostos?"]
2. [Pergunta objetiva e específica]
```

Para marcar o trecho incerto no código:

```
// TODO(AMBIGUIDADE): comportamento de cancelamento parcial não especificado
// Assumido aqui: pedido com itens enviados não pode ser cancelado — retorna 422
// Alternativa: cancelar apenas os itens ainda não enviados
```

## O que não fazer

- Completar código fazendo suposições silenciosas sobre regras de negócio
- Perguntar sobre detalhes de implementação triviais que a IA pode decidir sozinha
- Bloquear completamente sem entregar nenhum valor parcial quando há partes certas
- Fazer uma lista de 10 perguntas de uma vez — máximo 3 perguntas por iteração, as mais bloqueantes primeiro