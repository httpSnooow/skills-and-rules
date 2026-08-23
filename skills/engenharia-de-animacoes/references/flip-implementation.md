# Implementação de referência — técnica FLIP

Consultar este arquivo sempre que for animar uma mudança de layout (posição/tamanho de um elemento entre dois estados). Não reescrever a técnica do zero — copiar e adaptar o padrão abaixo.

## Por que FLIP

Animar `width`, `height`, `top` ou `left` diretamente força o navegador a recalcular layout e paint a cada frame, derrubando o framerate e contribuindo para Cumulative Layout Shift (CLS). FLIP contorna isso: em vez de animar a propriedade de layout, mede-se a diferença entre o estado inicial e final, e anima-se apenas um `transform` (translate + scale) que rodam no compositor.

As quatro etapas dão nome à técnica:
- **First**: medir a posição/tamanho do elemento no estado inicial.
- **Last**: aplicar a mudança de estado real (classe, layout) instantaneamente, sem animar.
- **Invert**: calcular a diferença entre First e Last, e aplicar um `transform` que faz o elemento *parecer* que ainda está no estado inicial.
- **Play**: no frame seguinte, remover o `transform` com uma transição — o navegador anima a diferença suavemente, e só `transform` está sendo animado.

## Implementação básica (elemento único)

```js
// First: medir estado inicial
const first = el.getBoundingClientRect();

// Last: aplicar a mudança de estado real (classe, layout, etc.) sem animar
el.classList.add('expanded');
const last = el.getBoundingClientRect();

// Invert: calcular a diferença e "congelar" visualmente no estado inicial
const dx = first.left - last.left;
const dy = first.top - last.top;
const sx = first.width / last.width;
const sy = first.height / last.height;
el.style.transformOrigin = 'top left';
el.style.transform = `translate(${dx}px, ${dy}px) scale(${sx}, ${sy})`;

// Play: no próximo frame, remover o transform com transição — só transform/opacity animam
requestAnimationFrame(() => {
  el.style.transition = 'transform 300ms cubic-bezier(0.4,0,0.2,1)';
  el.style.transform = '';
});
```

Usar os tokens de duração/easing do projeto (ex: `--motion-duration-component`, `--motion-easing-standard`) em vez do valor literal `300ms cubic-bezier(0.4,0,0.2,1)` acima — o literal está aqui apenas para deixar o exemplo autocontido.

## Variação — múltiplos elementos (grid/lista reordenando)

Quando vários elementos mudam de posição ao mesmo tempo (ex: um grid que reordena, ou itens que saem de uma lista e os remanescentes se reacomodam), medir First/Last de todos antes de aplicar qualquer `transform`, para evitar que a leitura de um elemento seja afetada pelo layout já alterado de outro:

```js
// First: medir todos antes de qualquer mudança
const firstRects = new Map(items.map(el => [el, el.getBoundingClientRect()]));

// Last: aplicar a reordenação real (ex: mudar a ordem no DOM/flex/grid)
applyNewOrder();

// Invert + Play: por elemento
items.forEach(el => {
  const first = firstRects.get(el);
  const last = el.getBoundingClientRect();
  const dx = first.left - last.left;
  const dy = first.top - last.top;
  if (dx === 0 && dy === 0) return; // elemento não se moveu, pular

  el.style.transform = `translate(${dx}px, ${dy}px)`;
  el.style.transition = 'none';

  requestAnimationFrame(() => {
    el.style.transition = 'transform 300ms cubic-bezier(0.4,0,0.2,1)';
    el.style.transform = '';
  });
});
```

## Quando preferir uma biblioteca em vez de FLIP manual

Para casos simples (1-2 elementos, mudança pontual), a implementação manual acima é suficiente e não adiciona dependência. Para listas grandes, reordenação frequente, ou quando o projeto já usa Framer Motion/Motion, preferir a primitiva `layout` da própria biblioteca (ex: `<motion.div layout>`), que implementa FLIP internamente com tratamento de casos-limite (elementos entrando/saindo durante a animação, layouts aninhados) que a implementação manual acima não cobre.

## Alternativa nativa: View Transitions API

Para transições de página/rota ou mudanças de estado do DOM em navegadores com suporte a `document.startViewTransition`, a View Transitions API resolve o mesmo problema (capturar snapshot "antes/depois" e animar via `transform`/`opacity`) sem a medição manual acima. Ver item 2 do `SKILL.md` para o critério de quando preferir cada uma. Quando o projeto precisar de compatibilidade ampla ou controle fino sobre múltiplos elementos com casos-limite (itens entrando/saindo durante a transição), a implementação FLIP manual deste arquivo continua sendo a opção mais previsível.
