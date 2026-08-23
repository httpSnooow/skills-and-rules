---
name: animating-interfaces
version: "1.1"
reviewed_at: "2026-08"
browser_apis_note: "APIs com suporte variável: View Transitions API (Baseline 2024), CSS Scroll-driven animations (Baseline 2023), WAAPI (Baseline 2020). Revisar suporte em caniuse.com ao aplicar em projetos com targets de browser legacy ou mobile específico."
description: Projeta e implementa animações de interface seguindo os padrões-ouro de Big Tech (Material Motion, Fluent, WAAPI, View Transitions API, WCAG 2.2). Prioriza performance de compositor (transform/opacity), acessibilidade (prefers-reduced-motion, gerenciamento de foco, limite de flash, pause/stop) e coerência via Motion Tokens. Use esta skill sempre que o usuário mencionar movimento, fluidez, transição ou comportamento visual ao longo do tempo — mesmo que o pedido seja implícito ("esse hover parece pesado", "a tela parece lerda", "deixa mais fluido", "anima isso") ou venha sem terminologia técnica. Aplica-se a: transições de rota/página, entrada/saída de modais/drawers/toasts, micro-interações (hover, tap, drag), loading states animados, scroll-driven animations e orquestração de listas (stagger).
---

# Engenharia de Animações

## Quando aplicar

Ao criar ou refatorar qualquer movimento de interface: transições de página/rota, entrada e saída de modais/drawers/toasts, micro-interações (hover, tap, drag), skeletons/loading states animados, scroll-driven animations, orquestração de listas (stagger) ou qualquer efeito que envolva mudança de estado visual ao longo do tempo.

**Exemplos de gatilho** (aplicar a skill): "anima a entrada desse modal", "deixa esse hover mais suave", "cria um stagger pra essa lista de cards", "a transição de rota tá seca, dá uma polida", "esse elemento parece pesado", "a interface tá lerda", "deixa mais fluido".

**Exemplos de NÃO-gatilho**:
- "monta um gráfico de barras animado" — visualização de dados segue as convenções da própria biblioteca de dataviz do projeto (D3, Recharts, etc.), não os tokens desta skill.
- "ajusta o grid desse card" — estrutura, layout e estados de loading/error/empty de um componente são escopo da skill `engenharia-de-ui-ux`; esta skill entra depois, para definir *como* o componente se move, não sua estrutura (ver item 7).
- "esse botão tá sem graça, adiciona um ícone" — mudança estática sem alteração de estado ao longo do tempo; não adicionar movimento "porque sim".

## Fluxo

