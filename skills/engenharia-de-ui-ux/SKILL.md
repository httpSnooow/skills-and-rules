---
name: engenharia-de-ui-ux
tools:
  - shell
suggests:
  - engenharia-de-animacoes
  - frontend-design
description: >-
  Designs and implements production-grade UI/UX for web components (modals,
  cards, forms, screens, dashboards): 8px grid, WCAG 2.2 AA, five-state
  defensive UX (loading/empty/error/partial/ideal), and mobile-first. Activates
  automatically whenever creating or updating any visual component, even when
  accessibility or loading states are not explicitly requested — they are
  non-negotiable production defaults. Does not activate for purely aesthetic
  decisions (color palette, typography mood) without a concrete component to
  build; combines with a visual-design skill when both are needed.
---

# Engenharia de UI/UX

## Quando aplicar
Ao criar, refatorar ou atualizar elementos de interface gráfica no frontend (componentes, modais, cards, formulários, páginas, layouts, dashboards) ou integrar dados na camada visual. **Aplicar mesmo que o pedido não mencione explicitamente acessibilidade, espaçamento ou estados de carregamento** — são padrões não-negociáveis de produção, não extras opcionais.

**Não aplicar** para decisões puramente estéticas/de direção visual sem um componente concreto a construir (ex.: "sugira uma paleta de cores mais moderna", "qual personalidade tipográfica combina com essa marca"). Nesses casos, prefira uma skill de direção visual (ex.: `frontend-design`). As duas se combinam bem quando a tarefa envolve tanto direção visual quanto um componente funcional. **Protocolo de co-ativação:** a skill `frontend-design` define paleta, tipografia e direção estética primeiro; esta skill recebe o resultado como contexto e aplica grid, estados defensivos e acessibilidade dentro dos tokens resultantes. Se os tokens definidos pela skill de design conflitarem com tokens existentes no projeto, sinalizar o conflito antes de gerar código (ex.: "a skill de design propôs `--color-primary: #3B82F6` mas o projeto já declara `--color-brand: #1D4ED8` para o mesmo papel — confirmar qual usar antes de prosseguir").

Para a transição/animação de entrada e saída de um componente (easing, duração, `prefers-reduced-motion`), delegar à skill `engenharia-de-animacoes` quando disponível — esta skill define o estado visual final de cada interação (hover/active/disabled/loading), não a transição entre estados.

## Fluxo

**Passo 0 — Inferência de contexto do projeto (antes de qualquer código):**

Antes de iniciar a implementação, verificar:
- **Sem Design Tokens/Tailwind no projeto:** inspecionar arquivos de estilo para inferir paleta e escala de espaçamento já em uso. Buscar por `--color-`, `--space-`, `--font-` nos arquivos de estilo — nunca criar `--color-primary` se o projeto já usa `--color-brand` para o mesmo papel. Se nada existir, propor um conjunto mínimo de tokens com bloco destacado no topo do CSS gerado (`/* TOKENS PROPOSTOS — revisar e consolidar com o design system do projeto */`) e mencionar no final da resposta quais tokens foram criados e quais valores precisam de confirmação.
- **Biblioteca de componentes de terceiros** (Material UI, Ant Design, etc.) com grid ou tokens próprios: priorizar consistência com a biblioteca já em uso e documentar o desvio do grid de 8px, em vez de forçar overrides frágeis.
- **"Partial State" indefinido:** exibir os dados já obtidos normalmente e um indicador de erro localizado apenas na porção que falhou — não invalidar o que já carregou nem tratar como Error State completo.
- **Formulários com dados sensíveis (senha, cartão de crédito, dados de saúde):** nunca usar `autocomplete="off"` em campos de senha. Usar `autocomplete="current-password"` para login e `autocomplete="new-password"` para cadastro/troca. Não incluir valores de campos sensíveis em mensagens de erro — logar apenas metadados, nunca o valor.
- **Virtualização de listas/tabelas longas** (react-window, TanStack Virtual, etc.): virtualização quebra a semântica de lista para leitores de tela. Adicionar `aria-rowcount={totalItems}` no container e `aria-rowindex={itemIndex + 1}` (1-based) em cada item renderizado. Para grids virtualizados, consultar https://www.w3.org/WAI/ARIA/apg/patterns/grid/. Se a virtualização for adicionada a um componente existente que a skill gerou sem ela, sinalizar que os atributos de ARIA precisam ser revisados.

**Passo 1 — Mapeamento de estados necessários:**

Identificar explicitamente quais dos 5 estados o componente exige:
- Componente com dados síncronos (props fixas, sem fetch) → apenas *Ideal State*.
- Componente com operação assíncrona (fetch, submit) → *Loading + Error + Ideal* no mínimo; verificar se *Empty* e *Partial* se aplicam.
- Listar os estados em uma linha antes do código (ex.: "Estados: Loading, Empty, Error, Ideal"). Só iniciar a implementação após esse mapeamento.

