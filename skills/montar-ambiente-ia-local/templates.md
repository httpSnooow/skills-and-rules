# Templates — Ambiente de contexto IA local

Substituir placeholders: `{{PROJECT}}`, `{{LAYER}}`, `{{GLOB}}`, `{{PERSONA}}`, `{{STACK}}`, `{{FLOW}}`, `{{FOLDERS}}`, `{{VISAO}}`, `{{PASTA}}`.

Scripts oficiais da skill: copiar de [scripts/](scripts/) (nao reescrever a mao).

Usar ASCII nos scripts PowerShell (evitar caracteres Unicode que quebram encoding).

Blocos abaixo usam cerca externa `~~~~` para nao quebrar fences internos.

---

## `.ai/context.md`

~~~~markdown
# {{PROJECT}} — Contexto Global de IA (Local)

## Visão do produto
{{VISAO}}

## Stack
{{STACK}}

## Arquitetura / comunicação entre camadas
{{FLOW}}

1. Respeitar a direção de dependência do projeto.
2. Camada inferior não importa a superior.
3. Regras de negócio na camada de domínio/aplicação (não na borda HTTP/UI pura).
4. Contratos de borda separados do modelo de persistência quando o projeto assim fizer.
5. Zero alucinação: se não existir no código/contexto, perguntar.
6. Nunca ler `.env` / secrets (ver `.cursorignore`).

## Pastas canônicas
{{FOLDERS}}

## Fontes de verdade

| Arquivo | Uso | Git? |
|---|---|---|
| `.ai/context.md` | Stack e arquitetura | Local |
| `.ai/agents.md` | Personas | Local |
| `.ai/layers/*.md` | Limites por camada | Local |
| `.ai/features/*.md` | Negócio temporário (`_done/` = arquivo) | Local |
| `*.spec.md` ao lado do SUT | Spec de teste (se o time usar) | Repo OK |

## Features vs testes
1. Feature ativa em `.ai/features/` (local).
2. Implementar por persona/camada.
3. Specs versionáveis no repo do produto, se aplicável.
4. Feature local ≠ spec commitada.

## Segurança
- `.cursorignore` bloqueia `.env`, keys, build artifacts.
- Sem hardcode de segredos em código ou em `.ai/`.
~~~~

---

## `.ai/agents.md`

~~~~markdown
# Personas de IA — {{PROJECT}}

Uma persona por tarefa. Não misturar responsabilidades na mesma alteração, salvo orquestração pedida.

## Mapa rápido

| Pasta / concern | Persona | Layer |
|---|---|---|
| {{PASTA}} | {{PERSONA}} | `.ai/layers/{{LAYER}}.md` |

---

## {{PERSONA}}

**Camadas:** …
**Foco:** …

**Pode**
- …

**Não pode**
- …

**Referências:** `.ai/layers/{{LAYER}}.md`
~~~~

Repetir o bloco de persona 3–5 vezes conforme camadas detectadas.

---

## `.ai/layers/{{LAYER}}.md`

~~~~markdown
# Camada: {{LAYER}}

**Pacotes/pastas:** `{{GLOB}}`
**Persona:** {{PERSONA}}

## Responsabilidade
…

## Obrigatório
- …

## Proibido
- …

## Fluxo canônico

    entrada → camada → saida

## Exemplo

    ERRADO: misturar persistencia na borda HTTP
    CERTO: borda delega para dominio/aplicacao

## Oracle de qualidade
…
~~~~

---

## `.ai/features/_template.md`

~~~~markdown
# Template de Feature (negócio temporário — LOCAL)

Copie para `.ai/features/<nome-kebab>.md`. Não versionar.

---

## Name
<title>

## Status
draft | active | done

## Expires
<YYYY-MM-DD>

## Intent
<resultado observavel>

## Persona
…

## Scope
- Backend/API: `...`
- Frontend/UI: `...`

## Preconditions
- …

## Business Rules
1. …

## Steps
1. …

## Oracles
- API: …
- DB: …
- UI: …

## Negative
- …

## Data
- …

## Out of Scope
- …

## Anti-alucinação
- Não criar tabelas/endpoints/campos não listados
- Contratos a reutilizar: …

## Done when
- [ ] Oracles cobertos
- [ ] Camadas respeitadas (`.ai/layers/`)
- [ ] Sem arquivos fora do Scope
- [ ] Status → done (ou `_done/` / apagar)

## Testes (repo)
Se precisar de spec versionável: `*.spec.md` ao lado do SUT — separado deste arquivo local.
~~~~

---

## `.ai/features/README.md`

~~~~markdown
# Features locais (não versionar)

1. Copiar `_template.md` → `<slug>.md` com `Status: active`.
2. Prompt: persona + `@.ai/features/<slug>.md` + layer.
3. Ao terminar: `Status: done`, apagar, ou mover para `_done/`.

Sem secrets. Specs de teste do produto ficam no repositório; features só em `.ai/features/`.
`_done/` é ignorada no boot/hook.
~~~~

---