1. **Motion Tokens (Fundação)**: Nunca usar durações e curvas de easing "no achismo" (`300ms`, `ease-in-out` genérico espalhado pelo código). Definir um conjunto limitado de tokens semânticos:

   **Duração** por escala de mudança:
   - Micro-interações (hover/press): `100–150ms`
   - Transições de componente (abrir/fechar modal, expandir card): `200–300ms`
   - Transições de tela/rota: `300–450ms`
   - Ações de **saída/fechamento devem ser mais rápidas** que as de **entrada/abertura** — o usuário já decidiu sair, não precisa esperar a mesma cerimônia da entrada.

   **Easing** — usar a família de curvas do Material 3 Motion, nunca `linear` fora de spinners/progress mecânicos:

   | Curva | Valor | Quando usar |
   |---|---|---|
   | **Standard** | `cubic-bezier(0.4, 0, 0.2, 1)` | Movimentos gerais dentro de uma view, sem direção dominante |
   | **Emphasized Decelerate** | `cubic-bezier(0.05, 0.7, 0.1, 1.0)` | **Entrada** de elementos — chegam devagar ao repouso (modais, drawers, elementos que entram na viewport) |
   | **Emphasized Accelerate** | `cubic-bezier(0.3, 0, 0.8, 0.15)` | **Saída** de elementos — partem rápido, sem hesitação (dismiss, fechar, sair da viewport) |

   Entradas usam Emphasized Decelerate (desacelera ao pousar); saídas usam Emphasized Accelerate (parte sem cerimônia). Nos tokens CSS, nomear explicitamente por direção:

   ```css
   :root {
     --motion-duration-component:      300ms;
     --motion-duration-component-exit: 200ms;
     --motion-easing-standard: cubic-bezier(0.4, 0, 0.2, 1);
     --motion-easing-enter:    cubic-bezier(0.05, 0.7, 0.1, 1.0);  /* Emphasized Decelerate */
     --motion-easing-exit:     cubic-bezier(0.3, 0, 0.8, 0.15);    /* Emphasized Accelerate */
   }
   ```

   Centralizar esses valores em Design Tokens (CSS vars, `tailwind.config`, ou objeto de tema), nunca hardcoded por componente.

   - **Se o projeto ainda não tem motion tokens definidos**: não inventar uma escala nova silenciosamente. Propor explicitamente ao usuário a escala acima como ponto de partida, e só então aplicá-la — trate a ausência de tokens como uma decisão de projeto a confirmar, não como algo a resolver sozinho.
   - **Se o projeto já usa um design system com tokens de motion próprios** (ex: `theme.transitions.duration.standard` no MUI, `theme.transition.duration` no Chakra, `--radix-*` no Radix UI), **priorizar esses tokens** em vez de propor uma escala nova. Integrar os princípios desta skill — assimetria entrada/saída, compositor-only, reduced-motion, stagger com teto — dentro dos tokens existentes. Só propor extensão dos tokens do DS quando o caso de uso não for coberto (ex: o DS não tem token de `exit duration` — propor ao usuário a adição de um token semântico complementar, seguindo a nomenclatura do DS).
   - Para ver como tokens, `prefers-reduced-motion`, performance de compositor e gerenciamento de foco (item 6.2) se combinam num componente real de ponta a ponta, consultar `references/exemplo-modal-completo.md`.

   **Exemplo — ruim vs bom:**
   - ❌ `transition: all 300ms ease-in-out;` (propriedade `all`; easing genérico; valor hardcoded)
   - ✅ `transition: transform var(--motion-duration-component) var(--motion-easing-enter), opacity var(--motion-duration-component) var(--motion-easing-enter);`
   - ❌ Modal abre e fecha com a mesma duração de 300ms e o mesmo easing.
   - ✅ Modal abre em 300ms com `--motion-easing-enter` e fecha em 200ms com `--motion-easing-exit`.

