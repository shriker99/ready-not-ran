# Removes the current-user install of Ready ≠ Ran.

$ErrorActionPreference = 'Continue'

$dest = Join-Path $env:LOCALAPPDATA 'ReadyNotRan'
$desktop = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Ready Not Ran.lnk'
$startDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Ready Not Ran'

foreach ($p in @($desktop, $startDir, $dest)) {
    if (Test-Path -LiteralPath $p) {
        Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host 'Ready Not Ran was removed for this Windows user.'