## `.ai/features/_done/README.md`

~~~~markdown
# Features arquivadas (`_done/`)

Exemplos e features concluídas. Não entram no boot nem no hook `sessionStart`.
Para reativar: mover para `.ai/features/` e setar `Status: active`.
~~~~

---

## `.ai/playbooks/feature-cycle.md`

~~~~markdown
# Playbook — ciclo de feature (local)

1. Copiar `_template` → `<slug>.md`, `Status: active`.
2. Implementar:

    Atue como [Persona].
    @.ai/features/<slug>.md
    @.ai/layers/<camada>.md

3. Specs versionáveis (`*.spec.md`) no repo do produto, se aplicável.
4. Encerrar: done → `_done/` ou apagar.
5. Rodar verify: `.ai/scripts/verify-local.ps1` (Windows) ou `.ai/scripts/verify-local.sh` (Unix).

Nunca commitar `.ai/`, `.cursor/rules/`, `.cursor/hooks*`.
~~~~

---

## `.ai/README.md`

~~~~markdown
# Sistema de Contexto de IA — Local

Tudo em `.ai/`, `.cursor/rules/` e `.cursor/hooks*` é local (gitignored).

## Como promptar

    Atue como [Persona].
    @.ai/features/<slug>.md
    @.ai/layers/<camada>.md

## Nunca commitar
`.ai/`, `.cursor/rules/`, `.cursor/hooks*`, `.cursorignore`, secrets, `.env`.

## Validar
Windows: `.\.ai\scripts\verify-local.ps1`
Unix: `bash .ai/scripts/verify-local.sh`
~~~~

---

## `.cursor/rules/00-architecture.mdc`

~~~~markdown
---
description: Arquitetura e boot de contexto IA local — {{PROJECT}}
alwaysApply: true
---

# {{PROJECT}} — Arquitetura

{{FLOW}}

- Negócio na camada de domínio/aplicação; borda HTTP/UI fina.
- Zero alucinação: sem inventar endpoint, coluna, DTO ou pacote.
- Nunca ler, citar ou logar `.env`, secrets, tokens ou senhas.
- Contexto local: `.ai/context.md`, `.ai/agents.md`, `.ai/layers/`, `.ai/features/`.
- Não commitar `.ai/`, `.cursor/rules/`, `.cursor/hooks*` nem `.cursorignore` de contexto.

## Boot (toda implementação)

1. Uma persona de `.ai/agents.md`.
2. Varrer `.ai/features/*.md` (exceto `_template` e `_done/`); se `Status: active`, ler e obedecer Scope/Oracles.
3. Respeitar a layer do arquivo aberto / glob.
4. Sem inventar contrato; na dúvida, perguntar.
~~~~

---

## `.cursor/rules/{{LAYER}}.mdc`

~~~~markdown
---
description: Limites da camada {{LAYER}}
globs: "{{GLOB}}"
alwaysApply: false
---

# {{LAYER}}

Resumo curto dos limites (3-6 linhas).

Detalhes: `.ai/layers/{{LAYER}}.md` · Persona: {{PERSONA}}
~~~~

---

## `.cursorignore`

~~~~
.env
**/.env
**/.env.*
!**/.env.example
**/settings.local.json
**/*.pem
**/*.key
**/id_rsa*
**/secrets/**
**/build/
**/dist/
**/target/
**/.gradle/
**/node_modules/
**/coverage/
**/*.log
**/out/
~~~~

Ajustar paths de dados sensíveis do projeto. O verify exige pelo menos: `.env`, `*.pem` ou `*.key`, `node_modules`.

---

## Bloco `.gitignore` (Local AI)

~~~~
### Local AI context (never commit) ###
.ai/
.cursor/rules/
.cursor/hooks.json
.cursor/hooks/
.cursor/*.md
.cursorignore
AGENTS.md
context.md
~~~~

---

## `.cursor/hooks.json` (Windows)

~~~~json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File .cursor/hooks/inject-active-features.ps1",
        "failClosed": false,
        "timeout": 15
      }
    ]
  }
}
~~~~

## `.cursor/hooks.json` (Unix)

~~~~json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "bash .cursor/hooks/inject-active-features.sh",
        "failClosed": false,
        "timeout": 15
      }
    ]
  }
}
~~~~

---

## Hooks e verify — copiar da skill

| Destino no workspace | Origem na skill |
|---|---|
| `.cursor/hooks/inject-active-features.ps1` | [scripts/inject-active-features.ps1](scripts/inject-active-features.ps1) |
| `.cursor/hooks/inject-active-features.sh` | [scripts/inject-active-features.sh](scripts/inject-active-features.sh) |
| `.ai/scripts/verify-local.ps1` | [scripts/verify-local.ps1](scripts/verify-local.ps1) |
| `.ai/scripts/verify-local.sh` | [scripts/verify-local.sh](scripts/verify-local.sh) |

Plano B se `sessionStart` nao injetar contexto: o boot em `00-architecture.mdc` (always-apply) obriga a varrer features `active`. Nao depender so do hook.
