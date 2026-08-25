# Critérios WCAG 2.2 relevantes a componentes de UI

Referência de apoio para a skill `engenharia-de-ui-ux`. Consultar apenas quando precisar do texto exato de um critério, de um exemplo aplicado, ou para resolver uma dúvida de conformidade — o corpo principal do SKILL.md já resume o essencial para o dia a dia.

## Índice
1. [Contraste de cor (1.4.3 / 1.4.6 / 1.4.11)](#1-contraste-de-cor)
2. [Tamanho de alvo de toque (2.5.8 / 2.5.5)](#2-tamanho-de-alvo-de-toque)
3. [Foco e navegação por teclado (2.4.3 / 2.4.1 / 2.4.7)](#3-foco-e-navegação-por-teclado)
4. [Formulários (1.3.1 / 3.3.1 / 3.3.2)](#4-formulários)
5. [Zoom e reflow (1.4.4 / 1.4.10)](#5-zoom-e-reflow)
6. [Animação por interação (2.3.3)](#6-animação-por-interação)
7. [A Primeira Regra do ARIA](#7-a-primeira-regra-do-aria)

---

## 1. Contraste de cor

| Critério | Nível | Requisito |
|---|---|---|
| 1.4.3 Contrast (Minimum) | AA | Texto normal: ≥4.5:1. Texto grande (≥24px, ou ≥18.66px/14pt em negrito): ≥3:1 |
| 1.4.6 Contrast (Enhanced) | AAA | Texto normal: ≥7:1. Texto grande: ≥4.5:1 |
| 1.4.11 Non-text Contrast | AA | Componentes de UI (bordas de input, ícones significativos, indicadores de estado) e elementos gráficos essenciais à compreensão: ≥3:1 contra a cor adjacente. Não tem equivalente AAA definido. |

**Exemplo:** um texto de legenda cinza-claro (`#9CA3AF`) sobre fundo branco (`#FFFFFF`) dá ~2.5:1 — falha até o mínimo AA para texto normal. O mesmo cinza como cor de um ícone de 24px sobre fundo branco também falharia 1.4.11 (precisa de 3:1).

**Como verificar:** `python scripts/contrast-check.py "#9CA3AF" "#FFFFFF"` retorna a razão exata e se passa em AA/AAA para texto normal, texto grande ou componente de UI (`--large` / `--ui`).

---

## 2. Tamanho de alvo de toque

| Critério | Nível | Requisito |
|---|---|---|
| 2.5.8 Target Size (Minimum) | AA | Alvos de ponteiro ≥24×24 CSS px, **exceto** quando: há ≥24px de espaçamento até o alvo adjacente; existe um alvo equivalente maior na mesma página; o alvo está embutido em uma sentença/bloco de texto; o tamanho é controlado pelo user agent; ou o tamanho específico é essencial à informação transmitida. |
| 2.5.5 Target Size (Enhanced) | AAA | Alvos de ponteiro ≥44×44 CSS px, sem as exceções de espaçamento do 2.5.8. |

**Erro comum a evitar:** tratar 44×44px como "o" mínimo de acessibilidade. É o piso **recomendado** (AAA) e também a convenção de Apple HIG (44pt) e Material Design (48dp) — mas o piso **obrigatório** de conformidade AA é 24×24px. Um ícone de 16×16px com padding suficiente para uma área de clique de 24×24px passa em AA.

---

## 3. Foco e navegação por teclado

- **2.4.3 Focus Order (AA):** a ordem de tabulação deve seguir uma sequência que preserve significado e operabilidade — normalmente a ordem visual/de leitura (esquerda→direita, cima→baixo em contextos LTR).
- **2.4.1 Bypass Blocks (A):** deve existir um mecanismo para pular blocos de conteúdo repetidos (navegação, cabeçalho) — tipicamente um "skip link" (`<a href="#main-content">Pular para o conteúdo</a>`) visível ao receber foco.
- **2.4.7 Focus Visible (AA):** qualquer componente operável por teclado deve ter um indicador de foco visível. Remover o outline padrão (`outline: none`) sem um substituto com contraste suficiente é uma violação direta.

---

## 4. Formulários

- **1.3.1 Info and Relationships (A):** rótulos devem estar programaticamente associados aos campos (`<label for="email">` + `<input id="email">`, ou `<label>` envolvendo o input). Placeholder não substitui label — desaparece ao digitar e não é lido de forma confiável por todos os leitores de tela.
- **3.3.1 Error Identification (A):** erros devem ser identificados em texto, não apenas por cor (ex.: borda vermelha sozinha não basta — adicionar ícone + mensagem textual).
- **3.3.2 Labels or Instructions (A):** campos que exigem um formato específico (ex.: senha com requisitos) devem comunicar esse formato antes ou durante a entrada, não só após o erro.

---

## 5. Zoom e reflow

- **1.4.4 Resize Text (AA):** texto deve poder ser ampliado até 200% sem perda de conteúdo ou funcionalidade — usar `rem`/`em` para tamanho de fonte, nunca `px` fixo.
- **1.4.10 Reflow (AA):** conteúdo deve se reorganizar em uma única coluna sem scroll horizontal quando a largura efetiva chega a 320 CSS px (equivalente a 400% de zoom em uma tela de 1280px).
- Nunca definir `user-scalable=no` ou `maximum-scale=1` na meta viewport — isso desabilita zoom do usuário e viola 1.4.4 diretamente.

---

## 6. Animação por interação

- **2.3.3 Animation from Interactions (AAA, mas boa prática geral):** animações disparadas por interação (não essenciais à funcionalidade) devem poder ser desabilitadas — respeitar `prefers-reduced-motion: reduce` reduzindo ou removendo parallax, auto-play e transições grandes.
- Detalhes de implementação de motion tokens, easing e duração ficam a cargo da skill `engenharia-de-animacoes` quando disponível; esta skill apenas garante que o requisito de acessibilidade de movimento não seja esquecido.

---

## 7. A Primeira Regra do ARIA

Fonte: WAI-ARIA Authoring Practices Guide (APG).

> Se um elemento HTML nativo ou atributo já tem a semântica e o comportamento necessários, use-o em vez de recriá-lo com ARIA em um elemento genérico.

Na prática: `<button>` em vez de `<div role="button" tabindex="0" onKeyDown={...}>`. O elemento nativo já vem com foco por teclado, ativação por Enter/Espaço, e semântica de leitor de tela — recriar isso manualmente é uma fonte comum de bugs de acessibilidade (ex.: esquecer o handler de tecla Espaço, ou o `tabindex`).

ARIA continua sendo necessário para: regiões dinâmicas (`aria-live`), estados sem equivalente nativo (`aria-expanded`, `aria-selected` em componentes customizados como tabs/accordions), e relações entre elementos (`aria-describedby`, `aria-labelledby`).