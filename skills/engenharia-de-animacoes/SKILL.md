---
name: engenharia-de-animacoes
description: Projeta e implementa animações de interface seguindo os padrões-ouro de Big Tech (Material Motion, Fluent, WAAPI, View Transitions API, WCAG 2.2). Prioriza performance de compositor (transform/opacity), acessibilidade (prefers-reduced-motion, gerenciamento de foco, limite de flash, pause/stop) e coerência via Motion Tokens. Use ao criar transições, micro-interações, entrada/saída de elementos ou orquestração de sequências animadas.
---

# Engenharia de Animações

## Quando aplicar

Ao criar ou refatorar qualquer movimento de interface: transições de página/rota, entrada e saída de modais/drawers/toasts, micro-interações (hover, tap, drag), skeletons/loading states animados, scroll-driven animations, orquestração de listas (stagger) ou qualquer efeito que envolva mudança de estado visual ao longo do tempo.

**Exemplos de gatilho** (aplicar a skill): "anima a entrada desse modal", "deixa esse hover mais suave", "cria um stagger pra essa lista de cards", "a transição de rota tá seca, dá uma polida".

**Exemplos de NÃO-gatilho**:
- "monta um gráfico de barras animado" — visualização de dados segue as convenções da própria biblioteca de dataviz do projeto (D3, Recharts, etc.), não os tokens desta skill.
- "ajusta o grid desse card" — estrutura, layout e estados de loading/error/empty de um componente são escopo da skill `engenharia-de-ui-ux`; esta skill entra depois, para definir *como* o componente se move, não sua estrutura (ver item 7).
- "esse botão tá sem graça, adiciona um ícone" — mudança estática sem alteração de estado ao longo do tempo; não adicionar movimento "porque sim".

## Fluxo

1. **Motion Tokens (Fundação)**: Nunca usar durações e curvas de easing "no achismo" (`300ms`, `ease-in-out` genérico espalhado pelo código). Definir um conjunto limitado de tokens semânticos, no espírito do Material Motion:
   - **Duração** por escala de mudança — micro-interações (hover/press): `100–150ms`; transições de componente (abrir/fechar modal, expandir card): `200–300ms`; transições de tela/rota: `300–450ms`. Ações de **saída/fechamento devem ser mais rápidas** que as de **entrada/abertura** — o usuário já decidiu sair, não precisa esperar a mesma cerimônia da entrada.
   - **Easing** — usar curvas assimétricas (ex.: `cubic-bezier(0.4, 0, 0.2, 1)` "standard", ou `cubic-bezier(0.22, 0.61, 0.36, 1)` para foco/ação), nunca `linear` fora de casos mecânicos (spinners, barras de progresso indeterminadas). O movimento deve **acelerar rápido e desacelerar de forma gradual**.
   - Centralizar esses valores em Design Tokens (CSS vars, `tailwind.config`, ou objeto de tema), nunca hardcoded por componente.
   - **Se o projeto ainda não tem motion tokens definidos**: não inventar uma escala nova silenciosamente. Propor explicitamente ao usuário a escala acima como ponto de partida, e só então aplicá-la — trate a ausência de tokens como uma decisão de projeto a confirmar, não como algo a resolver sozinho.
   - Para ver como tokens, `prefers-reduced-motion`, performance de compositor e gerenciamento de foco (item 6.2) se combinam num componente real de ponta a ponta, consultar `references/exemplo-modal-completo.md` em vez de montar a combinação do zero.

   **Exemplo — ruim vs bom:**
   - ❌ `transition: all 300ms ease-in-out;` (propriedade `all` — anima qualquer coisa que mude, inclusive propriedades de layout; easing genérico; valor hardcoded)
   - ✅ `transition: transform var(--motion-duration-component) var(--motion-easing-standard), opacity var(--motion-duration-component) var(--motion-easing-standard);` (propriedades explícitas, apenas as seguras para o compositor, tokens semânticos)
   - ❌ Modal abre e fecha com a mesma duração de 300ms.
   - ✅ Modal abre em 300ms (`--motion-duration-component`) e fecha em 200ms (`--motion-duration-component-exit`) — saída mais ágil que entrada.

