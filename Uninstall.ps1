# Removes the current-user install of Really Ran.

$ErrorActionPreference = 'Continue'

$dest = Join-Path $env:LOCALAPPDATA 'ReadyNotRan'
$desk = [Environment]::GetFolderPath('Desktop')
$links = @(
    (Join-Path $desk 'Really Ran.lnk'),
    (Join-Path $desk 'Ready Not Ran.lnk'),
    (Join-Path $desk 'Fix the easy ones.lnk'),
    (Join-Path $desk 'Put the old settings back.lnk'),
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Really Ran'),
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Ready Not Ran'),
    $dest
)

foreach ($p in $links) {
    if (Test-Path -LiteralPath $p) {
        Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host 'Really Ran was removed for this Windows user.'
