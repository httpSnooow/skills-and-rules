---
name: engenharia-de-ui-ux
description: >-
  Designs and implements UI/UX elements following Big Tech golden standards. 
  Enforces 8px grid, WCAG accessibility, and defensive state management 
  (loading, error, empty). Use when creating or updating visual components 
  like modals, cards, or screens.
---

# Engenharia de UI/UX

## Quando aplicar

Ao criar, refatorar ou atualizar elementos de interface gráfica no frontend (componentes, modais, cards, páginas, layouts) ou integrar dados na camada visual.

## Fluxo

1. **Fundação e Grid (8px)**: Aplicar espaçamentos, margens e dimensionamentos usando estritamente o sistema de Grid de 8px (ex: 8, 16, 24, 32). Utilizar exclusivamente Design Tokens (variáveis do Tailwind, CSS Vars) no lugar de valores arbitrários (`px` soltos).
2. **Arquitetura dos 5 Estados (UX Defensiva)**: Mapear e implementar explicitamente todos os cenários da interface: *Ideal State* (dados carregados), *Loading State* (Skeletons/Shimmers), *Empty State* (sem dados), *Error State* (falhas com opção de *Retry*) e *Partial State*.
3. **Acessibilidade Ouro (A11y/WCAG)**: Garantir suporte nativo a leitores de tela (atributos `aria-*`, `role`), navegação funcional via teclado (com `:focus-visible`) e alvos de toque ergonômicos (mínimo de 44x44px para interações).
4. **Hierarquia e Micro-interações**: Aplicar feedbacks visuais imediatos para todas as ações do usuário (estados de `:hover`, `:active`, `:disabled`) e limitar a hierarquia tipográfica a no máximo 3 tamanhos/pesos por contexto para evitar poluição visual.
5. **Responsividade e Mobile-First**:
   - Implementar sempre mobile-first: estilos base para o menor breakpoint, sobreposições (`@media min-width`) para telas maiores.
   - Breakpoints de referência (adaptar ao design system do projeto): `sm=640px`, `md=768px`, `lg=1024px`, `xl=1280px`.
   - Nunca usar valores de largura fixos em componentes que precisem funcionar em múltiplos contextos — usar `max-width` + `width: 100%`.
   - Testar mentalmente em **375px (iPhone SE)** antes de considerar pronto qualquer componente visual.

## Checklist rápido

- [ ] Cores, margens e tipografia utilizam Design Tokens (nada de valores hardcoded)?
- [ ] O componente trata cenários de *Loading* (Skeleton), *Error* (falhas de rede) e *Empty* de forma fluida?
- [ ] Elementos interativos possuem área de clique acessível, suporte a teclado (Tab) e não removem o outline de foco sem um substituto visual?
- [ ] Ações destrutivas (ex: exclusão) possuem confirmação e ações assíncronas fornecem feedback imediato (ex: desabilita botão e exibe spinner)?
- [ ] O componente funciona em viewport 375px sem scroll horizontal ou conteúdo cortado?
- [ ] Skeletons têm dimensões explícitas (width + height definidos) para reservar espaço e evitar Layout Shift?

## O que evitar

- Criar telas baseadas apenas no "caminho feliz" (dados renderizados perfeitamente no instante zero, sem prever latência ou exceções).
- Utilizar cores em hexadecimal bruto e valores fixos no CSS, quebrando o padrão visual do projeto e dificultando uso de Dark Mode.
- Utilizar "Spinners" de carregamento globais que empurram o conteúdo da tela (causando Layout Shift) em vez de reservar o espaço com Skeletons estruturais.
- Ignorar o mapeamento de áreas sensíveis ao toque para mobile, deixando botões muito pequenos.
