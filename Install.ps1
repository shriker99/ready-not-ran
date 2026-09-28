# Ready ≠ Ran installer — current user only. No admin. No network.

$ErrorActionPreference = 'Stop'

$here = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$dest = Join-Path $env:LOCALAPPDATA 'ReadyNotRan'

$copy = @(
    'ReadyNotRan.ps1',
    'Fix-ReadyNotRan.ps1',
    'Undo-ReadyNotRan.ps1',
    'Run-ReadyNotRan.cmd',
    'Run-Fix.cmd',
    'Run-Undo.cmd',
    'Uninstall.ps1',
    'FIXES.md',
    'PROBLEMS.md',
    'SECURITY.md',
    'BUYERS.md',
    'APPLY.md',
    'WHEN-IT-FAILS.md',
    'START-HERE.md',
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

$scanCmd = Join-Path $dest 'Run-ReadyNotRan.cmd'
$fixCmd = Join-Path $dest 'Run-Fix.cmd'
$undoCmd = Join-Path $dest 'Run-Undo.cmd'
$ps1 = Join-Path $dest 'ReadyNotRan.ps1'
if (-not (Test-Path -LiteralPath $ps1)) {
    Write-Host 'ReadyNotRan.ps1 was not in this folder. Unzip the whole download and run Install again.'
    exit 1
}

function New-RnrShortcut {
    param([string]$LinkPath, [string]$TargetCmd, [string]$Description)
    $folder = Split-Path -Parent $LinkPath
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $w = New-Object -ComObject WScript.Shell
    $s = $w.CreateShortcut($LinkPath)
    $s.TargetPath = $TargetCmd
    $s.WorkingDirectory = $dest
    $s.WindowStyle = 1
    $s.Description = $Description
    $s.Save()
}

$startDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Ready Not Ran'
$desk = [Environment]::GetFolderPath('Desktop')
New-RnrShortcut -LinkPath (Join-Path $startDir 'Ready Not Ran.lnk') -TargetCmd $scanCmd -Description 'Check night jobs on this PC'
New-RnrShortcut -LinkPath (Join-Path $desk 'Ready Not Ran.lnk') -TargetCmd $scanCmd -Description 'Check night jobs on this PC'
if (Test-Path -LiteralPath $fixCmd) {
    New-RnrShortcut -LinkPath (Join-Path $startDir 'Fix the easy ones.lnk') -TargetCmd $fixCmd -Description 'Apply safe night-job settings'
    New-RnrShortcut -LinkPath (Join-Path $desk 'Fix the easy ones.lnk') -TargetCmd $fixCmd -Description 'Apply safe night-job settings'
}
if (Test-Path -LiteralPath $undoCmd) {
    New-RnrShortcut -LinkPath (Join-Path $startDir 'Put the old settings back.lnk') -TargetCmd $undoCmd -Description 'Undo the last Ready Not Ran fix'
}

Write-Host 'Installed for this Windows user only.'
Write-Host "Folder: $dest"
Write-Host 'Desktop: Ready Not Ran  and  Fix the easy ones'
Write-Host 'Nothing was sent off this PC.'
