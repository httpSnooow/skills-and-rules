# Verify checklist — Ambiente de contexto IA local

Usar ao final da montagem ou no modo upgrade. Scripts oficiais: [scripts/](scripts/).

## Checklist de aceite

- [ ] `.ai/context.md` descreve stack e pastas **reais**
- [ ] `.ai/agents.md` com 3–5 personas (Pode / Nao pode) + mapa
- [ ] `.ai/layers/` cobre concerns principais
- [ ] `.ai/features/_template.md` + README + `_done/README.md`
- [ ] `.ai/playbooks/feature-cycle.md` + `.ai/README.md`
- [ ] `.cursor/rules/00-architecture.mdc` com `alwaysApply: true` e boot
- [ ] Um `.mdc` por layer com globs corretos
- [ ] FE: se houver `pages/**/services` (ou equivalente), glob de **data** inclui; UI declara precedencia
- [ ] `.cursorignore` contem no minimo: `.env`, `node_modules`, `.pem` ou `.key`
- [ ] `.gitignore` ignora `.ai/`, rules, hooks, `.cursorignore`
- [ ] Scripts **copiados** de [scripts/](scripts/) (nao reescritos)
- [ ] Hook opcional: JSON valido; `failClosed: false`
- [ ] Se existir inject script, existe `.cursor/hooks.json`
- [ ] Plano B documentado: boot always-apply varre features `active` se hook falhar
- [ ] Verify passou
- [ ] (Dev da skill) `scripts/smoke-skill.ps1` passou
- [ ] Nenhum secret em `.ai/`; nenhum commit pelo agente

## Isolamento Git

```powershell
git status --short
```

Nao deve listar `.ai/`, `.cursor/rules/`, `.cursor/hooks*`, `.cursorignore` como untracked a versionar.

Alteracao esperada nos repos: apenas linhas em `.gitignore` (humano decide commit).

## Como instalar os scripts no workspace

Da pasta da skill `montar-ambiente-ia-local/scripts/`:

| Destino | Origem |
|---|---|
| `.ai/scripts/verify-local.ps1` | `scripts/verify-local.ps1` |
| `.ai/scripts/verify-local.sh` | `scripts/verify-local.sh` |
| `.cursor/hooks/inject-active-features.ps1` | `scripts/inject-active-features.ps1` |
| `.cursor/hooks/inject-active-features.sh` | `scripts/inject-active-features.sh` |

Rodar:

```powershell
.\.ai\scripts\verify-local.ps1
```

```bash
bash .ai/scripts/verify-local.sh
```

## Plano B do hook (sessionStart)

`additional_context` de `sessionStart` pode nao ser injetado em algumas versoes do Cursor.

Garantia primaria: boot em `.cursor/rules/00-architecture.mdc` (always-apply) obriga varrer `.ai/features` com `Status: active`.

Nao bloquear montagem se o hook falhar; manter `failClosed: false`.

## Smoke da skill (desenvolvedor)

Na pasta da skill:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-skill.ps1
```

Cria fixture temporaria, copia scripts, roda verify + deteccao de feature active, apaga o temp.

## Modo upgrade

Se `.ai/` ja existir: rodar verify, listar falhas, preencher gaps, re-rodar. Nao apagar features `active`.

## Uso diario

```
Atue como [Persona].
@.ai/features/<slug>.md
@.ai/layers/<camada>.md
```
