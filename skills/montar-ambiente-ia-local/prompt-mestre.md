# Prompt mestre — Sistema de Contexto de IA Local (Padrão de Ouro)

Cole este prompt inteiro no Cursor em **qualquer** projeto/workspace. O agente deve analisar o repositório alvo e gerar a estrutura; não copiar outro produto.

---

Atue como um Arquiteto Sênior de IA e Auditor de Qualidade. Nossa equipe adota o Padrão de Ouro de desenvolvimento assistido por IA: governança de contexto, limites por camada/pasta, personas com alçada clara, zero alucinação e contexto **100% local** (não vai para o Git do produto).

## Missão

Implementar ou **atualizar** um **Sistema de Contexto de IA Local** na raiz deste workspace, independente da arquitetura do projeto (layered, hexagonal, Next.js, Django, etc.). Você deve **detectar** a estrutura real e adaptar — nunca assumir Controller/Service/Repository a menos que existam.

Se `.ai/` já existir: modo upgrade — rodar verify, preencher gaps, não apagar features `active`.

Scripts oficiais (verify + hook): copiar da skill `montar-ambiente-ia-local/scripts/` — não reescrever à mão.

## Restrições inegociáveis

1. Analisar o repo **antes** de criar arquivos; não escrever cegamente.
2. Contexto em `.ai/` e enforcement em `.cursor/rules/` (e opcionalmente `.cursor/hooks*`).
3. **Nunca** versionar: `.ai/`, `.cursor/rules/`, `.cursor/hooks.json`, `.cursor/hooks/`, `.cursorignore` (de contexto).
4. Atualizar/criar `.gitignore` na raiz e em cada repo Git filho com essas entradas (só o ignore pode ir ao Git; o conteúdo de contexto fica local).
5. Não fazer commit/push.
6. Não colocar secrets, tokens ou dumps em `.ai/`.
7. Zero alucinação: se stack, pasta ou contrato não existir, perguntar — não inventar.
8. `.mdc` curtos; detalhe em `.ai/layers/*.md`.
9. Features locais ≠ specs de teste versionáveis (`*.spec.md` no repo do produto).
10. Always-apply com boot checklist é a garantia; hook `sessionStart` é complemento (pode falhar em algumas versões do Cursor).

## Passo 1 — Análise

1. Listar a árvore relevante (ignorar `node_modules`, `build`, `.git`, `dist`, `target`).
2. Identificar stack (ex.: `package.json`, `build.gradle*`, `pom.xml`, `pyproject.toml`, `Cargo.toml`, `go.mod`).
3. Detectar se é monorepo, multi-repo irmãos, ou repo único; onde está o `.git`.
4. Mapear pastas/pacotes que funcionam como camadas ou bounded contexts.
5. Notar padrões especiais (ex.: clients HTTP sob `pages/**/services` → tratar como camada de **dados**, não UI).

## Passo 2 — Decisão de paths

Usar na **raiz do workspace** (pasta aberta no Cursor):

```
.ai/
  context.md
  agents.md
  README.md
  layers/
  features/
    _template.md
    README.md
    _done/
  playbooks/
    feature-cycle.md
  scripts/
    verify-local.ps1
.cursor/
  rules/
    00-architecture.mdc
    <layer>.mdc ...
  hooks.json          (opcional)
  hooks/              (opcional)
.cursorignore
```

## Passo 3 — Isolamento Git

Em todo `.gitignore` relevante, garantir bloco:

```
.ai/
.cursor/rules/
.cursor/hooks.json
.cursor/hooks/
.cursor/*.md
.cursorignore
AGENTS.md
context.md
```

Não usar padrões frágeis tipo `**/layers/` que possam ignorar código-fonte.

## Passo 4 — Arquivos globais

### `.ai/context.md`

Preencher com: visão do produto (deduzida), stack real, regra de comunicação entre camadas (adaptada ao estilo detectado), pastas canônicas, tabela de fontes de verdade, seção Features vs testes, segurança (`.cursorignore`).