2. **Escolha da técnica pelo tipo de movimento**:

   **Heurística de seleção rápida** (aplicar antes de ler a lista completa):

   | Caso de uso | Técnica preferida |
   |---|---|
   | Estado binário simples (hover, toggle, abrir/fechar) | CSS Transitions/Keyframes |
   | Troca de página, rota ou view | View Transitions API + fallback FLIP |
   | Drag, gesto, snap com momentum do usuário | Framer Motion / React Spring com `velocity` |
   | Elemento que muda de posição/tamanho entre estados | FLIP manual ou `<motion.div layout>` |
   | Animação vinculada a progresso de scroll | CSS `animation-timeline` (simples) / GSAP ScrollTrigger (complexo) |
   | Timeline complexa / múltiplos elementos coreografados | GSAP |
   | Ícone animado ou ilustração vetorial do design | Lottie/Rive |

   - **CSS Transitions/Keyframes**: para estados binários simples (hover, focus, toggle) — menor custo de bundle, roda no compositor.
   - **Web Animations API (WAAPI)**: quando precisar de controle imperativo (play/pause/reverse) sem dependência externa. Se o alvo do projeto incluir navegadores sem suporte total a WAAPI, usar CSS Transitions como fallback.

     **Estado pós-animação — bug silencioso frequente**: ao usar `animation.cancel()` ou ao terminar uma animação com `fill: none` (padrão), o elemento retorna ao estado CSS original. Para preservar o estado final:
     ```js
     // Opção 1 — commitStyles(): aplica os valores computados como estilos inline antes de cancelar
     animation.commitStyles(); // captura o estado final como style="..."
     animation.cancel();       // agora seguro — os estilos estão inline

     // Opção 2 — fill: forwards (com consciência de custo)
     // Mantém a animação "viva" na compositor tree — chamar anim.cancel() no unmount
     const anim = el.animate(keyframes, { duration: 300, fill: 'forwards' });
     ```
     Preferir `commitStyles()` + `cancel()` sobre `fill: forwards` em componentes com ciclo de vida (SPAs).

   - **View Transitions API**: para transições de página/rota ou mudanças de estado do DOM em navegadores com suporte (verificar `document.startViewTransition` antes de usar; aplicar FLIP como fallback). Preferir FLIP manual (`references/flip-implementation.md`) quando for necessário suporte amplo a navegadores, ou quando o controle fino sobre múltiplos elementos simultâneos exigir tratamento de casos-limite que a API ainda não cobre bem.
   - **Motion (Framer Motion) / React Spring**: para animações orientadas a **física (spring-based)** — ideal para drag, gestos, elementos que reagem a interrupção. Partir de preset moderado (`stiffness` ~300, `damping` ~30, `mass` 1) e ajustar conforme o elemento. Para que a resposta a interrupção funcione, **inicializar o spring com a `velocity` atual do pointer no momento do soltar**:
     ```js
     // Framer Motion
     animate(ref, { x: snapTarget }, { type: 'spring', stiffness: 300, damping: 30, velocity: currentVelocityPx })
     // React Spring
     api.start({ x: snapTarget, config: { tension: 300, friction: 30, velocity: currentVelocityPx } })
     ```
     `currentVelocityPx` vem do event handler do gesto (ex: `event.velocity[0]` em `onPointerUp`).
   - **GSAP + ScrollTrigger**: para timelines complexas, coreografia de múltiplos elementos e scroll-driven avançado. **Licença**: GSAP é gratuito para uso pessoal e open-source; produtos comerciais (SaaS, apps com receita, trabalho de agência) requerem licença Club GreenSock — verificar em greensock.com/licensing antes de adotar em produto.
   - **CSS Scroll-driven animations** (`animation-timeline: scroll()` / `view()`): para efeitos vinculados ao progresso de scroll em navegadores evergreen (Baseline 2023). Para scrubbing avançado ou triggers complexos, usar GSAP ScrollTrigger.

     Dois critérios específicos de scroll-driven:
     - **Acessibilidade**: `prefers-reduced-motion: reduce` não desativa automaticamente scroll-driven CSS — o fallback global do item 5 zera `animation-duration`, mas o elemento pode ficar no estado inicial (ex: `opacity: 0`) e nunca aparecer. Verificar que o estado final seja aplicado estaticamente:
       ```css
       @media (prefers-reduced-motion: reduce) {
         .scroll-animated { opacity: 1; transform: none; }
       }
       ```
     - **Propósito**: parallax decorativo é o maior ofensor de movimento não solicitado em scroll — aplicar o critério de "propósito antes de estética" (item 6) com rigor extra.
   - **Lottie/Rive**: para animações vetoriais complexas exportadas do design — não recriar à mão em CSS/JS.
   - **Fora dessa lista — dois cenários**:

     1. **O projeto usa biblioteca de animação não listada** (ex: Vue `<Transition>`, Anime.js, Svelte transitions, Motion One): não forçar migração. Aplicar os mesmos princípios — tokens centralizados, compositor-only, `prefers-reduced-motion`, stagger com teto — dentro da API da biblioteca existente.

     2. **O caso de uso não encaixa na tabela acima**: usar critérios por prioridade:
        - Movimento disparado por gesto contínuo do usuário (drag, swipe, pinch)? → Spring com `velocity`
        - Precisa de controle de timeline (play/pause/scrub)? → WAAPI ou GSAP (verificar licença)
        - Puramente declarativo, baseado em estado CSS? → CSS Transitions/Keyframes
        - Múltiplos elementos com relações espaciais complexas? → FLIP ou `<motion.div layout>`
        - Nenhum critério claro: declarar a ambiguidade ao usuário e apresentar as duas opções mais próximas com trade-offs — não adivinhar.

   **2.1 Vocabulário Fluent (produtos com identidade Microsoft/Windows)**: quando o produto segue Fluent Design:
   - **Connected Animation**: elemento (ex: card de lista) que se transforma na tela de detalhe — animar a transformação do próprio elemento entre as duas telas (equivalente ao Container Transform do M3, item 4).
   - **Curvas de easing Fluent**:

     | Nome Fluent | Valor | Equivalente M3 |
     |---|---|---|
     | FastInSlowOut (entrada expressiva) | `cubic-bezier(0.1, 0.9, 0.2, 1)` | Emphasized Decelerate |
     | FastOutSlowIn (saída) | `cubic-bezier(0.9, 0.1, 1, 0.2)` | Emphasized Accelerate |
     | Linear (mecânico) | `linear` | — (spinners, progress bars apenas) |

     Se o projeto usa Fluent UI React v9 (`@fluentui/react-components`) ou WinUI, verificar se o tema já expõe esses tokens — não propor escala nova se o DS os fornece.
   - **Eixo Z em animações Fluent**: simular via `scale(0.95→1.0)` para elemento que "avança", combinado com `translateZ` apenas em contexto 3D explícito (`transform-style: preserve-3d`).