2. **Escolha da técnica pelo tipo de movimento**:
   - **CSS Transitions/Keyframes**: para estados binários simples (hover, focus, toggle) — menor custo de bundle, roda no compositor.
   - **Web Animations API (WAAPI)**: quando precisar de controle imperativo (play/pause/reverse) sem dependência externa. Se o alvo do projeto incluir navegadores sem suporte total a WAAPI, usar CSS Transitions como fallback em vez de assumir suporte.
   - **View Transitions API**: para transições de página/rota ou mudanças de estado do DOM, em navegadores com suporte (verificar `document.startViewTransition` antes de usar; aplicar a técnica FLIP manual como fallback para navegadores sem suporte). É a alternativa nativa moderna à FLIP manual para este caso específico — captura automaticamente snapshots do "antes" e "depois" e anima via `transform`/`opacity` internamente, sem código de medição manual. Preferir FLIP manual (`references/flip-implementation.md`) quando for necessário suporte amplo a navegadores, ou quando o controle fino sobre múltiplos elementos simultâneos exigir tratamento de casos-limite que a API ainda não cobre bem (ex.: elementos entrando/saindo no meio da transição).
   - **Motion (Framer Motion) / React Spring**: para animações orientadas a **física (spring-based)** em vez de duração fixa — ideal para drag, gestos, elementos que reagem a interrupção do usuário. Ao configurar o spring, partir de um preset moderado (`stiffness` ~300, `damping` ~30, `mass` 1 — equivalente ao preset "gentle"/"default" das bibliotecas) e ajustar: aumentar `stiffness` para resposta mais rápida e direta (elementos pequenos, feedback imediato de toque); reduzir `damping` para mais oscilação/bounce perceptível (usar com moderação — overshoot excessivo conflita com a diretriz de propósito funcional do item 6); usar `mass` acima de 1 apenas para simular elementos "pesados" intencionalmente. Diferente de duração fixa, um spring bem configurado responde de forma contínua a interrupções do gesto do usuário (ex.: soltar o drag no meio do movimento), o que é a razão central para escolher spring em vez de easing tradicional.
   - **GSAP + ScrollTrigger**: para timelines complexas, coreografia de múltiplos elementos e animações vinculadas a scroll.
   - **Lottie/Rive**: para animações vetoriais complexas exportadas do design (ilustrações, ícones animados, onboarding) — não recriar isso à mão em CSS/JS.
   - **Fora dessa lista**: se o projeto já usa uma biblioteca de animação diferente (ex: Vue `<Transition>`, Anime.js, Svelte transitions), não forçar migração — aplicar os mesmos princípios (tokens, compositor-only, reduced-motion) dentro da API da biblioteca já existente no projeto.

   **2.1 Vocabulário Fluent (produtos com identidade Microsoft/Windows)**: quando o produto segue Fluent Design, priorizar o conceito de **Connected Animation** — quando um elemento (ex: card de uma lista) se torna a tela de detalhe, animar a transformação do próprio elemento (posição, tamanho, conteúdo) entre as duas telas, em vez de um cross-fade entre telas desconectadas. É o equivalente Fluent ao "container transform" do Material Motion (ver item 4).

3. **Performance de Compositor (regra de ouro técnica)**: Restringir animações **exclusivamente** às propriedades que rodam na *compositor thread*, sem disparar layout ou paint:
   - Permitido: `transform` (translate/scale/rotate) e `opacity`.
   - Evitar: `width`, `height`, `top`, `left`, `margin`, `box-shadow` extenso, `background-color` em loops de alta frequência — todos forçam recálculo de layout/paint e derrubam o framerate, além de serem causa direta de **Cumulative Layout Shift (CLS)**, uma métrica de Core Web Vitals.
   - Usar `will-change: transform, opacity` **apenas** no elemento ativo durante a animação, e remover a propriedade logo depois.
   - Para animar mudanças de layout (elemento que muda de posição/tamanho ao trocar de estado), usar a técnica **FLIP** (First, Last, Invert, Play): medir a posição inicial e final, e animar apenas via `transform` a diferença entre elas. Implementação de referência completa (código pronto para uso, incluindo variação para múltiplos elementos) em `references/flip-implementation.md` — consultar esse arquivo sempre que for implementar FLIP de fato, em vez de reescrever a técnica do zero.
   - **Se o usuário pedir explicitamente para animar uma propriedade de layout** (ex: "anima a largura da sidebar de 200px pra 400px"): não recusar de imediato nem implementar sem contexto. (1) Explicar em 1 frase o custo de performance (reflow, possível CLS); (2) propor e implementar por padrão a alternativa via `transform`/FLIP; (3) só implementar a versão original animando a propriedade de layout diretamente se o usuário reafirmar a escolha após entender o trade-off, ou se houver justificativa técnica real (ex: elemento com `overflow: hidden` onde `transform: scale` distorceria o conteúdo interno).

