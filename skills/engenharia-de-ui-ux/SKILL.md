---
name: engenharia-de-ui-ux
description: >-
  Designs and implements production-grade UI/UX for web components (modals,
  cards, forms, screens, dashboards): enforces the 8px spacing grid, WCAG 2.2
  AA accessibility (color contrast, semantic HTML before ARIA, keyboard
  navigation, target size), the five-state defensive UX model (loading,
  empty, error, partial, ideal), and mobile-first responsiveness. Use this
  whenever creating or modifying any visual UI component or layout - apply
  automatically even when the request does not explicitly mention
  accessibility, spacing, or loading states, since these are non-negotiable
  production defaults, not optional extras. For purely aesthetic direction
  (color palette mood, typographic personality, visual style) with no
  concrete component to build, prefer a visual-design skill instead; the two
  combine well when both a look-and-feel decision and a working component
  are needed.
---

# Engenharia de UI/UX

## Quando aplicar
Ao criar, refatorar ou atualizar elementos de interface gráfica no frontend (componentes, modais, cards, formulários, páginas, layouts, dashboards) ou integrar dados na camada visual. **Aplicar mesmo que o pedido não mencione explicitamente acessibilidade, espaçamento ou estados de carregamento** — são padrões não-negociáveis de produção, não extras opcionais.

**Não aplicar** para decisões puramente estéticas/de direção visual sem um componente concreto a construir (ex.: "sugira uma paleta de cores mais moderna", "qual personalidade tipográfica combina com essa marca"). Nesses casos, prefira uma skill de direção visual (ex.: `frontend-design`). As duas se combinam bem quando a tarefa envolve tanto direção visual quanto um componente funcional: a skill de design define a direção estética, esta skill garante grid, estados defensivos e acessibilidade dentro dela.

Para a transição/animação de entrada e saída de um componente (easing, duração, `prefers-reduced-motion`), delegar à skill `engenharia-de-animacoes` quando disponível — esta skill define o estado visual final de cada interação (hover/active/disabled/loading), não a transição entre estados.

## Quando faltar contexto
- **Sem sistema de Design Tokens/Tailwind configurado no projeto:** inspecionar arquivos de estilo existentes para inferir paleta e escala de espaçamento já em uso antes de inventar valores novos. Se nada existir, propor um conjunto mínimo de tokens CSS (`--space-*`, `--color-*`) e sinalizar essa decisão ao usuário em vez de assumir silenciosamente que o projeto usa Tailwind.
- **Biblioteca de componentes de terceiros** (Material UI, Ant Design, etc.) com grid ou tokens próprios: priorizar consistência com a biblioteca já em uso e documentar o desvio do grid de 8px, em vez de forçar overrides frágeis.
- **"Partial State" indefinido:** quando parte dos dados carrega com sucesso e parte falha (ex.: lista paginada onde a página 2 falhou), exibir os dados já obtidos normalmente e um indicador de erro localizado apenas na porção que falhou — não invalidar o que já carregou nem tratar como Error State completo.

## Fluxo

1. **Fundação e Grid (8px)**: aplicar espaçamentos, margens e dimensionamentos usando estritamente o sistema de Grid de 8px (ex: 8, 16, 24, 32). Utilizar exclusivamente Design Tokens no lugar de valores arbitrários (`px` soltos) — preferir tokens **semânticos** (`--color-bg-primary`, `--space-card-padding`) a tokens **primitivos** brutos (`--blue-500`, `--space-4`) na camada de componente, para suportar temas (dark mode, marca) sem reescrever CSS.

2. **Arquitetura dos 5 Estados (UX Defensiva)**: mapear e implementar explicitamente todos os cenários da interface: *Ideal State* (dados carregados), *Loading State* (Skeletons/Shimmers com dimensões explícitas), *Empty State* (sem dados), *Error State* (falhas com opção de *Retry*) e *Partial State* (dados parcialmente carregados — ver "Quando faltar contexto").

3. **Acessibilidade Ouro (A11y/WCAG 2.2 AA)**:
   - **Contraste**: mínimo 4.5:1 para texto normal e 3:1 para texto grande (≥24px, ou ≥18.66px em negrito) e para componentes de UI não-textuais como ícones e bordas de input (SC 1.4.3 / 1.4.11). Ao escolher uma cor de um token, validar o par contra o fundo real de uso — não assumir que um token de marca funciona em qualquer fundo. Para verificação exata, executar `scripts/contrast-check.py <cor-texto> <cor-fundo>` em vez de estimar visualmente.
   - **HTML semântico antes de ARIA**: priorizar elementos nativos (`<button>`, `<nav>`, `<label>`, `<input>`, `<dialog>`) em vez de recriar comportamento com `<div>`/`<span>` + `aria-*`. Só adicionar `role`/`aria-*` quando não existir elemento nativo equivalente (ex.: `aria-live` para regiões dinâmicas, `aria-expanded` em disclosure customizado).
   - **Teclado e navegação**: ordem de foco lógica seguindo a ordem visual/de leitura, `:focus-visible` com contraste suficiente, hierarquia de headings sem saltos (h1→h2→h3), skip link em páginas com navegação repetitiva.
   - **Alvos de toque**: mínimo 24×24 CSS px com 24px de espaçamento entre alvos adjacentes é o piso obrigatório de nível AA (SC 2.5.8); usar 44×44px como meta para ações primárias em mobile (padrão AAA / Apple HIG), não como "o" mínimo.
   - Ver `references/wcag-criteria.md` para a lista completa de critérios (formulários, zoom/reflow, animação por interação) e exemplos por critério.