3. **Performance de Compositor (regra de ouro técnica)**: Animar **exclusivamente** `transform` e `opacity`. Qualquer outra propriedade (width, height, top, left, margin, background-color, box-shadow) dispara reflow ou paint — causa direta de queda de framerate e CLS (Core Web Vitals).

   **Exceções documentadas e suas condições**:
   - `clip-path: circle()/inset()` com `will-change: clip-path` → compositor no Chrome/Edge (verificar no DevTools Rendering panel — Layer Borders)
   - `filter: brightness(0.9–1.15)` / `filter: hue-rotate()` → compositor-safe como alternativa a `background-color`; **ignorados em `forced-colors: active`** (ver `references/performance-compositor.md`)
   - `background-color` direto → apenas se a alternativa for significativamente mais complexa, sem loop, com trade-off registrado em comentário

   `will-change: transform, opacity` — aplicar apenas durante a animação, remover imediatamente após. Safari iOS: adicionar `transform: translateZ(0)` como fallback se houver jank mesmo com `will-change`.

   Para mudanças de posição/tamanho: usar **FLIP** (`references/flip-implementation.md`) ou **View Transitions API** com fallback FLIP.

   **Se o usuário pedir animação de propriedade de layout** (ex: "anima a largura da sidebar"): (1) explicar o custo em 1 frase (reflow, CLS); (2) propor e implementar por padrão via FLIP/transform; (3) implementar versão original apenas com reafirmação explícita, ou se houver justificativa técnica real (ex: `overflow: hidden` onde `transform: scale` distorceria o conteúdo).

   → Detalhes completos (clip-path polygon, content-visibility/IntersectionObserver, will-change Safari, layer explosion em stagger, forced-colors): `references/performance-compositor.md`

4. **Orquestração e Coreografia**: Quando múltiplos elementos animam juntos, aplicar **stagger** (delay incremental entre itens, tipicamente `20–60ms` por item) com um **teto de duração total de ~500ms** independentemente do número de itens. Para listas longas, reduzir o delay por item proporcionalmente ou aplicar stagger apenas aos primeiros 8–10 itens visíveis, animando o restante sem delay incremental.

   Definir sempre uma **direção lógica**, nomeando o padrão de transição do Material 3 Motion aplicado:
   - **Shared axis** (X/Y/Z) — navegação entre elementos do mesmo nível hierárquico (abas sequenciais, passos de wizard)
   - **Fade through** — troca de conteúdo sem relação direta (troca de aba sem elemento visual em comum)
   - **Container transform** — elemento que se expande para se tornar a própria tela de detalhe

   **4.1 RTL (right-to-left)**: em locales RTL (árabe, hebraico), inverter a direção espacial de entrada/saída. Usar propriedades lógicas (`inset-inline-start`/`inset-inline-end`) ou verificar o `dir` do documento antes de fixar a direção de um `transform: translateX`.