4. **Orquestração e Coreografia**: Quando múltiplos elementos animam juntos (listas, grids, cards), aplicar **stagger** (delay incremental entre itens, tipicamente `20–60ms` por item) em vez de disparar tudo simultaneamente, respeitando um **teto de duração total de orquestração de ~500ms** independentemente do número de itens. Para listas longas (dezenas de itens), reduzir o delay por item proporcionalmente ou aplicar stagger apenas aos primeiros 8–10 itens visíveis, animando o restante sem delay incremental — o objetivo é dar a sensação de sequência guiada sem fazer o usuário esperar uma cascata perceptível em conteúdo extenso.

   Definir sempre uma **direção lógica**, nomeando explicitamente qual padrão de transição do Material 3 Motion está sendo aplicado, em vez de improvisar: **shared axis** (X/Y/Z — navegação entre elementos do mesmo nível hierárquico, ex.: passos de um wizard ou abas sequenciais), **fade through** (troca de conteúdo sem relação direta entre si, ex.: troca de aba sem elemento visual em comum) ou **container transform** (um elemento que se expande para se tornar a própria tela de detalhe — equivalente ao Connected Animation do item 2.1). Declarar o padrão escolhido facilita revisão e consistência entre implementações do mesmo produto.

   **4.1 RTL (right-to-left)**: em locales RTL (árabe, hebraico), inverter a direção espacial de entrada/saída — um drawer que desliza da direita em LTR deve deslizar da esquerda em RTL. Usar propriedades lógicas (`inset-inline-start`/`inset-inline-end`) ou verificar o `dir` do documento antes de fixar a direção de um `transform: translateX`.

5. **Acessibilidade e Movimento (obrigatório, com critérios WCAG específicos)**:
   - Toda animação não-essencial (decorativa, de entrada, parallax, autoplay) deve respeitar `prefers-reduced-motion: reduce`, com fallback instantâneo. *Nota normativa*: o SC 2.3.3 (Animation from Interactions) do WCAG 2.2 cobre especificamente animação disparada por interação/movimento do dispositivo, não toda animação decorativa em geral — trate `prefers-reduced-motion` aqui como prática geral de acessibilidade alinhada ao princípio 2.3 (Seizures and Physical Reactions), não como cumprimento restrito desse único critério:
     ```css
     @media (prefers-reduced-motion: reduce) {
       *, *::before, *::after {
         animation-duration: 0.01ms !important;
         animation-iteration-count: 1 !important;
         transition-duration: 0.01ms !important;
         scroll-behavior: auto !important;
       }
     }
     ```
   - Animações que comunicam **estado funcional** (loading, erro, progresso) podem ser mantidas mesmo com a preferência ativada, mas reduzidas em intensidade (menor deslocamento, sem bounce/overshoot).
   - Qualquer animação em **loop automático** (carrosséis, banners, loading indefinido visível por mais de 5s) precisa oferecer controle de pausa acessível ao usuário (WCAG 2.2, SC 2.2.2 — Pause, Stop, Hide).
   - Nenhuma animação pode piscar/alternar em alto contraste mais de **3 vezes por segundo** (WCAG 2.2, SC 2.3.1 — risco de convulsão fotossensível). Isso é bloqueante, não uma sugestão de estilo.
   - **Conflito entre pedido do usuário e critério bloqueante**: se o pedido conflitar diretamente com um item marcado como bloqueante acima (flash acima de 3x/segundo, loop automático sem controle de pausa), seguir o mesmo padrão do item 3 para propriedades de layout: explicar em 1 frase o risco (ex.: risco de convulsão fotossensível), propor a alternativa que respeita o critério, e implementar apenas a alternativa segura. Diferente do item 3, itens bloqueantes de acessibilidade não devem ser implementados como pedido pelo usuário mesmo após reafirmação — aqui o risco é de segurança do usuário final, não uma preferência técnica que se resolve com consentimento informado.

6. **Propósito antes de estética**: Toda animação precisa responder a uma pergunta: *o que ela comunica?* (continuidade espacial, hierarquia, feedback de ação, relação causa-efeito). Movimento puramente decorativo, sem função, deve ser cortado ou reduzido.

   **6.1 Legibilidade durante o movimento**: evitar animar `scale`/`rotate` em elementos que contêm texto de leitura ativa (parágrafos, labels de formulário) de forma que a distorção prejudique a leitura durante a transição. Preferir animar o container e manter o texto interno estável, ou usar `opacity` (cross-fade) para troca de conteúdo textual em vez de escala.

   **6.2 Foco e leitores de tela durante a transição**: ao animar a entrada de um elemento que deve receber foco (modal, drawer, painel expandido), mover o foco programático (`el.focus()`) apenas após o término da animação de entrada, não no início — mover o foco antes faz leitores de tela anunciarem conteúdo que ainda está visualmente em transição, e pode capturar o foco num elemento com posição/opacidade intermediária, gerando uma experiência confusa para quem navega por teclado ou tecnologia assistiva. Para animações de saída, manter o elemento fora da árvore de foco (`aria-hidden="true"` + `inert`, ou remoção do DOM) apenas após a transição terminar — nunca no início da animação de saída, para não cortar a interação de quem ainda está lendo o conteúdo enquanto ele desaparece visualmente. Ver `references/exemplo-modal-completo.md` para a implementação completa desse sequenciamento.

