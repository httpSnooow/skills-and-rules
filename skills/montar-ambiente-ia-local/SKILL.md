---
name: montar-ambiente-ia-local
description: >-
  Sets up or upgrades local AI context governance (.ai/, Cursor rules, personas,
  layer boundaries, feature files, .cursorignore, git isolation) for any
  codebase. Use when the user asks to create an AI environment, local AI
  context, gold-standard AI setup, .ai/ folder, agents/layers rules, audit or
  upgrade an existing .ai/ setup, or mount AI governance in a new project.
disable-model-invocation: true
---

# Montar ambiente de contexto IA local

**Versao:** ver [VERSION](VERSION) (atual: 1.1.0)

Monta ou **atualiza** um Sistema de Contexto de IA **100% local** (nao versionado) na raiz do workspace atual. Agnostico de stack: detecta camadas do projeto alvo; nao copia outro produto.

## Changelog

### 1.1.0
- Modo upgrade; scripts PS1+SH versionados; examples (Next + Django)
- Templates com cercas `~~~~`; verify exige padroes minimos de `.cursorignore`
- Plano B do hook; verify exige `hooks.json` se inject existir
- `scripts/smoke-skill.ps1` para prova automatizada da skill

### 1.0.0
- Prompt mestre, templates, verify checklist iniciais

## Antes de comecar

1. Ler [prompt-mestre.md](prompt-mestre.md).
2. Ler [templates.md](templates.md); **copiar** scripts de [scripts/](scripts/) (nao reescrever).
3. Consultar [examples.md](examples.md) como few-shot de qualidade.
4. Validar com [verify-checklist.md](verify-checklist.md).
5. Prova da skill (opcional/dev): `powershell -File scripts/smoke-skill.ps1` a partir da pasta da skill.

## Modo: greenfield vs upgrade

**Se `.ai/` NAO existir** → fluxo greenfield completo abaixo.

**Se `.ai/` JA existir** → modo upgrade:

1. Rodar verify do workspace (ou copiar scripts atualizados de [scripts/](scripts/)).
2. Comparar com [verify-checklist.md](verify-checklist.md) e [examples.md](examples.md).
3. Preencher gaps apenas (layers faltantes, globs FE data, cursorignore fraco, boot, hooks).
4. Nao destruir features `active` do usuario.
5. Re-rodar verify.

## Fluxo obrigatorio (greenfield)

1. **Analisar** arvore, stack, monorepo vs multi-repo.
2. **Inferir camadas** e mapa pasta → persona → layer.
3. **Plano curto**; se o usuario pediu implementar, executar.
4. **Gerar** a partir dos templates + **copiar** scripts:
   - `.ai/*` (context, agents, layers, features, playbooks, README)
   - `.cursor/rules/00-architecture.mdc` + `.mdc` por layer
   - `.cursorignore` (padroes minimos obrigatorios)
   - bloco Local AI nos `.gitignore`
   - hooks: copiar `scripts/inject-active-features.ps1` e/ou `.sh`
   - verify: copiar `scripts/verify-local.ps1` e/ou `.sh` para `.ai/scripts/`
5. **Isolar Git**.
6. **Verificar**.
7. **Nao commitar**. Sem secrets em `.ai/`.

## Principios inegociaveis

- Direcao de dependencia do projeto (unidirecional quando layered).
- Personas com **Pode / Nao pode**.
- Features locais ≠ specs versionaveis.
- `.mdc` curto; detalhe em `.ai/layers/*.md`.
- `.cursorignore` bloqueia `.env`, keys, build artifacts.
- Boot always-apply e a garantia; hook `sessionStart` e complemento (pode falhar).
- Clients HTTP sob `pages/**/services` (ou equivalente) = **data**, nao UI.
- Zero alucinacao de stack/contrato.

## Independencia de arquitetura

| Estilo | Exemplos de camadas |
|---|---|
| Layered | controller → service → repository → entity |
| Hexagonal | adapters/in, application/domain, adapters/out |
| Next.js | `app/` UI, `components/`, `lib/`/`services/` HTTP, route handlers |
| Django MTV | views → services → models |

Ver few-shot em [examples.md](examples.md).

## Uso

```
Use a skill montar-ambiente-ia-local e monte o ambiente completo de contexto IA local neste workspace.
```

Upgrade:

```
Use a skill montar-ambiente-ia-local e audite/atualize o .ai/ existente neste workspace.
```

Ou cole [prompt-mestre.md](prompt-mestre.md).

## O que esta skill NAO faz

- Nao assume stack especifica de um produto legado.
- Nao cria ArchUnit/ESLint/CI de camadas.
- Nao faz commit/push.
- Nao copia arquivos de outro repositorio de produto; so o metodo + scripts da skill.