5. **Acessibilidade e Movimento (obrigatório, com critérios WCAG específicos)**:

   Toda animação não-essencial deve respeitar `prefers-reduced-motion: reduce`, com fallback instantâneo:
   ```css
   @media (prefers-reduced-motion: reduce) {
     *, *::before, *::after {
       animation-duration:        0.01ms !important;
       animation-iteration-count: 1      !important;
       transition-duration:       0.01ms !important;
       scroll-behavior:           auto   !important;
     }
   }
   ```

   Animações que comunicam **estado funcional** (loading, erro, progresso — ver item 6) podem ser mantidas com `prefers-reduced-motion`, mas reduzidas em intensidade:
   ```css
   @media (prefers-reduced-motion: reduce) {
     /* Spinner: trocar rotação por fade pulsante */
     .spinner {
       animation: pulse-fade 1s ease-in-out infinite;
     }
     @keyframes pulse-fade { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }

     /* Shake de erro: mantém feedback, sem deslocamento amplo */
     .input-error {
       animation: shake-subtle 0.3s ease-in-out;
     }
     @keyframes shake-subtle { 0%, 100% { transform: translateX(0); } 50% { transform: translateX(4px); } }
   }
   ```

   **Stagger com `prefers-reduced-motion`**: o delay incremental entre itens continua perceptível mesmo com `transition-duration: 0.01ms`. Zerar também os delays:
   ```css
   @media (prefers-reduced-motion: reduce) {
     .list-item {
       animation-delay:    0ms !important;
       transition-delay:   0ms !important;
     }
   }
   ```
   Quando o stagger é via JS (Framer Motion, GSAP), verificar se a library lê `prefers-reduced-motion` automaticamente ou se o delay precisa ser zerado manualmente.

   **Scroll-driven**: `prefers-reduced-motion` não desativa automaticamente `animation-timeline` — garantir que o estado final seja aplicado estaticamente no bloco de reduced-motion (ver item 2, scroll-driven).

   Qualquer animação em **loop automático** visível por mais de 5 segundos precisa oferecer controle de pausa acessível (WCAG 2.2, SC 2.2.2).

   Nenhuma animação pode piscar/alternar em alto contraste mais de **3 vezes por segundo** (WCAG 2.2, SC 2.3.1 — risco de convulsão fotossensível). **Bloqueante — não implementar mesmo com reafirmação explícita do usuário.**

   **`forced-colors` (Windows High Contrast Mode)**: `filter: brightness()` e `filter: hue-rotate()` são ignorados em `forced-colors: active` — alternativas de cor via filtro perdem o efeito. Verificar que o elemento comunica seu estado via forma, posição ou opacidade, independente de cor. Ver `references/performance-compositor.md` para exemplos e como testar.

   **Contraste durante transições de opacidade (WCAG 1.4.3)**: elementos que fazem fade em `opacity: 0→1` passam por estados onde o contraste do texto pode ser insuficiente. Preferir animar o container (o texto interno permanece estável) em vez de animar a opacidade do próprio elemento de texto. Em fades longos (>300ms) com texto, preferir cross-fade entre dois estados sobrepostos.

   **Conflito entre pedido do usuário e critério bloqueante (flash/convulsão)**: seguir o mesmo padrão do item 3 — explicar o risco, propor alternativa segura e implementar apenas a alternativa. Diferente do item 3, itens bloqueantes de acessibilidade não devem ser implementados mesmo após reafirmação: o risco é ao usuário-final, não uma preferência técnica resolvível com consentimento informado.

   **Dark patterns de movimento (bloqueante — mesmo nível que WCAG SC 2.3.1)**: os padrões abaixo **não devem ser implementados mesmo com reafirmação explícita do usuário**. O risco não é do solicitante, mas do usuário-final que é manipulado:
   - Botão de fechar/cancelar/recusar que se move, encolhe ou demora a responder ao clique para dificultar saída de fluxo ("roach motel")
   - Progress bar com desaceleração artificial antes de 100% sem progresso real por etapa
   - Animação que obscurece ou desvia atenção do usuário-final no momento em que informação de custo, prazo ou consequência é exibida
   - Badge ou dot de notificação em loop (pulse, bounce, glow) sem notificação real aguardando ação do usuário

   Base regulatória: FTC Dark Patterns guidelines (2022) — ilusão de urgência via movimento é prática enganosa; EU Digital Services Act Art. 25 — plataformas não podem usar interfaces que prejudiquem a autonomia de escolha do usuário. Nível de guardrail idêntico ao flash fotossensível: implementar causa dano ao usuário-final.

