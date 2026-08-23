# Referência — Performance de Compositor

Consultar quando implementar exceções documentadas no item 3 do SKILL.md, ao depurar
jank em casos específicos, ou ao lidar com `clip-path`, `filter`, `will-change`,
`content-visibility` e animações em stagger de listas longas.

---

## `clip-path` e compositor

`clip-path: circle()` e `clip-path: inset()` são aceleradas pelo compositor no Chrome/Edge
quando o elemento tem `will-change: clip-path` — útil para animações de revelar (iris,
curtain). Para verificar se a layer está sendo promovida: DevTools → Rendering panel →
Layer Borders.

Cuidados:
- `clip-path: polygon()` com muitos vértices força paint a cada frame — não é
  compositor-safe independente de `will-change`.
- `clip-path: path()` tem comportamento variável entre versões de navegador — testar no
  alvo antes de usar.

---

## `filter: brightness()` e `hue-rotate()` como alternativa compositor-safe a `background-color`

`filter: brightness()` é um multiplicador linear aplicado no compositor — mas tem limites:

- Em elementos escuros (`#1a1a1a` ou similar em `prefers-color-scheme: dark`), limitar a
  `brightness(0.9)–brightness(1.15)`. Acima de `brightness(1.2)`, o resultado em elementos
  escuros pode ser próximo ao branco — efeito não intencional.
- Preferir `opacity` quando a variação de cor entre estados for grande.

**`forced-colors` (Windows High Contrast Mode):** `filter: brightness()` e
`filter: hue-rotate()` são **ignorados** em `@media (forced-colors: active)`. Elementos
que dependem de variação de filtro para comunicar estado perdem esse sinal visual em High
Contrast. Garantir que o estado seja legível também via forma, posição ou opacidade:

```css
@media (forced-colors: active) {
  /* Estado de hover/focus legível por borda, não apenas por cor/filtro */
  .interactive-el:hover,
  .interactive-el:focus-visible {
    outline: 2px solid ButtonText; /* usa cor do sistema — sempre visível */
  }
}
```

Testar animações críticas de UI com Windows → Configurações → Acessibilidade → Temas de
alto contraste ativados.

---

## `will-change` — uso correto e armadilhas

### Padrão correto: aplicar apenas durante a animação

```css
.card { /* estado padrão — sem will-change */ }
.card.animating { will-change: transform, opacity; }
```

```js
el.classList.add('animating');
el.addEventListener('transitionend', () => el.classList.remove('animating'), { once: true });
```

**Nunca** usar `will-change: transform` globalmente ou de forma permanente — cada elemento
promovido consome memória de GPU separada. Em CSS de reset ou globais (`*, *::before`),
isso pode criar dezenas ou centenas de layers desnecessárias.

### Safari iOS — fallback de promoção de layer

Em Safari iOS, `will-change` pode ser ignorado em elementos com posicionamento complexo
(ex: elementos aninhados em `position: fixed` com `transform` no ancestral). Se houver
jank perceptível mesmo com `will-change` declarado:

```css
.animating {
  will-change: transform, opacity;
  transform: translateZ(0); /* fallback legado de promoção de layer — Safari iOS */
}
```

Remover `transform: translateZ(0)` junto com `will-change` após a animação, pelo mesmo
motivo.

---

## `content-visibility: auto` e animações em listas

Em listas longas com `content-visibility: auto`, elementos fora da viewport não têm layout
calculado — `getBoundingClientRect()` retorna zeros, e `transitionend` pode não disparar.

### Padrão correto com IntersectionObserver

```js
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      animateElement(entry.target);
      observer.unobserve(entry.target); // evita repetição ao sair/voltar à viewport
    }
  });
});

items.forEach(el => observer.observe(el));
```

### Cleanup obrigatório em componentes com ciclo de vida

`unobserve(el)` remove apenas a observação do elemento específico — o observer em si
permanece ativo na memória. Em SPAs de navegação longa, observers não desconectados
acumulam e causam degradação de performance:

```js
// React
useEffect(() => {
  const observer = new IntersectionObserver(callback);
  items.forEach(el => observer.observe(el));
  return () => observer.disconnect(); // cleanup no unmount
}, []);

// Vue
onUnmounted(() => observer.disconnect());

// Svelte
onDestroy(() => observer.disconnect());
```

---

## Layer explosion em stagger

Ao usar `will-change: transform` em stagger de muitos elementos (dezenas), cada elemento
promovido cria uma layer de GPU separada. Em listas de 50+ itens, isso pode resultar em
centenas de MB de memória de GPU.

Estratégias para evitar:
1. Aplicar `will-change` apenas nos primeiros 8–10 elementos visíveis (alinhado com o teto
   de stagger do item 4 do SKILL.md).
2. Remover `will-change` imediatamente após cada animação terminar (via `transitionend`).
3. Verificar consumo de layers em Chrome DevTools → Layers panel antes de shipar.

---

## Verificação no DevTools

| O que verificar | Onde encontrar |
|---|---|
| Layers promovidas | DevTools → Layers panel |
| Paint a cada frame | DevTools → Rendering → Paint Flashing |
| Long Tasks >50ms | DevTools → Performance → Main thread |
| INP (Interaction to Next Paint) | DevTools → Performance → Interactions |
| CLS | DevTools → Performance → Experience |
