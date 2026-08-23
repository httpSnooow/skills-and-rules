# Exemplo de referência — modal completo (entrada + saída + reduced-motion + foco)

Consultar este arquivo como exemplo de como as peças do `SKILL.md` se combinam num componente real. Não é uma técnica isolada como o FLIP — é a montagem ponta a ponta de tokens, performance de compositor, `prefers-reduced-motion` e gerenciamento de foco (item 6.2) num único componente, do jeito que apareceriam juntos numa implementação real.

## Tokens usados (definidos uma vez, centralizados — item 1)

```css
:root {
  --motion-duration-component: 300ms;      /* entrada */
  --motion-duration-component-exit: 200ms; /* saída — mais rápida que a entrada */
  --motion-easing-standard: cubic-bezier(0.4, 0, 0.2, 1);
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

## CSS do modal (apenas `transform`/`opacity` — item 3)

```css
.modal-overlay {
  opacity: 0;
  transition: opacity var(--motion-duration-component) var(--motion-easing-standard);
}
.modal-overlay.is-open {
  opacity: 1;
}
.modal-overlay.is-closing {
  transition-duration: var(--motion-duration-component-exit);
  opacity: 0;
}

.modal-panel {
  transform: translateY(16px) scale(0.98);
  opacity: 0;
  transition:
    transform var(--motion-duration-component) var(--motion-easing-standard),
    opacity var(--motion-duration-component) var(--motion-easing-standard);
}
.modal-panel.is-open {
  transform: translateY(0) scale(1);
  opacity: 1;
}
.modal-panel.is-closing {
  transition-duration: var(--motion-duration-component-exit);
  transform: translateY(8px) scale(0.98);
  opacity: 0;
}
```

## JS — sequenciamento de estado, animação e foco (item 6.2)

O ponto central deste exemplo: o foco só se move **depois** que a animação de entrada termina, e o elemento só sai da árvore de acessibilidade **depois** que a animação de saída termina — nunca no início de nenhuma das duas.

```js
function openModal(modal, overlay, triggerEl) {
  // elemento entra no DOM/visível, mas ainda fora da árvore de foco
  modal.removeAttribute('inert');
  overlay.classList.add('is-open');
  modal.classList.add('is-open');

  // Play: aguarda o fim da transição de ENTRADA antes de mover o foco
  const panel = modal.querySelector('.modal-panel');
  panel.addEventListener('transitionend', function onEnd(e) {
    if (e.propertyName !== 'transform') return;
    panel.removeEventListener('transitionend', onEnd);
    panel.focus(); // só agora — não no início da animação
  });
}

function closeModal(modal, overlay, triggerEl) {
  overlay.classList.remove('is-open');
  overlay.classList.add('is-closing');
  modal.classList.remove('is-open');
  modal.classList.add('is-closing');

  const panel = modal.querySelector('.modal-panel');
  panel.addEventListener('transitionend', function onEnd(e) {
    if (e.propertyName !== 'transform') return;
    panel.removeEventListener('transitionend', onEnd);
    // só agora, com a animação de SAÍDA já concluída, sai da árvore de foco
    modal.setAttribute('inert', '');
    modal.classList.remove('is-closing');
    overlay.classList.remove('is-closing');
    triggerEl?.focus(); // devolve o foco a quem abriu o modal
  });
}
```

## Por que este exemplo, e não só as peças isoladas

- Os **tokens** (item 1) evitam duração/easing soltos no componente.
- O CSS anima **só `transform`/`opacity`** (item 3), nunca `top`/`margin`/`display`.
- A duração de **saída é menor que a de entrada** (200ms vs 300ms — item 1).
- O bloco `prefers-reduced-motion` (item 5) zera as durações globalmente sem exigir nenhuma lógica condicional adicional no JS acima — o `transitionend` ainda dispara, só que quase instantaneamente.
- O foco só se move após `transitionend` da entrada, e o `inert` só é reaplicado após `transitionend` da saída (item 6.2) — é o sequenciamento que a maioria das implementações "no achismo" pula, movendo o foco no mesmo instante em que a classe `is-open` é aplicada.

Para replicar este padrão num componente diferente (drawer, toast), manter a mesma estrutura de: (1) tornar visível/focável → (2) aplicar classe de animação → (3) esperar `transitionend` → (4) só então mover foco ou retirar da árvore de acessibilidade.