6. **Propósito antes de estética**: Toda animação precisa responder a: *o que ela comunica?*

   **Funcional** (manter com `prefers-reduced-motion`, em intensidade reduzida): a animação transmite informação de estado que não está disponível de outra forma — spinner de loading, shake em input com erro, container transform (relação espacial lista→detalhe), progress bar com progresso real.

   **Decorativa** (suprimir com `prefers-reduced-motion`): remover a animação não altera a compreensão do estado do sistema — hero section animada, parallax de fundo, card que cresce no hover sem comunicar estado novo.

   **Regra de desempate**: em caso de dúvida, tratar como decorativa.

   **Raciocínio para casos ambíguos — exemplos**:

   - 🟡 Card com `scale(1.03)` no hover → **Decorativo** — o cursor já comunica "clicável"; a escala não acrescenta estado novo. Suprimir com `prefers-reduced-motion`. **Exceção**: se o scale revelar conteúdo filho (botão que aparece dentro do card), torna-se funcional — manter em intensidade reduzida.

   - 🟡 Badge de notificação com pulse em loop → **Dark pattern** se não houver notificação real aguardando ação (bloqueante — item 5). Se houver notificação real: **funcional**, mas com animação de entrada única, não loop.

   - 🟡 Progress bar avançando suavemente → **Funcional** apenas se o progresso reflete o estado real da operação. Velocidade fixa independente do progresso real: **decorativa** e potencial dark pattern (item 5).

   - 🟡 Spinner de loading → **Funcional**. Com `prefers-reduced-motion`, substituir por fade pulsante — mantém o feedback de "carregando", remove o movimento rotativo.

   **6.1 Legibilidade durante o movimento**: evitar animar `scale`/`rotate` em elementos com texto de leitura ativa (parágrafos, labels de formulário). Preferir animar o container e manter o texto interno estável, ou usar `opacity` (cross-fade) para troca de conteúdo textual.

   **6.2 Foco e leitores de tela durante a transição**: ao animar a entrada de um elemento que deve receber foco (modal, drawer, painel expandido), mover o foco programático (`el.focus()`) apenas após o término da animação de entrada — mover antes faz leitores de tela anunciarem conteúdo ainda em transição. Para animações de saída, manter o elemento na árvore de acessibilidade (`aria-hidden="true"` / `inert` aplicados após `transitionend`) — nunca no início da saída. Ver `references/exemplo-modal-completo.md` para a implementação completa.

7. **Fronteira com `engenharia-de-ui-ux`**: Esta skill trata do *movimento*. A skill `engenharia-de-ui-ux` trata da *estrutura* (grid de 8px, os 5 estados, a11y estática, responsividade). Aplicar as duas juntas nesta ordem: estrutura primeiro (`engenharia-de-ui-ux`), movimento depois (esta skill). Em caso de conflito — dimensão de skeleton fixa vs. duração de transição — a estrutura tem precedência; o movimento se adapta a ela.

**Antes de entregar qualquer implementação, percorrer o Checklist abaixo como gate de saída.**

## Checklist rápido

### 🎨 Tokens e Técnica
- [ ] As durações e curvas de easing vêm de Motion Tokens centralizados (ou dos tokens do design system existente)?
- [ ] Foi aplicada a técnica correta para o tipo de movimento (heurística do item 2)?
- [ ] O padrão M3 Motion aplicado (shared axis / fade through / container transform) foi nomeado explicitamente?
- [ ] Entradas usam `--motion-easing-enter` (Emphasized Decelerate) e saídas usam `--motion-easing-exit` (Emphasized Accelerate)?

