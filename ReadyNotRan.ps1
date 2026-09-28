# Ready ≠ Ran — read-only night-job checker
# Does not change scheduled tasks. Writes HTML + CSV under .\out

[CmdletBinding()]
param(
    [switch]$IncludeMicrosoft
)

$ErrorActionPreference = 'Stop'

function Get-ResultWords {
    param([int]$Code)
    switch ([uint32]$Code) {
        0          { 'Windows says the program finished cleanly' }
        267009     { 'Still running' }
        267011     { 'Has not run yet' }
        267012     { 'No more times left on the schedule' }
        267014     { 'Stopped by a person' }
        2147942402 { 'File or program path not found' }
        2147942667 { 'Folder in the path does not exist' }
        2147943645 { 'Saved login for the job is wrong or expired' }
        3221225786 { 'The program was closed while running' }
        default    { "Windows code $Code" }
    }
}

function Get-Verdict {
    param($State, $LastRun, $Result, $Missed, $SkipReasons)
    $never = -not $LastRun -or $LastRun.Year -lt 2000
    if ($State -eq 'Disabled') { return 'Disabled' }
    if ($never -or $Result -eq 267011) { return 'Never ran' }
    if ($Missed -gt 0) { return 'Missed' }
    if ($Result -ne 0) { return 'Failed' }
    if ($SkipReasons.Count -gt 0) { return 'May skip' }
    return 'Looks OK'
}

$here = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$outDir = Join-Path $here 'out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

try {
    Import-Module ScheduledTasks -ErrorAction Stop
} catch {
    Write-Host 'This checker needs Windows Scheduled Tasks. It will not run here.'
    exit 1
}

$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
if (-not $IncludeMicrosoft) {
    $tasks = @($tasks | Where-Object { $_.TaskPath -notlike '\Microsoft\*' })
}

$rows = @()
foreach ($t in $tasks) {
    try {
        $info = Get-ScheduledTaskInfo -InputObject $t -ErrorAction Stop
    } catch {
        continue
    }

    $settings = $t.Settings
    $skip = @()
    if ($settings.DisallowStartIfOnBatteries) { $skip += 'will not start on battery' }
    if ($settings.StopIfGoingOnBatteries) { $skip += 'stops if the plug is pulled' }
    if ($settings.RunOnlyIfIdle) { $skip += 'waits until the PC is idle' }
    if (-not $settings.WakeToRun) { $skip += 'will not wake a sleeping PC' }
    if (-not $settings.StartWhenAvailable) { $skip += 'will not catch up after a missed night' }

    $actions = @()
    foreach ($a in @($t.Actions)) {
        $line = [string]$a.Execute
        if ($a.Arguments) { $line = ($line + ' ' + [string]$a.Arguments).Trim() }
        if ($line) { $actions += $line }
    }

    $lastRun = $info.LastRunTime
    $nextRun = $info.NextRunTime
    $result = [int]$info.LastTaskResult
    $missed = 0
    try { $missed = [int]$info.NumberOfMissedRuns } catch { $missed = 0 }

    $verdict = Get-Verdict -State $t.State -LastRun $lastRun -Result $result -Missed $missed -SkipReasons $skip

    $rows += [pscustomobject]@{
        Name         = $t.TaskName
        Folder       = $t.TaskPath
        Status       = [string]$t.State
        Verdict      = $verdict
        LastRun      = if ($lastRun -and $lastRun.Year -ge 2000) { $lastRun.ToString('yyyy-MM-dd HH:mm') } else { 'never' }
        NextRun      = if ($nextRun -and $nextRun.Year -ge 2000) { $nextRun.ToString('yyyy-MM-dd HH:mm') } else { 'none' }
        LastResult   = Get-ResultWords $result
        MissedNights = $missed
        SkipRisks    = ($skip -join '; ')
        Command      = ($actions -join ' | ')
    }
}

$rows = @($rows | Sort-Object @{Expression = {
    switch ($_.Verdict) {
        'Failed' { 0 }
        'Missed' { 1 }
        'Never ran' { 2 }
        'Disabled' { 3 }
        'May skip' { 4 }
        default { 5 }
    }
}}, Name)

$csvPath = Join-Path $outDir 'ReadyNotRan.csv'
$htmlPath = Join-Path $outDir 'ReadyNotRan.html'
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath

function H([string]$s) {
    if ($null -eq $s) { return '' }
    ($s -replace '&', '&' -replace '<', '<' -replace '>', '>' -replace '"', '"')
}

$counts = $rows | Group-Object Verdict | ForEach-Object { "$($_.Count) $($_.Name)" }
$summary = if ($counts) { $counts -join ' · ' } else { 'No jobs found' }

$tr = New-Object System.Text.StringBuilder
foreach ($r in $rows) {
    $tone = switch ($r.Verdict) {
        'Failed' { '#fde8e8' }
        'Missed' { '#fff4d6' }
        'Never ran' { '#fff4d6' }
        'Disabled' { '#eee' }
        'May skip' { '#e8f1fb' }
        default { '#e7f6ec' }
    }
    [void]$tr.Append("<tr style='background:$tone'><td>$(H $r.Name)</td><td>$(H $r.Folder)</td><td>$(H $r.Status)</td><td><b>$(H $r.Verdict)</b></td><td>$(H $r.LastRun)</td><td>$(H $r.NextRun)</td><td>$(H $r.LastResult)</td><td>$(H ([string]$r.MissedNights))</td><td>$(H $r.SkipRisks)</td><td>$(H $r.Command)</td></tr>")
}

$when = Get-Date -Format 'yyyy-MM-dd HH:mm'
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Ready ≠ Ran report</title>
<style>
body { font-family: Segoe UI, sans-serif; margin: 24px; color: #222; }
h1 { margin-bottom: 8px; }
.sub { color: #555; margin-bottom: 20px; }
table { border-collapse: collapse; width: 100%; font-size: 14px; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: left; vertical-align: top; }
th { background: #f4f4f4; }
</style>
</head>
<body>
<h1>Ready ≠ Ran</h1>
<p class="sub">$when · $(H $summary) · This report only looks. It does not change jobs.</p>
<table>
<thead>
<tr><th>Name</th><th>Folder</th><th>Windows status</th><th>Verdict</th><th>Last run</th><th>Next run</th><th>What Windows stored</th><th>Missed</th><th>Skip risks</th><th>Command</th></tr>
</thead>
<tbody>
$($tr.ToString())
</tbody>
</table>
</body>
</html>
"@

Set-Content -Path $htmlPath -Value $html -Encoding UTF8

Write-Host "Jobs checked: $($rows.Count)"
Write-Host $summary
Write-Host "HTML: $htmlPath"
Write-Host "CSV:  $csvPath"

try { Invoke-Item $htmlPath } catch { }
