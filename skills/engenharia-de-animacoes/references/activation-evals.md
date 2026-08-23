# Eval Queries de Ativação — animating-interfaces

Usar estas queries para calibrar a `description` da skill. Para cada query, verificar se a
skill dispara conforme o veredito esperado (✅ deve ativar / ❌ não deve ativar).

---

## Queries que DEVEM ativar a skill

| # | Query | Tipo de ativação |
|---|---|---|
| 1 | "anima a entrada desse modal" | Explícita / técnica |
| 2 | "deixa esse hover mais suave" | Explícita / técnica |
| 3 | "cria um stagger pra essa lista de cards" | Explícita / técnica |
| 4 | "a transição de rota tá seca, dá uma polida" | Explícita / coloquial |
| 5 | "esse elemento parece pesado quando aparece" | **Implícita** |
| 6 | "a interface tá lerda, parece que trava" | **Implícita** |
| 7 | "deixa mais fluido" | **Implícita** |
| 8 | "tô tentando fazer aquele efeito de card que expande pra tela de detalhe" | Implícita / descritiva |
| 9 | "o botão deveria dar um feedback quando o usuário clica" | Implícita / UX |
| 10 | "esse loading state não tá comunicando nada" | Implícita / UX |
| 11 | "o skeleton loader tá feio" | Implícita (skeleton = loading state animado) |
| 12 | "implementa drag com snap" | Implícita (snap com momentum = spring/physics) |

---

## Queries que NÃO devem ativar a skill

| # | Query | Por quê não ativar |
|---|---|---|
| 1 | "monta um gráfico de barras animado" | Dataviz — convenções da library (D3, Recharts) |
| 2 | "ajusta o grid desse card" | Estrutura/layout — escopo de `engenharia-de-ui-ux` |
| 3 | "esse botão tá sem graça, adiciona um ícone" | Mudança estática sem estado ao longo do tempo |
| 4 | "adiciona acessibilidade ao formulário" | Acessibilidade estática — escopo de `engenharia-de-ui-ux` |
| 5 | "otimiza o bundle size" | Performance de carregamento, não de animação |
| 6 | "o cursor de texto tá piscando muito rápido" | Propriedade de plataforma/sistema, não animação de UI |

---

## Queries limítrofes (calibrar com cuidado)

| # | Query | Decisão sugerida | Razão |
|---|---|---|---|
| 1 | "implementa drag-and-drop" | ✅ Ativar **se** o pedido envolve movimento durante o drag (spring, snap) | Se for apenas a lógica de soltar/reordenar sem foco em movimento, não ativar |
| 2 | "adiciona uma animação de confete quando o usuário completa a tarefa" | ✅ Ativar, mas aplicar critério de propósito (item 6 — funcional ou decorativo excessivo?) | É animação de UI; o modelo deve questionar se comunica estado ou é puramente decorativa |
| 3 | "o formulário deveria shake quando o usuário erra" | ✅ Ativar | Shake de validação é feedback de estado funcional — caso central da skill |
| 4 | "o app tá com umas animações muito exageradas, simplifica" | ✅ Ativar | Refatoração de movimento — aplica os mesmos princípios |

---

## Como usar este arquivo para calibração iterativa

1. Para cada query acima, gerar a resposta da skill **a partir apenas da `description`**
   (sem ler o corpo do SKILL.md) — simular o processo de seleção de skill do agente.
2. Registrar se a skill foi selecionada (✅) ou não (❌) para cada query.
3. Calcular a taxa de acerto nas categorias "deve ativar" e "não deve ativar".
4. Para cada falha: identificar qual trecho da `description` causou sub-ativação ou
   ativação indevida.
5. Ajustar a `description` e re-testar com o conjunto completo (não apenas os casos que
   falharam) para garantir ausência de regressões.
6. **Alvo mínimo antes de considerar a skill pronta**: ≥85% nas queries implícitas
   (queries 5–12 da tabela "deve ativar"); 100% nas queries "não deve ativar".