### ⚡ Performance
- [ ] A animação usa exclusivamente `transform`/`opacity` (ou está explicitamente justificada a exceção com comentário no código)?
- [ ] Transições de saída são mais rápidas que as de entrada?
- [ ] `will-change` é aplicado só durante a animação ativa e removido depois?
- [ ] Mudanças de layout usam FLIP (`references/flip-implementation.md`) ou a View Transitions API (com fallback FLIP)?
- [ ] Se propriedade de layout foi pedida explicitamente, o protocolo de 3 passos foi seguido (explicar → propor FLIP → implementar original só com reafirmação)?
- [ ] Se spring em drag/gesto, a `velocity` atual do pointer foi passada como parâmetro inicial?
- [ ] Se WAAPI com `cancel()`, foi chamado `commitStyles()` antes para preservar o estado final?
- [ ] Animações JS-driven (GSAP, Framer handlers) não bloqueiam o thread durante input — INP verificado no Chrome DevTools Performance → Interactions (alvo: <200ms)?
- [ ] Se GSAP: licença verificada para o contexto do projeto (pessoal/open-source vs. produto comercial)?

### ♿ Acessibilidade
- [ ] A animação foi classificada como **funcional** ou **decorativa** (item 6) antes de definir o comportamento com `prefers-reduced-motion`?
- [ ] O fallback de `prefers-reduced-motion` foi implementado em CSS (não apenas mencionado)?
- [ ] Se scroll-driven (`animation-timeline`), o estado final foi aplicado estaticamente no bloco de reduced-motion?
- [ ] Se stagger foi usado, os `animation-delay`/`transition-delay` foram zerados no bloco de reduced-motion?
- [ ] Loops automáticos têm controle de pausa acessível (WCAG 2.2.2)?
- [ ] Nenhuma animação pisca >3x/segundo (WCAG 2.3.1) — mesmo com reafirmação explícita do usuário?
- [ ] Foco programático movido só após `transitionend` de entrada; `inert` reaplicado só após `transitionend` de saída?
- [ ] Texto de leitura ativa não é distorcido por `scale`/`rotate` durante a transição?
- [ ] Em animações de opacidade com texto: o container anima (não o elemento de texto diretamente)?
- [ ] Em contextos Windows: `filter: brightness()/hue-rotate()` têm fallback de forma/posição para `forced-colors: active`?

### 🧪 Teste
- [ ] Testado no Chrome DevTools Performance (CPU throttling 4x), mantendo **≥55fps** e sem long tasks >50ms?
- [ ] Testado em dispositivo Android de entrada ou via Device Emulation?

### 🎯 Propósito
- [ ] Cada animação tem propósito comunicativo claro (feedback, continuidade, hierarquia) e não é decorativa sem função nem dark pattern?

## O que evitar

| Anti-padrão | Referência |
|---|---|
| Animar `width`/`height`/`top`/`left`/`margin` diretamente | Item 3 — usar FLIP ou View Transitions API |
| Easing `linear` fora de spinner/progress mecânico | Item 1 — usar curvas da família M3 |
| Duração igual para entrada e saída; mesmo easing para entrada e saída | Item 1 — saída deve ser mais rápida (`--motion-easing-exit`) |
| `will-change` permanente ou global | Item 3 + `references/performance-compositor.md` |
| Loop automático sem controle de pausa acessível | Item 5 — WCAG 2.2.2 bloqueante |
| Flash em alto contraste acima de 3x/segundo | Item 5 — WCAG 2.3.1 bloqueante, não implementar mesmo com reafirmação |
| Dark patterns de movimento (roach motel, fake loading, desvio de atenção, badge sem notificação real) | Item 5 — bloqueante, mesmo nível que WCAG 2.3.1 |
| Spring em drag/gesto sem inicializar `velocity` com o momentum atual do pointer | Item 2 — principal razão para usar spring é desperdiçada |
| Ignorar `prefers-reduced-motion` ou zerar só a duração sem também zerar delays de stagger | Item 5 — delay incremental permanece perceptível mesmo com `transition-duration: 0.01ms` |
| WAAPI com `cancel()` sem `commitStyles()` antes | Item 2 — o elemento reseta para o estado CSS original (bug silencioso) |
| `filter: brightness()/hue-rotate()` sem fallback para `forced-colors: active` | Item 5 + `references/performance-compositor.md` |
