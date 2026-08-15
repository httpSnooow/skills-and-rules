$ErrorActionPreference = 'Continue'
$root = Get-Location
$featuresDir = Join-Path $root '.ai\features'
$actives = New-Object System.Collections.Generic.List[object]
if (Test-Path $featuresDir) {
  Get-ChildItem -Path $featuresDir -Filter '*.md' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne '_template.md' } |
    ForEach-Object {
      $raw = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if (-not $raw) { return }
      $isActive = $false
      if ($raw -match '(?im)^\s*#{1,2}\s*Status\s*\r?\n+\s*(draft|active|done)\s*$') {
        $isActive = ($Matches[1].ToLowerInvariant() -eq 'active')
      } elseif ($raw -match '(?im)^\s*Status\s*:\s*(draft|active|done)') {
        $isActive = ($Matches[1].ToLowerInvariant() -eq 'active')
      }
      if (-not $isActive) { return }
      $name = $_.BaseName
      if ($raw -match '(?im)^\s*#{1,2}\s*Name\s*\r?\n+\s*([^\r\n#]+)') {
        $name = $Matches[1].Trim()
      }
      $intent = ''
      if ($raw -match '(?im)^\s*#{1,2}\s*Intent\s*\r?\n+\s*([^\r\n#]+)') {
        $intent = $Matches[1].Trim()
      }
      $actives.Add([pscustomobject]@{ Rel = ('.ai/features/' + $_.Name); Name = $name; Intent = $intent }) | Out-Null
    }
}
$context = ''
$envMap = @{ ACTIVE_AI_FEATURES = '' }
if ($actives.Count -gt 0) {
  $lines = New-Object System.Collections.Generic.List[string]
  [void]$lines.Add('Active local AI features (read and obey Scope/Oracles before coding):')
  foreach ($a in $actives) {
    $line = '- ' + $a.Rel + ': ' + $a.Name
    if ($a.Intent) { $line = $line + ' - ' + $a.Intent }
    [void]$lines.Add($line)
  }
  $context = [string]::Join([Environment]::NewLine, $lines)
  $envMap['ACTIVE_AI_FEATURES'] = [string]::Join(';', ($actives | ForEach-Object { $_.Rel }))
}
$result = [ordered]@{ env = $envMap; additional_context = $context }
[Console]::Out.Write(($result | ConvertTo-Json -Compress -Depth 5))
exit 0