### `.ai/agents.md`

Criar 3–5 personas baseadas nas camadas detectadas. Cada uma com: camadas, foco, **Pode**, **Não pode**, referências a `.ai/layers/...`. Incluir mapa rápido pasta → persona → layer.

Exemplos de nomes (adaptar): `[Agente de API/Borda]`, `[Agente de Domínio]`, `[Agente de Infra/Dados]`, `[Agente de Frontend/UI]`.

## Passo 5 — Layers, features e playbook

1. Um arquivo `.ai/layers/<nome>.md` por concern detectado (obrigatório/proibido/fluxo/oracle; 1 exemplo ❌/✅ quando possível).
2. Concerns auxiliares (enums, utils, i18n, mocks, config) podem ir em `supporting.md` se forem muitos.
3. `.ai/features/_template.md` com: Name, Status (`draft|active|done`), Expires, Intent, Persona, Scope, Preconditions, Business Rules, Steps, Oracles, Negative, Data, Out of Scope, Anti-alucinação, Done when; nota sobre `*.spec.md` no repo.
4. `.ai/features/README.md` + `.ai/features/_done/README.md`.
5. `.ai/playbooks/feature-cycle.md` (abrir feature → implementar por persona → testes versionáveis opcionais → done/`_done` → verify).
6. `.ai/README.md` de onboarding (como promptar, o que não commitar).

## Passo 6 — Cursor rules, ignore e hook

1. `.cursor/rules/00-architecture.mdc` com `alwaysApply: true`: unidirecionalidade adaptada, zero alucinação, nunca ler secrets, ponteiros `.ai/`, boot:
   - uma persona;
   - varrer features `Status: active` (exceto `_template` e `_done/`);
   - respeitar layer do arquivo aberto;
   - não inventar contrato.
2. Um `.mdc` por layer com `globs` corretos e corpo curto apontando para `.ai/layers/...`.
3. Frontend: separar UI vs data quando fizer sentido; incluir globs de services colocados sob pages se existirem.
4. `.cursorignore` mínimo obrigatório (verify falha se faltar): `.env`, `node_modules`, `.pem`/`.key`; mais `**/.env.*` (exceto `!.env.example`), build/target, coverage, logs, secrets.
5. Opcional: hook `sessionStart` (copiar PS1 e/ou SH da skill) com JSON `{ "env": { "ACTIVE_AI_FEATURES": "..." }, "additional_context": "..." }` e `failClosed: false`. Plano B: boot always-apply varre features `active` se o inject falhar.

## Passo 7 — Verify e entrega

1. Copiar `verify-local.ps1` / `verify-local.sh` da skill para `.ai/scripts/` e executar.
2. Entregar: árvore criada; camadas/personas; como promptar; o que nunca commitar; commit de `.gitignore` é decisão do humano.

## Independência de arquitetura (guia rápido)

| Estilo | Direção típica | Personas típicas |
|---|---|---|
| Layered | UI/HTTP → domínio → dados | API, Domínio, Infra, Frontend |
| Hexagonal | adapters → application/domain → ports/adapters out | Borda, Domínio, Infra |
| Next.js App Router | page/component → lib/services → route handlers | UI, Data/HTTP, API Route |
| Django MTV | view → service → model | View/API, Domínio, Dados |

## Formato de prompt diário (documentar no README)

```
Atue como [Persona].
@.ai/features/<slug>.md
@.ai/layers/<camada>.md
```

Uma persona por etapa em fluxos multi-camada.

## Critério de pronto

- [ ] Análise refletida nos arquivos (stack e pastas reais)
- [ ] `.ai/` + `.cursor/rules/` + `.cursorignore` criados
- [ ] Ignores nos repos Git
- [ ] Personas com Pode/Não pode
- [ ] Layers com limites claros
- [ ] Feature template + playbook + README
- [ ] Always-apply com boot
- [ ] Verify passou
- [ ] Nenhum commit feito por você
