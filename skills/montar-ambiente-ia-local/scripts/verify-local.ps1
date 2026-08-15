$ErrorActionPreference = 'Stop'

if (Test-Path (Join-Path (Get-Location) '.ai')) {
  $root = (Get-Location).Path
} else {
  $candidate = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  if (Test-Path (Join-Path $candidate '.ai')) {
    $root = $candidate
  } else {
    $root = (Get-Location).Path
  }
}
Set-Location $root

$required = @(
  '.cursorignore',
  '.ai\context.md',
  '.ai\agents.md',
  '.ai\README.md',
  '.ai\features\_template.md',
  '.ai\features\README.md',
  '.ai\features\_done\README.md',
  '.ai\playbooks\feature-cycle.md',
  '.cursor\rules\00-architecture.mdc'
)

$failed = $false
foreach ($rel in $required) {
  if (-not (Test-Path $rel)) {
    Write-Host "MISSING: $rel"
    $failed = $true
  } else {
    Write-Host "OK: $rel"
  }
}

$layerFiles = @(Get-ChildItem '.ai\layers' -Filter '*.md' -File -ErrorAction SilentlyContinue)
if ($layerFiles.Count -lt 1) {
  Write-Host 'MISSING: .ai/layers/*.md'
  $failed = $true
} else {
  Write-Host ("OK: {0} layer file(s)" -f $layerFiles.Count)
}

$mdcFiles = @(Get-ChildItem '.cursor\rules' -Filter '*.mdc' -File -ErrorAction SilentlyContinue)
if ($mdcFiles.Count -lt 2) {
  Write-Host 'MISSING: expected always-apply + at least one layer mdc'
  $failed = $true
} else {
  Write-Host ("OK: {0} mdc file(s)" -f $mdcFiles.Count)
}

$arch = Get-Content '.cursor\rules\00-architecture.mdc' -Raw -ErrorAction SilentlyContinue
if (-not $arch -or $arch -notmatch 'alwaysApply:\s*true') {
  Write-Host 'BAD: 00-architecture.mdc must have alwaysApply: true'
  $failed = $true
} else {
  Write-Host 'OK: alwaysApply architecture rule'
}

$ci = Get-Content '.cursorignore' -Raw -ErrorAction SilentlyContinue
$ciOk = $true
if (-not $ci) {
  Write-Host 'MISSING: .cursorignore content'
  $failed = $true
  $ciOk = $false
} else {
  if ($ci -notmatch '\.env') {
    Write-Host 'WEAK cursorignore: missing .env'
    $failed = $true
    $ciOk = $false
  }
  if ($ci -notmatch 'node_modules') {
    Write-Host 'WEAK cursorignore: missing node_modules'
    $failed = $true
    $ciOk = $false
  }
  if ($ci -notmatch '\.pem|\.key') {
    Write-Host 'WEAK cursorignore: missing .pem/.key'
    $failed = $true
    $ciOk = $false
  }
}
if ($ciOk) {
  Write-Host 'OK: cursorignore minimum patterns'
}

function Assert-CleanRepo([string]$repoRel) {
  if (-not (Test-Path $repoRel)) { return }
  if (-not (Test-Path (Join-Path $repoRel '.git'))) {
    Write-Host "SKIP git: $repoRel (no .git)"
    return
  }
  Push-Location $repoRel
  try {
    $status = @(git status --short)
    $hits = @($status | Where-Object { $_ -match '\.ai(/|\\)|\.cursor(/|\\)(rules|hooks)|\.cursorignore' })
    if ($hits.Count -gt 0) {
      Write-Host "LEAK in ${repoRel}:"
      $hits | ForEach-Object { Write-Host "  $_" }
      $script:failed = $true
    } else {
      Write-Host "OK git isolation: $repoRel"
    }
  } finally {
    Pop-Location
  }
}

if (Test-Path '.git') { Assert-CleanRepo '.' }
Get-ChildItem -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  if (Test-Path (Join-Path $_.FullName '.git')) {
    Assert-CleanRepo $_.Name
  }
}

$hookPs1 = '.cursor\hooks\inject-active-features.ps1'
$hookSh = '.cursor\hooks\inject-active-features.sh'
$hasHook = (Test-Path $hookPs1) -or (Test-Path $hookSh)
if ($hasHook) {
  if (-not (Test-Path '.cursor\hooks.json')) {
    Write-Host 'MISSING: .cursor/hooks.json (inject script present)'
    $failed = $true
  } else {
    Write-Host 'OK: hooks.json present with inject script'
  }
}

if (Test-Path $hookPs1) {
  Write-Host '--- hook smoke (ps1) ---'
  $hookOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $hookPs1 2>&1
  try {
    $null = ($hookOut | Out-String).Trim() | ConvertFrom-Json
    Write-Host 'OK: hook returns JSON'
  } catch {
    Write-Host "BAD hook JSON: $hookOut"
    $failed = $true
  }
} elseif (Test-Path $hookSh) {
  Write-Host 'SKIP hook JSON smoke on Windows for .sh'
} else {
  Write-Host 'SKIP hook (not installed)'
}

if ($failed) {
  Write-Host 'VERIFY FAILED'
  exit 1
}
Write-Host 'VERIFY PASSED'
exit 0