7. **Fronteira com `engenharia-de-ui-ux`**: Esta skill trata do *movimento* (duração, easing, performance de compositor, acessibilidade de motion). A skill `engenharia-de-ui-ux` trata da *estrutura* do componente (grid de 8px, os 5 estados, a11y estática, responsividade). Ao animar um componente com estados (loading/error/empty), aplicar as duas juntas, nesta ordem: estrutura primeiro (`engenharia-de-ui-ux`), movimento depois (esta skill). Em caso de conflito aparente — por exemplo, dimensão de skeleton fixa vs. duração de transição — a estrutura (dimensões, layout) tem precedência; o movimento se adapta a ela, nunca o contrário.

## Checklist rápido

- [ ] As durações e curvas de easing vêm de Motion Tokens centralizados, e não de valores soltos por componente?
- [ ] A animação usa exclusivamente `transform`/`opacity` (ou está explicitamente justificada a exceção)?
- [ ] Transições de saída/fechamento são mais rápidas que as de entrada/abertura?
- [ ] `will-change` é aplicado só durante a animação ativa e removido depois?
- [ ] Mudanças de layout usam a técnica FLIP (`references/flip-implementation.md`) ou a View Transitions API (com fallback FLIP) em vez de animar `width`/`height`/`top`/`left` diretamente?
- [ ] Se o usuário pediu explicitamente para animar uma propriedade proibida, o custo foi explicado e a alternativa via FLIP foi proposta antes de implementar o pedido original?
- [ ] A animação respeita `prefers-reduced-motion`, com o fallback de CSS implementado (não apenas mencionado)?
- [ ] Animações em loop automático têm controle de pausa acessível (WCAG 2.2.2)?
- [ ] Nenhuma animação pisca mais de 3x/segundo em alto contraste (WCAG 2.3.1), mesmo diante de pedido explícito e reafirmado do usuário?
- [ ] Sequências com múltiplos elementos usam stagger com direção lógica e teto de ~500ms de duração total, com direção invertida em locales RTL quando aplicável?
- [ ] O padrão de transição do Material 3 Motion aplicado (shared axis / fade through / container transform) foi nomeado explicitamente?
- [ ] Texto de leitura ativa não é distorcido por `scale`/`rotate` durante a transição?
- [ ] Em elementos que recebem foco (modal/drawer), o foco programático é movido só após o fim da animação de entrada, e o elemento só sai da árvore de foco após o fim da animação de saída?
- [ ] A animação foi testada no Chrome DevTools Performance com CPU throttling 4x, mantendo ao menos 50fps e sem *long tasks* > 50ms durante a execução?
- [ ] Cada animação tem um propósito comunicativo claro (feedback, continuidade, hierarquia) e não é puramente decorativa nem manipulativa?

## O que evitar

| Anti-padrão | Por quê | Ver seção |
|---|---|---|
| Animar `width`/`height`/`top`/`left`/`margin` diretamente | Causa reflow constante, quebra framerate, contribui para CLS | 3 |
| Easing `linear` fora de spinner/progress mecânico | Movimento parece artificial — não acelera/desacelera como algo físico | 1 |
| Duração igual para entrada e saída | Saída deve ser mais ágil; o usuário já decidiu sair | 1 |
| `will-change` global ou deixado permanentemente | Consome memória de GPU sem necessidade | 3 |
| Ignorar `prefers-reduced-motion` ou tratá-lo como opcional | Força movimento em quem pediu para reduzi-lo — não é opcional | 5 |
| Loop automático sem controle de pausa acessível | Viola WCAG 2.2.2 (Pause, Stop, Hide) | 5 |
| Flash em alto contraste acima de 3x/segundo | Risco real de convulsão fotossensível, não apenas desconforto | 5 |
| Mover o foco para um elemento antes de sua animação de entrada terminar | Leitor de tela anuncia conteúdo ainda em transição; foco pode ficar num estado intermediário confuso | 6.2 |
| Orquestrar dezenas de elementos sem stagger, ou sem teto de duração total | Sem stagger: gera sensação de "pop" caótico. Sem teto: força espera perceptível em listas longas | 4 |
| Recriar à mão (CSS/JS puro) animação vetorial complexa do design | Deveria vir como Lottie/Rive do time de design | 2 |
| Testar só em desktop de alta performance | Comportamento diverge em mobile/dispositivos entry-level | Checklist |
| Usar movimento para manipular a decisão do usuário em vez de comunicar estado real — inclui processamento falso/loading sem trabalho real por trás; elementos de fechar/cancelar/recusar que se movem, encolhem ou atrasam sua resposta ao clique para dificultar a saída de um fluxo ("roach motel"); e animações usadas para desviar a atenção do usuário no momento em que uma informação de custo, prazo ou consequência é exibida | É dark pattern, não motion design — **não implementar mesmo se solicitado explicitamente, sem justificativa funcional real** | 6 |
