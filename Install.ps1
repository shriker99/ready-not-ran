# Ready ≠ Ran installer — current user only. No admin. No network.
# Copies the checker onto THIS PC and makes a Start Menu + Desktop shortcut.

$ErrorActionPreference = 'Stop'

$here = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$dest = Join-Path $env:LOCALAPPDATA 'ReadyNotRan'

$copy = @(
    'ReadyNotRan.ps1',
    'Run-ReadyNotRan.cmd',
    'Uninstall.ps1',
    'FIXES.md',
    'PROBLEMS.md',
    'SECURITY.md',
    'BUYERS.md',
    'LICENSE',
    'README.md'
)

New-Item -ItemType Directory -Force -Path $dest | Out-Null

foreach ($name in $copy) {
    $from = Join-Path $here $name
    if (Test-Path -LiteralPath $from) {
        Copy-Item -LiteralPath $from -Destination (Join-Path $dest $name) -Force
    }
}

Get-ChildItem -LiteralPath $dest -File | ForEach-Object {
    try { Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue } catch { }
}

$cmd = Join-Path $dest 'Run-ReadyNotRan.cmd'
$ps1 = Join-Path $dest 'ReadyNotRan.ps1'
if (-not (Test-Path -LiteralPath $ps1)) {
    Write-Host 'ReadyNotRan.ps1 was not in this folder. Unzip the whole download and run Install again.'
    exit 1
}

function New-RnrShortcut {
    param([string]$LinkPath, [string]$TargetCmd)
    $folder = Split-Path -Parent $LinkPath
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $w = New-Object -ComObject WScript.Shell
    $s = $w.CreateShortcut($LinkPath)
    $s.TargetPath = $TargetCmd
    $s.WorkingDirectory = $dest
    $s.WindowStyle = 1
    $s.Description = 'Ready Not Ran — night-job checker'
    $s.Save()
}

$startDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Ready Not Ran'
New-RnrShortcut -LinkPath (Join-Path $startDir 'Ready Not Ran.lnk') -TargetCmd $cmd
New-RnrShortcut -LinkPath (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Ready Not Ran.lnk') -TargetCmd $cmd

Write-Host 'Installed for this Windows user only.'
Write-Host "Folder: $dest"
Write-Host 'Shortcuts: Start Menu and Desktop.'
Write-Host 'Nothing was sent off this PC. No admin rights were used.'
Write-Host 'Double-click Ready Not Ran to run the checker.'