1. **Fundação e Grid (8px)**: aplicar espaçamentos, margens e dimensionamentos usando estritamente o sistema de Grid de 8px (ex: 8, 16, 24, 32). Utilizar exclusivamente Design Tokens no lugar de valores arbitrários (`px` soltos) — preferir tokens **semânticos** (`--color-bg-primary`, `--space-card-padding`) a tokens **primitivos** brutos (`--blue-500`, `--space-4`) na camada de componente, para suportar temas (dark mode, marca) sem reescrever CSS.

2. **Arquitetura dos 5 Estados (UX Defensiva)**: mapear e implementar explicitamente todos os cenários da interface: *Ideal State* (dados carregados), *Loading State* (Skeletons/Shimmers com dimensões explícitas), *Empty State* (sem dados), *Error State* (falhas com opção de *Retry*) e *Partial State* (dados parcialmente carregados — ver Passo 0).

3. **Acessibilidade Ouro (A11y/WCAG 2.2 AA)**:
   - **Contraste**: mínimo 4.5:1 para texto normal e 3:1 para texto grande (≥24px, ou ≥18.66px em negrito) e para componentes de UI não-textuais como ícones e bordas de input (SC 1.4.3 / 1.4.11). Ao escolher uma cor de um token, validar o par contra o fundo real de uso — não assumir que um token de marca funciona em qualquer fundo. Para verificação exata, executar `scripts/contrast-check.py <cor-texto> <cor-fundo>` em vez de estimar visualmente.
   - **HTML semântico antes de ARIA**: priorizar elementos nativos (`<button>`, `<nav>`, `<label>`, `<input>`, `<dialog>`) em vez de recriar comportamento com `<div>`/`<span>` + `aria-*`. Só adicionar `role`/`aria-*` quando não existir elemento nativo equivalente (ex.: `aria-live` para regiões dinâmicas, `aria-expanded` em disclosure customizado).
   - **Label in Name (SC 2.5.3 AA):** em componentes com `aria-label` ou `aria-labelledby`, o label acessível deve conter o texto visível do elemento — nunca substituí-lo. Um botão icon-only sem texto visível deve ter `aria-label` descritivo da ação, não do ícone (`aria-label="Excluir item"`, não `aria-label="ícone de lixeira"`). Em botões com ícone + texto visível, o `aria-label` deve conter esse texto visível.
   - **Conteúdo em hover/foco (SC 1.4.13 AA):** tooltips e popovers que aparecem ao passar o mouse ou focar devem ser: (1) **dismissáveis** sem mover o foco (Esc); (2) **hoveráveis** — o ponteiro pode se mover para o conteúdo exibido sem que ele feche; (3) **persistentes** até o usuário dispensar. Erro comum: `mouseleave` no trigger fecha o tooltip antes de o usuário alcançar o texto — usar `mouseleave` no contêiner pai que engloba trigger + tooltip. Ver `references/wcag-criteria.md` seção 8.
   - **Teclado e navegação**: ordem de foco lógica seguindo a ordem visual/de leitura, hierarquia de headings sem saltos (h1→h2→h3), skip link em páginas com navegação repetitiva.
   - **Foco visível — SC 2.4.7 + 2.4.11 (AA):** `:focus-visible` obrigatório; nunca remover `outline` sem substituto. O indicador de foco deve satisfazer dois requisitos do SC 2.4.11 (novo em WCAG 2.2): (1) **área mínima** correspondente ao perímetro do componente × 2px CSS (na prática, `outline: 2px solid` satisfaz isso para a maioria dos componentes retangulares); (2) **contraste mínimo de 3:1** entre os pixels do indicador de foco e os pixels adjacentes sem foco — verificar com `scripts/contrast-check.py <cor-outline> <cor-fundo> --ui`.
   - **Foco não obscurecido — SC 2.4.12 (AA):** o componente focado não pode ser completamente escondido por `position: sticky` ou `position: fixed` (sticky headers, sidebars, cookie banners). Garantir `scroll-margin-top` suficiente nos elementos interativos para que o foco fique visível acima do elemento fixo. Foco parcialmente obscurecido é permitido em AA; ocultação total é proibida.
   - **Widgets compostos (tabs, listbox, combobox, menu, tree):** dentro do widget, `Arrow Keys` navegam entre itens — Tab move o foco para *fora* do widget inteiro. Implementar via **roving `tabindex`** ou **`aria-activedescendant`** — os dois são mutuamente exclusivos:
     - **Roving `tabindex`** (preferencial para a maioria dos widgets): item ativo recebe `tabindex="0"`, demais recebem `tabindex="-1"`. O foco real move entre os itens; leitores de tela anunciam cada item automaticamente. Usar em: listbox, tree, tabs, toolbar, menu.
     - **`aria-activedescendant`** (quando mover o foco real causaria perda de contexto do container): foco permanece no container; item ativo é indicado via `aria-activedescendant="id-do-item"`. Usar em: combobox (campo de input mantém foco enquanto a lista é navegada), grid editável.
     - **Nunca misturar os dois no mesmo widget.** Consultar https://www.w3.org/WAI/ARIA/apg/patterns/ para o padrão de teclado específico de cada widget antes de implementar. Ver `examples/tabs-widget.jsx` para implementação completa de tabs com roving tabindex.
   - **Alvos de toque**: mínimo 24×24 CSS px com 24px de espaçamento entre alvos adjacentes é o piso obrigatório de nível AA (SC 2.5.8); usar 44×44px como meta para ações primárias em mobile (padrão AAA / Apple HIG), não como "o" mínimo.
   - Ver `references/wcag-criteria.md` para a lista completa de critérios (formulários, zoom/reflow, animação por interação) e exemplos por critério.