4. **Hierarquia e Micro-interações**: aplicar feedbacks visuais imediatos para todas as ações do usuário (estados de `:hover`, `:active`, `:disabled`, `aria-busy` durante carregamento assíncrono). Limitar a hierarquia tipográfica a no máximo 3 tamanhos/pesos por tela ou componente isolado (ex.: um Card usa no máximo título + corpo + legenda), usando uma escala modular consistente com o design system do projeto (ex.: 12/14/16/20/24/32px) em vez de valores tipográficos ad-hoc. Ao criar um novo elemento visual, avaliar se ele deveria ser um componente reutilizável (átomo/molécula, ex.: Button, Badge) ou uma composição de componentes já existentes (organismo, ex.: Card = Image + Title + Badge + Button) — preferir compor a partir de primitivas já existentes a duplicar markup/estilo.

5. **Responsividade, i18n e Mobile-First**:
   - Implementar sempre mobile-first: estilos base para o menor breakpoint, sobreposições (`@media min-width`) para telas maiores.
   - Breakpoints de referência (adaptar ao design system do projeto): `sm=640px`, `md=768px`, `lg=1024px`, `xl=1280px`.
   - Nunca usar valores de largura fixos em componentes que precisem funcionar em múltiplos contextos — usar `max-width` + `width: 100%`.
   - Testar mentalmente em **375px (iPhone SE)** antes de considerar pronto qualquer componente visual.
   - Reservar espaço para expansão de texto em traduções (alemão pode exceder 30-50% o comprimento do inglês) — evitar containers de altura fixa para texto traduzível. Preferir propriedades lógicas de CSS (`margin-inline-start`, `padding-inline-end`) a `margin-left`/`padding-right` quando o produto suportar RTL.

6. **Padrões de Formulário** (quando aplicável): todo `<input>` possui `<label>` associado (via `for`/`id` ou envolvendo o campo) — nunca apenas placeholder como rótulo. Erros de validação aparecem próximos ao campo, em texto (não apenas cor), anunciados via `aria-live` ou `aria-describedby`. Usar `autocomplete`/`inputmode`/`type` corretos (email, tel, etc.).

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

Se o projeto não usar Tailwind, aplicar os mesmos tokens via CSS custom properties (`var(--space-4)`, `var(--color-brand-primary)`) mantendo os mesmos estados (`hover`, `active`, `disabled`, `focus-visible`, `aria-busy`).

## Checklist rápido
- [ ] Cores, margens e tipografia utilizam Design Tokens semânticos (nada de valores hardcoded)?
- [ ] O componente trata cenários de *Loading* (Skeleton), *Error* (falhas de rede), *Empty* e *Partial* de forma fluida?
- [ ] Texto e componentes de UI atingem a razão de contraste mínima (4.5:1 texto normal / 3:1 texto grande e UI não-textual)? Rodou `scripts/contrast-check.py`?
- [ ] Elementos interativos usam HTML nativo semântico antes de ARIA, possuem área de clique ≥24×24px, suporte a teclado (Tab, ordem lógica) e não removem o outline de foco sem um substituto visual?
- [ ] Ações destrutivas oferecem undo (preferencial) ou confirmação, e ações assíncronas fornecem feedback imediato (`aria-busy`, spinner, botão desabilitado)?
- [ ] O componente funciona em viewport 375px sem scroll horizontal ou conteúdo cortado, e sem `user-scalable=no`?
- [ ] Skeletons têm dimensões explícitas (width + height) para reservar espaço e evitar Layout Shift?
- [ ] Botões de ações opostas (aceitar/recusar, confirmar/cancelar) têm peso visual equivalente — nenhum dark pattern de proeminência artificial?

## O que evitar
- Criar telas baseadas apenas no "caminho feliz" (dados renderizados perfeitamente no instante zero, sem prever latência, exceções ou dados parciais).
- Utilizar cores em hexadecimal bruto e valores fixos no CSS, quebrando o padrão visual do projeto e dificultando uso de Dark Mode.
- Utilizar "Spinners" de carregamento globais que empurram o conteúdo da tela (Layout Shift) em vez de reservar o espaço com Skeletons estruturais.
- Ignorar o mapeamento de áreas sensíveis ao toque para mobile, deixando alvos menores que 24×24px.
- Recriar comportamento nativo (botão, link, campo) com `<div>`/`<span>` + `onClick` quando um elemento HTML semântico resolveria com acessibilidade de graça.
- Definir `user-scalable=no`/`maximum-scale=1` na meta viewport, ou usar `px` fixo para tamanho de fonte em vez de `rem`/`em` — ambos impedem usuários com baixa visão de ampliar o texto.
- Criar padrões de interface manipulativos (dark patterns): botão de recusa/cancelamento visualmente menos proeminente que o de aceite, contagens regressivas falsas, opt-out disfarçado de opt-in, texto de confirm-shaming, ou fricção deliberada para dificultar cancelamento/exclusão de conta.

## Referências
- `references/wcag-criteria.md` — critérios WCAG 2.2 relevantes a componentes de UI, com exemplos por critério (contraste, target size, foco, formulários, zoom/reflow, animação por interação).
- `scripts/contrast-check.py` — calculadora determinística de razão de contraste (WCAG 2.2), usar em vez de estimar visualmente.