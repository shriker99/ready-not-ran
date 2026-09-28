# Really Ran installer — current user only. No admin. No network.
# Disk folder stays ReadyNotRan so spare copies and Undo still find them.

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
    'README.md',
    'NAME.md'
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
    Write-Host 'The program file was not in this folder. Unzip the whole download and run Install again.'
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

$startDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Really Ran'
$desk = [Environment]::GetFolderPath('Desktop')
New-RnrShortcut -LinkPath (Join-Path $startDir 'Really Ran.lnk') -TargetCmd $scanCmd -Description 'Really Ran — did last night finish?'
New-RnrShortcut -LinkPath (Join-Path $desk 'Really Ran.lnk') -TargetCmd $scanCmd -Description 'Really Ran — did last night finish?'
if (Test-Path -LiteralPath $fixCmd) {
    New-RnrShortcut -LinkPath (Join-Path $startDir 'Fix the easy ones.lnk') -TargetCmd $fixCmd -Description 'Really Ran — apply safe settings'
    New-RnrShortcut -LinkPath (Join-Path $desk 'Fix the easy ones.lnk') -TargetCmd $fixCmd -Description 'Really Ran — apply safe settings'
}
if (Test-Path -LiteralPath $undoCmd) {
    New-RnrShortcut -LinkPath (Join-Path $startDir 'Put the old settings back.lnk') -TargetCmd $undoCmd -Description 'Really Ran — undo the last fix'
    New-RnrShortcut -LinkPath (Join-Path $desk 'Put the old settings back.lnk') -TargetCmd $undoCmd -Description 'Really Ran — undo the last fix'
}

Write-Host 'Installed Really Ran for this Windows user only.'
Write-Host "Folder: $dest"
Write-Host 'Desktop: Really Ran  and  Fix the easy ones'
Write-Host 'Nothing was sent off this PC.'
