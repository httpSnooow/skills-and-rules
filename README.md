<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=24&height=220&section=header&text=skills%20%26amp;%20rules&fontSize=60&fontColor=ffffff&fontAlignY=38&desc=AI%20Agent%20Customizations%20for%20Antigravity%2C%20Cursor%2C%20Claude%20Code%20%26amp;%20Copilot&descAlignY=58&descSize=15&descColor=c4b5fd)

[![Skills](https://img.shields.io/badge/skills-14-7c3aed?style=flat-square&logo=gitbook&logoColor=white)](./skills)
[![Rules](https://img.shields.io/badge/rules-12-06b6d4?style=flat-square&logo=markdown&logoColor=white)](./rules)
[![Language](https://img.shields.io/badge/lang-pt--BR-10b981?style=flat-square&logo=googletranslate&logoColor=white)]()
[![Works with Antigravity](https://img.shields.io/badge/Antigravity-compatible-7c3aed?style=flat-square&logo=googlegemini&logoColor=white)]()
[![Works with Cursor](https://img.shields.io/badge/Cursor-compatible-000000?style=flat-square&logo=cursor&logoColor=white)]()
[![Works with Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-d97706?style=flat-square&logo=anthropic&logoColor=white)]()
[![Works with Copilot](https://img.shields.io/badge/Copilot-compatible-0078d4?style=flat-square&logo=github&logoColor=white)]()

</div>

> **Um toolkit production-grade de skills e rules.**
> Adicione ao Antigravity, Cursor, Claude Code ou Copilot.

<br/>

---

## 📋 Índice

- [O que é isso?](#-o-que-é-isso)
- [Como funciona](#-como-funciona)
- [Skills](#-skills-1)
- [Rules](#-rules-1)
- [Quick Start](#-quick-start-1)
- [Estrutura do Repositório](#-estrutura-do-repositório)

---

## 🧠 O que é isso?

Este repositório contém dois tipos de customizações para agentes de IA:

| Tipo | O que faz | Quantidade |
|------|-----------|-----------|
| **Skills** | Cheatsheets sob demanda carregadas pelo agente para workflows especializados (debugging, migrações, revisões…) | 14 |
| **Rules** | Restrições comportamentais sempre ativas que governam cada resposta (segurança, pragmatismo, disciplina de tokens…) | 12 |

Juntas, elas impõem os padrões de engenharia de um **desenvolvedor Staff-level** — em cada sessão, cada agente, cada projeto.

---

## ⚙️ Como funciona

```
┌─────────────────────────────────────────┐
│           Seu Agente de IA              │
│  (Antigravity / Cursor / Claude Code)   │
└──────────────┬──────────────────────────┘
               │ carrega na inicialização
               ▼
┌──────────────────────────┐
│         RULES/            │  ← sempre ativo, em cada turno
│  segurança · pragmatismo  │
│  performance · contratos  │
└──────────────────────────┘
               │ invocado sob demanda
               ▼
┌──────────────────────────┐
│         SKILLS/           │  ← ativado pelo tipo de tarefa
│  debug · review · migrate │
│  refactor · observe · …   │
└──────────────────────────┘
```

**Rules** são carregadas globalmente e se aplicam a cada resposta sem exceção.
**Skills** são invocadas quando o agente identifica um workflow específico (ex: `gate-pr` antes de um commit, `debugar-root-cause` quando um bug não está claro).

---

## 📦 Skills

Skills são conjuntos de instruções especializadas para workflows complexos e repetíveis. Cada skill é uma pasta contendo um `SKILL.md` com frontmatter YAML e orientações passo a passo detalhadas.

| Skill | Categoria | Descrição | Quando usar |
|-------|-----------|-----------|-------------|
| [`analisar-padroes`](./skills/analisar-padroes/) | 🔍 Análise | Busca implementações similares no codebase antes de escrever código novo. Alinha o trabalho com a arquitetura, nomenclatura e utilitários existentes. | Antes de implementar qualquer feature, API, tela ou serviço |
| [`code-review-critico`](./skills/code-review-critico/) | 🔬 Review | Revisa código como um Staff Engineer experiente. Foca em acoplamento, coesão, nomenclatura, complexidade ciclomática, testabilidade e segurança. | Ao revisar PRs ou auditar código legado |
| [`debugar-root-cause`](./skills/debugar-root-cause/) | 🐛 Debug | Framework sistemático de 4 fases: hipótese → experimento mínimo → isolamento → correção. | Quando a causa do bug não é imediatamente óbvia |
| [`documentar-decisao`](./skills/documentar-decisao/) | 📝 Docs | Gera um ADR (Architectural Decision Record) leve para escolhas de design não óbvias. | Ao introduzir uma mudança de padrão ou decisão arquitetural |
| [`engenharia-de-testes`](./skills/engenharia-de-testes/) | ✅ Testes | Projeta testes robustos focados em edge cases, caminhos negativos e tratamento de erros — além do happy path. | Ao criar ou atualizar arquivos de teste |
| [`engenharia-de-ui-ux`](./skills/engenharia-de-ui-ux/) | 🎨 UI/UX | Implementa UI/UX seguindo padrões Big Tech: grid de 8px, acessibilidade WCAG, gerenciamento defensivo de estados (loading/error/empty). | Ao criar ou atualizar componentes visuais |
| [`explicar-decisao-tecnica`](./skills/explicar-decisao-tecnica/) | 💡 Explicar | Explica a motivação arquitetural, padrões de design e trade-offs por trás de uma decisão de código. | Ao introduzir uma abstração complexa ou responder "por quê" |
| [`gate-pr`](./skills/gate-pr/) | 🚦 Qualidade | Checklist pré-PR: escopo respeitado, testes passando, sem artefatos de debug, sem dependências não declaradas, sem regressões de segurança. | Antes de considerar qualquer tarefa completa ou abrir um PR |
| [`mapeamento-de-armadilhas`](./skills/mapeamento-de-armadilhas/) | ⚠️ Risco | Destaca armadilhas comuns de produção, edge cases e anti-patterns associados ao código implementado. | Ao escrever lógica de negócio crítica, operações assíncronas ou acesso a DB |
| [`migracoes-zero-downtime`](./skills/migracoes-zero-downtime/) | 🗄️ Banco de Dados | Gera migrações de banco de dados seguras usando o padrão Expand and Contract — zero downtime garantido. | Ao adicionar, renomear ou remover colunas/tabelas em um DB em produção |
| [`montar-ambiente-ia-local`](./skills/montar-ambiente-ia-local/) | 🤖 Setup | Configura ou atualiza a governança de contexto de IA local (`.ai/`, rules, personas, limites de camadas, `.cursorignore`). | Ao inicializar a governança de IA em um novo projeto |
| [`observabilidade-e-telemetria`](./skills/observabilidade-e-telemetria/) | 📡 Observabilidade | Adiciona logs estruturados, métricas e traces distribuídos usando o modelo TRÊS PILARES (OpenTelemetry). | Ao implementar fluxos críticos de negócio que precisam ser monitorados em produção |
| [`refatoracao-segura`](./skills/refatoracao-segura/) | 🔄 Refatoração | Guia refatorações em larga escala usando Strangler Fig e Branch by Abstraction — migração incremental sem risco. | Para refatorações significativas que não podem ser feitas com segurança em um único PR |
| [`verificar-impacto`](./skills/verificar-impacto/) | 🔗 Impacto | Encontra usos de símbolos alterados (imports, referências, testes) e verifica que os fluxos dependentes ainda funcionam. | Antes de finalizar qualquer rename, mudança de assinatura ou edição de utilitário compartilhado |

---

## 📜 Rules

Rules são restrições comportamentais sempre ativas carregadas globalmente. Elas governam cada resposta do agente sem exceção.

| Rule | Princípio | Prioridade |
|------|-----------|------------|
| [`seguranca.md`](./rules/seguranca.md) | 🔒 **Prioridade máxima.** Nenhum secret no código, nenhum PII em logs, apenas queries parametrizadas, outputs sanitizados. Sobrepõe todas as outras rules. | `P0` |
| [`pragmatismo.md`](./rules/pragmatismo.md) | ⚖️ Resolva o problema real com a solução correta mais simples. Evite over-engineering. | `P1` |
| [`codigo-operacional.md`](./rules/codigo-operacional.md) | 🏗️ Estrutura e abstração com julgamento deliberado — sem padrões prematuros. | `P2` |
| [`0comentarios.md`](./rules/0comentarios.md) | 🚫 Nunca explique o que o código faz em comentários. Se precisar de um comentário, reescreva-o. | `P3` |
| [`contratos-e-api-design.md`](./rules/contratos-e-api-design.md) | 📐 Contratos de API são imutáveis. Nunca faça breaking changes silenciosamente. | `P3` |
| [`resiliencia-e-fallback.md`](./rules/resiliencia-e-fallback.md) | 🛡️ Sistemas devem falhar graciosamente. Toda chamada externa deve ter um fallback definido. | `P3` |
| [`performance-e-escala.md`](./rules/performance-e-escala.md) | 🚀 Anti-patterns proibidos de performance: queries N+1, loops sem limites, I/O síncrono em hot paths. | `P3` |
| [`token-budget.md`](./rules/token-budget.md) | 💰 Disciplina de execução por sessão. Pense antes de agir, nunca desperdice tokens em especulação. | `P3` |
| [`fluxo-humano.md`](./rules/fluxo-humano.md) | 🧑‍🏫 Modo mentor e fluxo humano de desenvolvimento. Explique decisões, não apenas entregue código. | `P3` |
| [`limites.md`](./rules/limites.md) | 🚧 Proibições absolutas de execução e terminal. Nunca execute comandos destrutivos sem confirmação. | `P3` |
| [`convencoes-projeto.md`](./rules/convencoes-projeto.md) | 📏 Siga as convenções de nomenclatura, estrutura de pastas e ferramentas do projeto atual. | `P3` |
| [`ambiguidade.md`](./rules/ambiguidade.md) | ❓ Nunca adivinhe regras de negócio. Se o prompt for ambíguo, escreva até onde tem certeza e pergunte. | `P3` |

> **Hierarquia de rules:** `seguranca` > `pragmatismo` > `codigo-operacional` > todas as outras.

---

## 🚀 Quick Start

### Antigravity

Coloque as pastas `skills/` e `rules/` dentro do diretório `.agents/` na raiz do workspace:

```
seu-projeto/
└── .agents/
    ├── skills/
    │   └── <nome-da-skill>/
    │       └── SKILL.md
    └── rules/
        └── <nome-da-rule>.md
```

O Antigravity auto-descobre e carrega todas as skills e rules de `.agents/` na inicialização.

---

### Cursor

Adicione rules ao diretório `.cursor/rules/`. Para skills, crie um arquivo `.cursor/rules/<nome-da-skill>.mdc` com o conteúdo da skill:

```
seu-projeto/
└── .cursor/
    └── rules/
        ├── seguranca.mdc
        ├── pragmatismo.mdc
        └── gate-pr.mdc        ← skill usada como rule
```

---

### Claude Code

Adicione rules ao `CLAUDE.md` na raiz do projeto, ou ao `~/.claude/CLAUDE.md` para rules globais. Para skills, referencie-as no seu `CLAUDE.md` com uma descrição de quando invocar cada uma.

```markdown
<!-- CLAUDE.md -->
## Rules
<!-- cole o conteúdo das rules aqui -->

## Skills
- Ao debugar bugs não óbvios, siga o workflow de debugar-root-cause.
- Antes de abrir qualquer PR, execute o checklist do gate-pr.
```

---

### GitHub Copilot

Adicione rules ao `.github/copilot-instructions.md`:

```
seu-projeto/
└── .github/
    └── copilot-instructions.md   ← cole o conteúdo das rules aqui
```

Para skills, crie arquivos de instrução individuais em `.github/copilot/instructions/`:

```
.github/
└── copilot/
    └── instructions/
        ├── gate-pr.instructions.md
        └── debugar-root-cause.instructions.md
```

---

## 📁 Estrutura do Repositório

```
skills-and-rules/
│
├── skills/                            # Workflows especializados sob demanda
│   ├── analisar-padroes/              # Análise de padrões antes de novo código
│   ├── code-review-critico/           # Code review de Staff Engineer
│   ├── debugar-root-cause/            # Debug de causa raiz em 4 fases
│   ├── documentar-decisao/            # Geração de ADR leve
│   ├── engenharia-de-testes/          # Engenharia de testes robustos
│   ├── engenharia-de-ui-ux/           # Padrões de UI/UX Big Tech
│   ├── explicar-decisao-tecnica/      # Explicação de arquitetura
│   ├── gate-pr/                       # Gate de qualidade pré-PR
│   ├── mapeamento-de-armadilhas/      # Mapeamento de armadilhas de produção
│   ├── migracoes-zero-downtime/       # Migrações de DB seguras
│   ├── montar-ambiente-ia-local/      # Setup de governança de IA local
│   ├── observabilidade-e-telemetria/  # Instrumentação OpenTelemetry
│   ├── refatoracao-segura/            # Refatoração com Strangler Fig
│   └── verificar-impacto/             # Verificação de impacto antes do PR
│
└── rules/                             # Restrições comportamentais sempre ativas
    ├── seguranca.md                   # 🔒 Hardening de segurança (P0)
    ├── pragmatismo.md                 # ⚖️ Pragmatismo e escopo (P1)
    ├── codigo-operacional.md          # 🏗️ Estrutura de código (P2)
    ├── 0comentarios.md                # 🚫 Zero comentários explicativos
    ├── contratos-e-api-design.md      # 📐 Contratos de API imutáveis
    ├── resiliencia-e-fallback.md      # 🛡️ Falha graciosa
    ├── performance-e-escala.md        # 🚀 Anti-patterns de performance
    ├── token-budget.md                # 💰 Disciplina de execução por sessão
    ├── fluxo-humano.md                # 🧑‍🏫 Modo mentor e fluxo humano
    ├── limites.md                     # 🚧 Proibições de execução
    ├── convencoes-projeto.md          # 📏 Convenções do projeto
    └── ambiguidade.md                 # ❓ Lidar com ambiguidade, nunca adivinhar
```

<div align="center">

---

🇺🇸 **English version below**

---

</div>


<br/>

> **A production-grade toolkit of skills and behavioral rules that transform any AI coding agent into a senior engineer.**
> Drop them into Antigravity, Cursor, Claude Code or Copilot and watch your agent stop guessing and start delivering.

<br/>

---

## 📋 Table of Contents

- [What is this?](#-what-is-this)
- [How it works](#-how-it-works)
- [Skills](#-skills)
- [Rules](#-rules)
- [Quick Start](#-quick-start)
- [Repository Structure](#-repository-structure)

---

## 🧠 What is this?

This repository contains two types of AI agent customizations:

| Type | What it does | Count |
|------|-------------|-------|
| **Skills** | On-demand cheatsheets loaded by the agent for specialized workflows (debugging, migrations, reviews…) | 14 |
| **Rules** | Always-on behavioral constraints that govern every response (security, pragmatism, token discipline…) | 12 |

Together, they enforce the engineering standards of a **Staff-level developer** — every session, every agent, every project.

---

## ⚙️ How it works

```
┌─────────────────────────────────────────┐
│           Your AI Agent                 │
│  (Antigravity / Cursor / Claude Code)   │
└──────────────┬──────────────────────────┘
               │ loads on startup
               ▼
┌──────────────────────────┐
│         RULES/            │  ← always active, every turn
│  security · pragmatism    │
│  performance · contracts  │
└──────────────────────────┘
               │ invoked on demand
               ▼
┌──────────────────────────┐
│         SKILLS/           │  ← triggered by task type
│  debug · review · migrate │
│  refactor · observe · …   │
└──────────────────────────┘
```

**Rules** are loaded globally and apply to every single response.
**Skills** are invoked when the agent identifies a specific workflow (e.g., `gate-pr` before a commit, `debugar-root-cause` when a bug is unclear).

---

## 📦 Skills

Skills are specialized instruction sets for complex, repeatable workflows. Each skill is a folder containing a `SKILL.md` with YAML frontmatter and detailed step-by-step guidance.

| Skill | Category | Description | When to use |
|-------|----------|-------------|-------------|
| [`analisar-padroes`](./skills/analisar-padroes/) | 🔍 Analysis | Searches the codebase for similar implementations before writing new code. Aligns new work with existing architecture, naming, and shared utilities. | Before implementing any new feature, API, screen, or service |
| [`code-review-critico`](./skills/code-review-critico/) | 🔬 Review | Reviews code as an experienced Staff Engineer. Focuses on coupling, cohesion, naming, cyclomatic complexity, testability, and security. | When reviewing PRs or auditing legacy code |
| [`debugar-root-cause`](./skills/debugar-root-cause/) | 🐛 Debug | Systematic 4-phase framework: hypothesis → minimum experiment → isolation → fix. | When the bug cause is not immediately obvious |
| [`documentar-decisao`](./skills/documentar-decisao/) | 📝 Docs | Generates a lightweight ADR (Architectural Decision Record) for non-obvious design choices. | When introducing a pattern change or architectural decision |
| [`engenharia-de-testes`](./skills/engenharia-de-testes/) | ✅ Testing | Designs robust tests focusing on edge cases, negative paths, and error handling — beyond the happy path. | When creating or updating test files |
| [`engenharia-de-ui-ux`](./skills/engenharia-de-ui-ux/) | 🎨 UI/UX | Implements UI/UX following Big Tech standards: 8px grid, WCAG accessibility, defensive state management (loading/error/empty). | When creating or updating visual components |
| [`explicar-decisao-tecnica`](./skills/explicar-decisao-tecnica/) | 💡 Explain | Explains the architectural motivation, design patterns, and trade-offs behind a coding decision. | When introducing a complex abstraction or answering "why" |
| [`gate-pr`](./skills/gate-pr/) | 🚦 Quality | Pre-PR checklist: scope respected, tests passing, no debug artifacts, no undeclared dependencies, no security regressions. | Before considering any task complete or opening a PR |
| [`mapeamento-de-armadilhas`](./skills/mapeamento-de-armadilhas/) | ⚠️ Risk | Highlights common production pitfalls, edge cases, and anti-patterns associated with the implemented code. | When writing core business logic, async operations, or DB access |
| [`migracoes-zero-downtime`](./skills/migracoes-zero-downtime/) | 🗄️ Database | Generates safe database migrations using the Expand and Contract pattern — zero downtime guaranteed. | When adding, renaming, or removing columns/tables on a live DB |
| [`montar-ambiente-ia-local`](./skills/montar-ambiente-ia-local/) | 🤖 Setup | Sets up or upgrades local AI context governance (`.ai/`, rules, personas, layer boundaries, `.cursorignore`). | When bootstrapping AI governance for a new project |
| [`observabilidade-e-telemetria`](./skills/observabilidade-e-telemetria/) | 📡 Observability | Adds structured logs, metrics, and distributed traces using the THREE PILLARS model (OpenTelemetry). | When implementing business-critical flows that must be monitored in production |
| [`refatoracao-segura`](./skills/refatoracao-segura/) | 🔄 Refactor | Guides large-scale refactoring using Strangler Fig and Branch by Abstraction — zero-risk incremental migration. | For significant refactors that cannot be safely done in a single PR |
| [`verificar-impacto`](./skills/verificar-impacto/) | 🔗 Impact | Finds usages of changed symbols (imports, references, tests) and verifies that dependent flows still work. | Before finalizing any rename, signature change, or shared utility edit |

---

## 📜 Rules

Rules are always-on behavioral constraints loaded globally. They govern every single agent response without exception.

| Rule | Principle | Priority |
|------|-----------|----------|
| [`seguranca.md`](./rules/seguranca.md) | 🔒 **Highest priority.** No secrets in code, no PII in logs, parameterized queries only, sanitized outputs. Overrides all other rules. | `P0` |
| [`pragmatismo.md`](./rules/pragmatismo.md) | ⚖️ Solve the actual problem with the simplest correct solution. Avoid over-engineering. | `P1` |
| [`codigo-operacional.md`](./rules/codigo-operacional.md) | 🏗️ Structure and abstraction with deliberate judgment — not premature patterns. | `P2` |
| [`0comentarios.md`](./rules/0comentarios.md) | 🚫 Never explain what the code does in comments. If it needs a comment, rewrite it. | `P3` |
| [`contratos-e-api-design.md`](./rules/contratos-e-api-design.md) | 📐 API contracts are immutable. Never make breaking changes silently. | `P3` |
| [`resiliencia-e-fallback.md`](./rules/resiliencia-e-fallback.md) | 🛡️ Systems must fail gracefully. Every external call must have a defined fallback. | `P3` |
| [`performance-e-escala.md`](./rules/performance-e-escala.md) | 🚀 Forbidden anti-patterns for performance: N+1 queries, unbounded loops, synchronous I/O in hot paths. | `P3` |
| [`token-budget.md`](./rules/token-budget.md) | 💰 Execution discipline per session. Think before acting, never burn tokens on speculation. | `P3` |
| [`fluxo-humano.md`](./rules/fluxo-humano.md) | 🧑‍🏫 Mentor mode and human development flow. Explain decisions, don't just deliver code. | `P3` |
| [`limites.md`](./rules/limites.md) | 🚧 Absolute execution and terminal prohibitions. Never run destructive commands without confirmation. | `P3` |
| [`convencoes-projeto.md`](./rules/convencoes-projeto.md) | 📏 Follow the current project's naming, folder structure, and tooling conventions. | `P3` |
| [`ambiguidade.md`](./rules/ambiguidade.md) | ❓ Never guess business rules. If the prompt is ambiguous, write to the edge of certainty and ask. | `P3` |

> **Rule hierarchy:** `seguranca` > `pragmatismo` > `codigo-operacional` > all others.

---

## 🚀 Quick Start

### Antigravity

Place the `skills/` and `rules/` folders inside your `.agents/` directory at the workspace root:

```
your-project/
└── .agents/
    ├── skills/
    │   └── <skill-name>/
    │       └── SKILL.md
    └── rules/
        └── <rule-name>.md
```

Antigravity auto-discovers and loads all skills and rules from `.agents/` on startup.

---

### Cursor

Add rules to your `.cursor/rules/` directory. For skills, create a `.cursor/rules/<skill-name>.mdc` file with the skill content:

```
your-project/
└── .cursor/
    └── rules/
        ├── seguranca.mdc
        ├── pragmatismo.mdc
        └── gate-pr.mdc        ← skill used as a rule
```

---

### Claude Code

Add rules to your `CLAUDE.md` at the project root, or to `~/.claude/CLAUDE.md` for global rules. For skills, reference them in your `CLAUDE.md` with a description of when to invoke each one.

```markdown
<!-- CLAUDE.md -->
## Rules
<!-- paste rule content here -->

## Skills
- When debugging non-obvious bugs, follow the debugar-root-cause workflow.
- Before opening any PR, run the gate-pr checklist.
```

---

### GitHub Copilot

Add rules to `.github/copilot-instructions.md`:

```
your-project/
└── .github/
    └── copilot-instructions.md   ← paste rule content here
```

For skills, create individual instruction files under `.github/copilot/instructions/`:

```
.github/
└── copilot/
    └── instructions/
        ├── gate-pr.instructions.md
        └── debugar-root-cause.instructions.md
```

---

## 📁 Repository Structure

```
skills-and-rules/
│
├── skills/                            # On-demand specialized workflows
│   ├── analisar-padroes/              # Pattern analysis before new code
│   ├── code-review-critico/           # Staff Engineer code review
│   ├── debugar-root-cause/            # 4-phase root cause debugging
│   ├── documentar-decisao/            # Lightweight ADR generation
│   ├── engenharia-de-testes/          # Robust test engineering
│   ├── engenharia-de-ui-ux/           # Big Tech UI/UX standards
│   ├── explicar-decisao-tecnica/      # Architecture explanation
│   ├── gate-pr/                       # Pre-PR quality gate
│   ├── mapeamento-de-armadilhas/      # Production pitfall mapping
│   ├── migracoes-zero-downtime/       # Safe DB migrations
│   ├── montar-ambiente-ia-local/      # Local AI governance setup
│   ├── observabilidade-e-telemetria/  # OpenTelemetry instrumentation
│   ├── refatoracao-segura/            # Strangler Fig refactoring
│   └── verificar-impacto/             # Impact verification before PR
│
└── rules/                             # Always-on behavioral constraints
    ├── seguranca.md                   # 🔒 Security hardening (P0)
    ├── pragmatismo.md                 # ⚖️ Pragmatism & scope (P1)
    ├── codigo-operacional.md          # 🏗️ Code structure (P2)
    ├── 0comentarios.md                # 🚫 Zero explanatory comments
    ├── contratos-e-api-design.md      # 📐 Immutable API contracts
    ├── resiliencia-e-fallback.md      # 🛡️ Graceful failure
    ├── performance-e-escala.md        # 🚀 Performance anti-patterns
    ├── token-budget.md                # 💰 Session execution discipline
    ├── fluxo-humano.md                # 🧑‍🏫 Mentor & human flow
    ├── limites.md                     # 🚧 Execution prohibitions
    ├── convencoes-projeto.md          # 📏 Project conventions
    └── ambiguidade.md                 # ❓ Handle ambiguity, never guess
```

<br/>

<div align="center">

![footer](https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=24&height=120&section=footer)

</div>
