# Queries de Ativação — engenharia-de-ui-ux

Casos de teste para validar que a skill ativa nos prompts corretos e não ativa nos incorretos.
Medir taxa de acerto esperada: ≥14/15 corretos para considerar a seleção calibrada.

## Devem ativar a skill (8 casos)

| # | Prompt de exemplo | Motivo esperado de ativação |
|---|---|---|
| 1 | "Crie um card de produto com imagem, título, preço e botão de compra" | Componente visual concreto |
| 2 | "Implemente um modal de confirmação de exclusão" | Componente visual + ação destrutiva |
| 3 | "Adicione estados de loading e erro ao componente de lista de usuários" | Estados defensivos explícitos |
| 4 | "Refatore este formulário de cadastro para ser acessível" | Componente visual + acessibilidade |
| 5 | "Crie um dashboard com métricas de vendas" | Layout/tela completa |
| 6 | "Faça este botão funcionar em mobile" | Componente visual + responsividade |
| 7 | "Adicione um skeleton de loading para a tabela de pedidos" | Estado defensivo de loading |
| 8 | "Implemente um dropdown de seleção de país" | Componente de formulário (widget composto) |

## Não devem ativar a skill (7 casos)

| # | Prompt de exemplo | Motivo de não-ativação |
|---|---|---|
| 1 | "Qual paleta de cores combina com uma marca de saúde mental?" | Direção estética pura, sem componente concreto |
| 2 | "Qual tipografia transmite seriedade para um banco?" | Direção tipográfica pura |
| 3 | "Explique a diferença entre padding e margin" | Conceitual, não geração de componente |
| 4 | "Gere um endpoint REST para criar usuários" | Backend — fora do domínio |
| 5 | "Escreva um teste unitário para o componente Button" | Engenharia de testes, não UI/UX |
| 6 | "Adicione uma animação de entrada ao modal" | Delegar à skill `engenharia-de-animacoes` |
| 7 | "Qual mood board combina com o rebranding da empresa?" | Direção visual estratégica pura |

## Casos de borda (ativação condicional — requerem julgamento)

| # | Prompt | Comportamento esperado |
|---|---|---|
| B1 | "Redesenhe esta tela para parecer mais moderna" | **Ativar** — há um componente/tela concreto a modificar, mesmo que o pedido seja estético |
| B2 | "Quais componentes devo usar para o onboarding?" | **Não ativar** — decisão de produto/arquitetura de informação, sem implementação |
| B3 | "Corrija o CSS deste botão — ele está com padding errado" | **Ativar** — modificação de componente visual existente |

## Como usar este arquivo

Para validar antes de atualizar a description ou as instruções de ativação da skill:

1. Para cada query das tabelas acima, verificar se o sistema de roteamento seleciona esta skill.
2. Contabilizar acertos (skill ativada corretamente nas 8 + não ativada corretamente nas 7).
3. Taxa mínima aceitável para deploy: 14/15.
4. Em caso de falha, ajustar a description (Camada 1) antes de ajustar o corpo do SKILL.md.