4. **Hierarquia e Micro-interações**: aplicar feedbacks visuais imediatos para todas as ações do usuário (estados de `:hover`, `:active`, `:disabled`, `aria-busy` durante carregamento assíncrono). Limitar a hierarquia tipográfica a no máximo 3 níveis por **componente isolado** (ex.: um Card usa título + corpo + legenda — não mais que isso por componente); em páginas e telas completas, respeitar a escala do design system do projeto, que pode ter mais níveis e ainda assim ser consistente. Nunca usar valores tipográficos ad-hoc (`font-size: 13px`) fora da escala definida. Ao criar um novo elemento visual, avaliar se ele deveria ser um componente reutilizável (átomo/molécula, ex.: Button, Badge) ou uma composição de componentes já existentes (organismo, ex.: Card = Image + Title + Badge + Button) — preferir compor a partir de primitivas já existentes a duplicar markup/estilo.
   - **Affordances e reconhecimento (Nielsen H6):** elementos interativos devem ser reconhecíveis sem instruções — o usuário não deve precisar lembrar que algo é clicável. Critérios práticos: (1) botões e links têm aparência de botão/link (fundo, borda ou sublinhado — não apenas texto com `cursor: pointer`); (2) cards clicáveis têm indicador visual de hover (`background-color` ou `box-shadow` de hover visível — nunca apenas `cursor: pointer` silencioso); (3) campos de formulário têm borda visível (não apenas placeholder cinza em fundo branco); (4) ícones que representam ações têm `aria-label` descritivo da **ação** (não do ícone) e, quando o contexto permite, rótulo textual adjacente.

5. **Responsividade, i18n e Mobile-First**:
   - Implementar sempre mobile-first: estilos base para o menor breakpoint, sobreposições (`@media min-width`) para telas maiores.
   - Inspecionar o design system do projeto para os breakpoints em uso antes de assumir valores padrão — a convenção do projeto tem precedência sobre qualquer default.
   - Testar mentalmente em **375px (iPhone SE)** antes de considerar pronto qualquer componente visual.
   - Reservar espaço para expansão de texto em traduções (alemão pode exceder 30-50% o comprimento do inglês) — evitar containers de altura fixa para texto traduzível. Preferir propriedades lógicas de CSS (`margin-inline-start`, `padding-inline-end`) a `margin-left`/`padding-right` quando o produto suportar RTL.

6. **Padrões de Formulário** (quando aplicável): todo `<input>` possui `<label>` associado (via `for`/`id` ou envolvendo o campo) — nunca apenas placeholder como rótulo. Erros de validação aparecem próximos ao campo, em texto (não apenas cor), anunciados via `aria-live` ou `aria-describedby`. `autocomplete` é **obrigatório** (SC 1.3.5 AA, não apenas recomendação) para campos que coletam dados pessoais — nome (`name`), email (`email`), telefone (`tel`), endereço (`street-address`, `postal-code`), cartão (`cc-number`). Para senhas: `autocomplete="current-password"` em login, `autocomplete="new-password"` em cadastro/troca — nunca `autocomplete="off"`. Usar `inputmode` e `type` corretos para cada campo (email, tel, number, etc.).

## Exemplo mínimo

```jsx
// ❌ Evitar
<div style={{padding: '10px', color: '#333'}} onClick={submit}>Enviar</div>

// ✅ Aplicar
<button
  className="px-4 py-2 min-h-[44px] text-fg-primary bg-brand-primary rounded-lg
             hover:bg-brand-primary-hover active:scale-[0.98]
             disabled:opacity-50 disabled:pointer-events-none
             focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
  disabled={isLoading}
  onClick={submit}
  aria-busy={isLoading}
>
  {isLoading ? <Spinner aria-hidden="true" /> : 'Enviar'}
</button>
```

