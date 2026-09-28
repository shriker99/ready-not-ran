# Ready ≠ Ran — do the easy fixes for this PC
# Changes only skip-settings. Never touches the program a job runs.
# Spare copy first. Undo-ReadyNotRan.ps1 puts the old jobs back.

[CmdletBinding()]
param(
    [switch]$Yes,
    [switch]$IncludeMicrosoft
)

$ErrorActionPreference = 'Continue'
$here = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$backupRoot = Join-Path $env:LOCALAPPDATA 'ReadyNotRan\backups'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $backupRoot $stamp
$outDir = Join-Path $here 'out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function H([string]$s) {
    if ($null -eq $s) { return '' }
    ((($s -replace '&', '&amp;') -replace '<', '&lt;') -replace '>', '&gt;') -replace '"', '&quot;'
}

try { Import-Module ScheduledTasks -ErrorAction Stop }
catch {
    Write-Host 'This fixer needs Windows. It will not run here.'
    exit 1
}

if (-not $Yes) {
    Write-Host ''
    Write-Host 'This will change night-job settings on THIS computer so backups and reports'
    Write-Host 'are less likely to be skipped (wake, battery, missed nights, idle).'
    Write-Host 'It will not change the program a job runs. It will not type a password.'
    Write-Host 'A spare copy is saved first so you can undo.'
    Write-Host ''
    $answer = Read-Host 'Type YES to fix the easy ones'
    if ($answer -ne 'YES') {
        Write-Host 'No changes were made.'
        exit 0
    }
}

$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
if (-not $IncludeMicrosoft) {
    $tasks = @($tasks | Where-Object { $_.TaskPath -notlike '\Microsoft\*' })
}

$changed = @()
$skipped = @()
$failed = @()

