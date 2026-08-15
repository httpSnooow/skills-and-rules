$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $skillRoot 'SKILL.md'))) {
  Write-Host 'BAD: run from skill scripts/ folder'
  exit 1
}

$fixture = Join-Path $env:TEMP ("ai-skill-smoke-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
Write-Host "FIXTURE: $fixture"

try {
  $dirs = @(
    '.ai\layers',
    '.ai\features\_done',
    '.ai\playbooks',
    '.ai\scripts',
    '.cursor\rules',
    '.cursor\hooks'
  )
  foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path (Join-Path $fixture $d) -Force | Out-Null
  }

  @'
# Smoke Project — Contexto Global de IA (Local)

## Visão do produto
Fixture for skill smoke test.

## Stack
- Fake stack for verify

## Arquitetura / comunicação entre camadas
UI -> service -> repository

## Pastas canônicas
src/ui, src/services, src/repositories
'@ | Set-Content (Join-Path $fixture '.ai\context.md') -Encoding utf8

  @'
# Personas

## Mapa rápido
| Pasta | Persona | Layer |
|---|---|---|
| services | [Agente de Dominio] | services.md |

## [Agente de Dominio]
**Pode**
- regras de negocio
**Nao pode**
- HTTP
'@ | Set-Content (Join-Path $fixture '.ai\agents.md') -Encoding utf8

  @'
# Camada: services
**Persona:** [Agente de Dominio]
## Responsabilidade
Dominio
## Obrigatorio
- validar
## Proibido
- HTTP
'@ | Set-Content (Join-Path $fixture '.ai\layers\services.md') -Encoding utf8

  @'
# Template
## Name
x
## Status
draft
'@ | Set-Content (Join-Path $fixture '.ai\features\_template.md') -Encoding utf8

  '# features' | Set-Content (Join-Path $fixture '.ai\features\README.md') -Encoding utf8
  '# done' | Set-Content (Join-Path $fixture '.ai\features\_done\README.md') -Encoding utf8
  '# cycle' | Set-Content (Join-Path $fixture '.ai\playbooks\feature-cycle.md') -Encoding utf8
  '# readme' | Set-Content (Join-Path $fixture '.ai\README.md') -Encoding utf8

  @'
---
description: smoke architecture
alwaysApply: true
---

# Smoke architecture
Boot: persona, active features, layer, no invent.
'@ | Set-Content (Join-Path $fixture '.cursor\rules\00-architecture.mdc') -Encoding utf8

  @'
---
description: services layer
globs: "**/services/**/*.ts"
alwaysApply: false
---

# services
Detalhes: .ai/layers/services.md
'@ | Set-Content (Join-Path $fixture '.cursor\rules\backend-service.mdc') -Encoding utf8

  @'
.env
**/.env
**/.env.*
!**/.env.example
**/*.pem
**/*.key
**/node_modules/
**/build/
'@ | Set-Content (Join-Path $fixture '.cursorignore') -Encoding utf8

  Copy-Item (Join-Path $skillRoot 'scripts\verify-local.ps1') (Join-Path $fixture '.ai\scripts\verify-local.ps1') -Force
  Copy-Item (Join-Path $skillRoot 'scripts\inject-active-features.ps1') (Join-Path $fixture '.cursor\hooks\inject-active-features.ps1') -Force

  @'
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
'@ | Set-Content (Join-Path $fixture '.cursor\hooks.json') -Encoding utf8

  Push-Location $fixture
  try {
    Write-Host '--- verify ---'
    & powershell -NoProfile -ExecutionPolicy Bypass -File '.\.ai\scripts\verify-local.ps1'
    if ($LASTEXITCODE -ne 0) {
      throw "verify failed with exit $LASTEXITCODE"
    }

    Write-Host '--- hook empty ---'
    $empty = & powershell -NoProfile -ExecutionPolicy Bypass -File '.\.cursor\hooks\inject-active-features.ps1'
    $emptyObj = ($empty | Out-String).Trim() | ConvertFrom-Json
    if ($null -eq $emptyObj.env) { throw 'hook missing env' }

    @'
# Name
Smoke Feature

## Status
active

## Intent
Prove active detection
'@ | Set-Content '.\.ai\features\_smoke-active.md' -Encoding utf8

    Write-Host '--- hook active ---'
    $active = & powershell -NoProfile -ExecutionPolicy Bypass -File '.\.cursor\hooks\inject-active-features.ps1'
    $activeObj = ($active | Out-String).Trim() | ConvertFrom-Json
    if ($activeObj.env.ACTIVE_AI_FEATURES -notmatch '_smoke-active') {
      throw "active feature not detected: $($activeObj.env.ACTIVE_AI_FEATURES)"
    }
    Write-Host 'OK: active feature detected'
  } finally {
    Pop-Location
  }

  Write-Host 'SMOKE PASSED'
  exit 0
} catch {
  Write-Host "SMOKE FAILED: $_"
  exit 1
} finally {
  if (Test-Path $fixture) {
    Remove-Item -Recurse -Force $fixture -ErrorAction SilentlyContinue
  }
}
