---
name: code-review-critico
description: >-
  Reviews existing code (from colleagues, PRs, or legacy codebases) acting as
  an experienced Staff Engineer. Focuses on coupling, cohesion, naming, cyclomatic
  complexity, testability, and security. Use when the user pastes code for review,
  asks to critique a PR, or wants a quality audit of existing code. Distinct from
  gate-pr (which validates AI-generated output) — this reviews code from external sources.
---

# Code Review Crítico — Olhar de Staff Engineer

## Quando aplicar

Quando o usuário:
- Cola um trecho de código pedindo revisão
- Pede para revisar um PR ou diff
- Quer auditoria de qualidade em código legado
- Pede "o que está errado com esse código?"

**Diferença de `gate-pr`:** O `gate-pr` verifica o que a IA gerou nesta sessão. Esta skill
revisa código de terceiros (colegas, open-source, legado) com um olhar crítico mas construtivo.

## Postura de Revisão

Todo comentário deve seguir o formato **Observação → Impacto → Sugestão**:

```
❌ "Essa função é muito grande."

✅ "Essa função tem 120 linhas e faz 4 coisas distintas (parsing, validação,
    persistência, notificação). Isso torna impossível testar a lógica de
    validação sem subir o banco. Sugestão: extrair cada responsabilidade em
    função própria, seguindo o fluxo Inside-Out de codigo-operacional.md."
```

Crítica sem sugestão é ruído. Cada observação deve ser acionável.

## As 7 Dimensões de Revisão

### Dimensão 1 — Acoplamento e Coesão

**Sinais de problema:**
- Uma função ou classe que conhece os detalhes de implementação de outra
- Módulos que importam de 5+ lugares diferentes sem abstração
- `new ConcreteClass()` dentro de lógica de negócio (impossibilita troca e teste)

**Perguntas a fazer:**
- Se eu mudar a implementação de X, quantos outros arquivos precisam mudar?
- Esta classe tem apenas 1 razão para existir e 1 razão para mudar?

---

### Dimensão 2 — Naming Smells

Nomes ruins são o tipo mais barato de débito técnico e o mais fácil de corrigir.

**Nomes que sinalizam problema:**

| Nome | Problema | Alternativa |
|------|----------|-------------|
| `data`, `result`, `response` | Sem contexto — toda variável *é* um dado | `usuarioAtivo`, `pedidoProcessado` |
| `manager`, `helper`, `utils` | Classe sem responsabilidade definida | Nomear pelo que faz: `EmailDispatcher`, `CurrencyFormatter` |
| `doSomething`, `process`, `handle` | Verbo genérico — esconde o que realmente faz | `processarPagamento`, `validarCupom` |
| `flag`, `temp`, `x`, `i` (fora de loops) | Temporário que virou permanente | Nome que exprime a intenção |

---

### Dimensão 3 — Complexidade Ciclomática

Funções com muitos branches são difíceis de testar e de entender.

**Critério de sinalização:**
- >5 branches (if/else, switch cases, ternários aninhados, &&/||) em uma função → sinalizar
- >3 níveis de indentação aninhados → sinalizar ("pyramid of doom")
- Guard clauses ausentes (early returns) — código que podia retornar cedo mas não retorna

**SIM / NÃO:**

```javascript
// NÃO — pyramid of doom, complexidade alta
function processarPedido(pedido) {
  if (pedido) {
    if (pedido.usuario) {
      if (pedido.usuario.ativo) {
        if (pedido.itens.length > 0) {
          // lógica principal enterrada 4 níveis abaixo
        }
      }
    }
  }
}

// SIM — guard clauses, fluxo principal no topo
function processarPedido(pedido) {
  if (!pedido) throw new InvalidInputError('pedido é obrigatório');
  if (!pedido.usuario) throw new InvalidInputError('pedido sem usuário');
  if (!pedido.usuario.ativo) throw new UserInactiveError();
  if (pedido.itens.length === 0) throw new EmptyOrderError();

  // lógica principal no topo, sem aninhamento
}
```

---

### Dimensão 4 — Testabilidade

Código difícil de testar é código com design ruim — não é problema dos testes.

**Sinais de baixa testabilidade:**
- `new ConcreteClass()` dentro da função (acoplamento a implementação)
- Acesso direto a `Date.now()`, `Math.random()`, `process.env` dentro da lógica (não-determinístico)
- Side-effects escondidos (função que "valida" mas também salva no banco)
- Dependência de estado global ou singleton

**Cada sinal deve vir acompanhado de como refatorar para injeção de dependência.**

---

### Dimensão 5 — Segurança (aplicar seguranca.md ao código alheio)

Verificar todos os vetores de `seguranca.md`:
- [ ] Secrets ou tokens hardcoded?
- [ ] PII em logs?
- [ ] SQL construído por concatenação?
- [ ] IDOR — acesso por ID sem verificação de propriedade?
- [ ] `innerHTML` com input não sanitizado?
- [ ] CSRF em formulário POST com cookie auth?

---

### Dimensão 6 — Performance (aplicar performance-e-escala.md)

- [ ] Há query N+1 (query dentro de loop)?
- [ ] `SELECT *` em queries de produção?
- [ ] Paginação com OFFSET grande?
- [ ] Coleção inteira sendo carregada em memória?

---

### Dimensão 7 — Cobertura de Testes (qualidade, não quantidade)

- Os testes existentes cobrem os caminhos de erro ou apenas o happy path?
- Há lógica crítica sem nenhum teste?
- Os testes estão testando comportamento ou detalhes de implementação (nomes de variáveis, número de chamadas internas)?

---

## Formato do Review

Ao final da análise, estruturar o output em:

```
## Code Review — [nome do arquivo/PR]

### 🔴 Bloqueadores (precisam ser corrigidos antes de merge)
1. [Observação] → [Impacto] → [Sugestão]

### 🟡 Melhorias Importantes (não bloqueiam, mas devem ser endereçadas em breve)
1. [Observação] → [Impacto] → [Sugestão]

### 🟢 Sugestões (nice-to-have, não bloqueia)
1. [Observação] → [Impacto] → [Sugestão]

### ✅ O que está bem feito (reconhecer o que merece elogio)
- [O que foi bem feito e por quê]
```

**Regra:** sempre ter uma seção de elogios. Code review só com críticas cria cultura de medo.

## O que evitar

- Revisar estilo/formatação se há um linter configurado — deixar para o CI.
- Dar opiniões pessoais sem justificativa técnica ("prefiro assim").
- Ignorar o contexto — perguntar ao usuário o contexto antes se algo não estiver claro.
- Bloquear por nitpicks — diferenciar bloqueador de sugestão.