foreach ($t in $tasks) {
    $label = ($t.TaskPath + $t.TaskName)
    try {
        $s = $t.Settings
        $needs = $false
        if ($s.DisallowStartIfOnBatteries) { $needs = $true }
        if ($s.StopIfGoingOnBatteries) { $needs = $true }
        if (-not $s.WakeToRun) { $needs = $true }
        if (-not $s.StartWhenAvailable) { $needs = $true }
        if ($s.RunOnlyIfIdle) { $needs = $true }
        if ($s.RunOnlyIfNetworkAvailable) { $needs = $true }
        if ($s.Hidden) { $needs = $true }
        $restartCount = 0
        try { $restartCount = [int]$s.RestartCount } catch { }
        if ($restartCount -le 0) { $needs = $true }
        $stopIdle = $false
        try { if ($s.IdleSettings -and $s.IdleSettings.StopOnIdleEnd) { $stopIdle = $true } } catch { }
        if ($stopIdle) { $needs = $true }

        if (-not $needs) {
            $skipped += [pscustomobject]@{ Name = $t.TaskName; Folder = $t.TaskPath; Why = 'Already had the easy settings' }
            continue
        }

        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        $safeName = ($t.TaskPath.Trim('\') + '_' + $t.TaskName) -replace '[\\/:*?"<>|]', '_'
        if (-not $safeName) { $safeName = $t.TaskName }
        $xmlPath = Join-Path $backupDir ($safeName + '.xml')
        $xml = Export-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath
        Set-Content -Path $xmlPath -Value $xml -Encoding Unicode

        $s.DisallowStartIfOnBatteries = $false
        $s.StopIfGoingOnBatteries = $false
        $s.WakeToRun = $true
        $s.StartWhenAvailable = $true
        $s.RunOnlyIfIdle = $false
        $s.RunOnlyIfNetworkAvailable = $false
        $s.Hidden = $false
        $s.RestartCount = 3
        try { $s.RestartInterval = [TimeSpan]::FromMinutes(5) } catch { }
        try { if ($s.IdleSettings) { $s.IdleSettings.StopOnIdleEnd = $false } } catch { }
        try {
            $s.MultipleInstances = 'Queue'
        } catch {
            try { $s.MultipleInstances = 2 } catch { }
        }

        Set-ScheduledTask -InputObject $t -ErrorAction Stop | Out-Null
        $changed += [pscustomobject]@{ Name = $t.TaskName; Folder = $t.TaskPath; Why = 'Wake, battery, catch-up, idle, retry' }
    }
    catch {
        $msg = [string]$_.Exception.Message
        $hint = 'Could not change this job. Often needs the person who created it, or an old password.'
        if ($msg -match 'password|access|denied|privilege|unauthorized') {
            $hint = 'Windows blocked the change. A person must open this job and type the current password.'
        }
        $failed += [pscustomobject]@{ Name = $t.TaskName; Folder = $t.TaskPath; Why = $hint }
    }
}

$latest = Join-Path $backupRoot 'LATEST.txt'
if (Test-Path -LiteralPath $backupDir) {
    Set-Content -Path $latest -Value $backupDir -Encoding UTF8
}

$htmlPath = Join-Path $outDir 'ReadyNotRan-fix.html'
$cRows = (($changed | ForEach-Object { "<tr style='background:#e7f6ec'><td>$(H $_.Name)</td><td>$(H $_.Folder)</td><td>$(H $_.Why)</td></tr>" }) -join "`n")
$fRows = (($failed | ForEach-Object { "<tr style='background:#fde8e8'><td>$(H $_.Name)</td><td>$(H $_.Folder)</td><td>$(H $_.Why)</td></tr>" }) -join "`n")
$sRows = (($skipped | ForEach-Object { "<tr><td>$(H $_.Name)</td><td>$(H $_.Folder)</td><td>$(H $_.Why)</td></tr>" }) -join "`n")
if (-not $cRows) { $cRows = '<tr><td colspan="3">None</td></tr>' }
if (-not $fRows) { $fRows = '<tr><td colspan="3">None</td></tr>' }
if (-not $sRows) { $sRows = '<tr><td colspan="3">None</td></tr>' }
$when = Get-Date -Format 'yyyy-MM-dd HH:mm'
$backupNote = if (Test-Path -LiteralPath $backupDir) { $backupDir } else { 'No spare copy needed' }

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Ready ≠ Ran — what we changed</title>
<style>
body{font-family:Segoe UI,sans-serif;margin:24px;color:#222}
table{border-collapse:collapse;width:100%;font-size:14px;margin-bottom:18px}
th,td{border:1px solid #ccc;padding:8px;text-align:left}
th{background:#f4f4f4}
.sub{color:#555}
</style>
</head>
<body>
<h1>What we changed for you</h1>
<p class="sub">$when · Easy fixes only. The program each job runs was not changed.</p>
<p>Spare copy: $(H $backupNote)</p>
<p>To undo, double-click <b>Put the old settings back</b> or run Undo-ReadyNotRan.ps1.</p>
<h2>Changed</h2>
<table><tr><th>Job</th><th>Folder</th><th>What we did</th></tr>$cRows</table>
<h2>Could not change</h2>
<table><tr><th>Job</th><th>Folder</th><th>What a person must do</th></tr>$fRows</table>
<h2>Left alone</h2>
<table><tr><th>Job</th><th>Folder</th><th>Why</th></tr>$sRows</table>
<p>We still cannot type a password, invent a missing folder, or repair a backup program that writes nothing.</p>
</body>
</html>
"@
Set-Content -Path $htmlPath -Value $html -Encoding UTF8

Write-Host "Changed: $($changed.Count)"
Write-Host "Could not change: $($failed.Count)"
Write-Host "Left alone: $($skipped.Count)"
Write-Host "Report: $htmlPath"
if (Test-Path -LiteralPath $backupDir) { Write-Host "Spare copy: $backupDir" }
try { Invoke-Item $htmlPath } catch { }