Se o projeto não usar Tailwind, aplicar via CSS custom properties — os mesmos estados são obrigatórios:

```jsx
// ✅ Equivalente vanilla CSS
<button
  class="btn-primary"
  disabled={isLoading}
  aria-busy={isLoading}
>
  {isLoading ? <Spinner aria-hidden="true" /> : 'Enviar'}
</button>
```

```css
/* CSS — mesmos estados do exemplo Tailwind acima */
.btn-primary {
  padding: var(--space-2) var(--space-4);
  min-height: 44px;
  color: var(--color-fg-on-brand);
  background: var(--color-brand-primary);
  border-radius: var(--radius-lg);
  border: none;
  cursor: pointer;
}
.btn-primary:hover:not(:disabled)  { background: var(--color-brand-primary-hover); }
.btn-primary:active:not(:disabled) { transform: scale(0.98); }
.btn-primary:disabled               { opacity: 0.5; pointer-events: none; }
.btn-primary:focus-visible {
  outline: 2px solid var(--color-brand-primary);
  outline-offset: 2px;
}
```

## Checklist rápido — executar antes de finalizar qualquer componente

Após implementar o componente (passos 1–6 do Fluxo), verificar cada item abaixo antes de considerar pronto:
- [ ] Cores, margens e tipografia utilizam Design Tokens semânticos (nada de valores hardcoded)?
- [ ] O componente trata cenários de *Loading* (Skeleton), *Error* (falhas de rede), *Empty* e *Partial* de forma fluida?
- [ ] Texto e componentes de UI atingem a razão de contraste mínima (4.5:1 texto normal / 3:1 texto grande e UI não-textual)? Rodou `scripts/contrast-check.py`?
- [ ] Elementos interativos usam HTML nativo semântico antes de ARIA, possuem área de clique ≥24×24px, suporte a teclado (Tab, ordem lógica) e não removem o outline de foco sem um substituto visual?
- [ ] Ações destrutivas oferecem undo (preferencial) ou confirmação, e ações assíncronas fornecem feedback imediato (`aria-busy`, spinner, botão desabilitado)?
- [ ] O componente funciona em viewport 375px sem scroll horizontal ou conteúdo cortado, e sem `user-scalable=no`?
- [ ] Skeletons têm dimensões explícitas (width + height) para reservar espaço e evitar Layout Shift?
- [ ] Botões de ações opostas (aceitar/recusar, confirmar/cancelar) têm peso visual equivalente — nenhum dark pattern de proeminência artificial?

## O que evitar
- Criar telas baseadas apenas no "caminho feliz" (dados carregados instantaneamente, sem latência, exceção ou dados parciais).
- Utilizar cores em hexadecimal bruto e valores fixos no CSS — quebra o padrão visual do projeto e inviabiliza Dark Mode.
- Ignorar áreas de toque menores que 24×24px em mobile.
- Definir `user-scalable=no`/`maximum-scale=1` na meta viewport ou `px` fixo para tamanho de fonte — impedem zoom para usuários com baixa visão (viola SC 1.4.4).
- Criar dark patterns: botão de recusa/cancelamento visualmente menos proeminente que o de aceite, contagens regressivas falsas, opt-out disfarçado de opt-in, confirm-shaming, ou fricção deliberada para dificultar cancelamento/exclusão de conta.
- Renderizar conteúdo gerado por usuário via `dangerouslySetInnerHTML` (React), `innerHTML` (vanilla JS) ou equivalentes sem sanitização explícita — abre vetores de XSS. Quando rich-text de usuário precisar ser renderizado como HTML, usar uma biblioteca de sanitização dedicada (ex.: `DOMPurify`) com allowlist mínima de tags/atributos. Se não houver sanitização no projeto, sinalizar com `// ATENÇÃO: dado renderizado sem sanitização — avaliar uso de DOMPurify ou equivalente` antes de gerar o trecho.

## Referências
- `references/wcag-criteria.md` — critérios WCAG 2.2 relevantes a componentes de UI, com exemplos por critério (contraste, target size, foco, formulários, zoom/reflow, animação por interação, conteúdo em hover/foco).
- `references/activation-evals.md` — casos de teste de ativação da skill (8 positivos, 7 negativos, 3 de borda).
- `examples/` — exemplos de Empty State, Error State, formulário acessível completo e widget composto (`tabs-widget.jsx` — tabs com roving tabindex e ARIA completo).
- `scripts/contrast-check.py` — calculadora determinística de razão de contraste (WCAG 2.2), usar em vez de estimar visualmente.