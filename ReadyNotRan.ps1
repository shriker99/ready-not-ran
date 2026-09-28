# Ready ≠ Ran — read-only night-job checker
# Looks for 28 real traps. Does not change scheduled tasks.
# Writes HTML + CSV under .\out

[CmdletBinding()]
param(
    [switch]$IncludeMicrosoft
)

$ErrorActionPreference = 'Continue'

$Catalog = [ordered]@{
    '01 History off'              = 'Task History is off, so failed nights leave no trail.'
    '02 Wake timers blocked'      = 'Windows power settings may refuse to wake the PC.'
    '03 Connected sleep'          = 'Modern Standby can swallow the alarm clock.'
    '04 Scheduler service sick'   = 'If the Task Scheduler service is stopped, every job is theater.'
    '05 Laptop defaults'          = 'This PC has a battery. Night jobs inherit battery-protection defaults.'
    '06 Ready ≠ finished'         = 'A clean last result only means the program exited. It can still have done no work.'
    '07 Never ran'                = 'On the list. Has not fired.'
    '08 Turned off'               = 'The job is disabled. The library can still show it.'
    '09 Missed nights'            = 'The clock time passed and nothing caught up.'
    '10 Will not wake PC'         = 'Wake-the-computer is off. Sleeping laptops skip the job.'
    '11 Wall power only'          = 'Will not start on battery. Default on most jobs.'
    '12 Dies on unplug'           = 'A long run is killed if the plug comes out.'
    '13 Waits for idle'           = 'Touch the mouse and the job is skipped.'
    '14 Stops when you return'    = 'Idle ended, job killed mid-work.'
    '15 No catch-up'              = 'A missed slot is gone until the next scheduled time.'
    '16 Stale or limited login'   = 'Saved password is wrong, or this login type cannot see the network.'
    '17 Only while logged on'     = 'Overnight work dies at sign-out.'
    '18 Bad path or Start-in'     = 'Program path or Start-in folder is missing. Often runs from System32 by accident.'
    '19 Mapped drive letter'      = 'H: and Z: often do not exist when nobody is logged in.'
    '20 Hidden'                   = 'Easy to forget the job exists.'
    '21 Needs a network'          = 'No Wi-Fi or VPN, job skipped.'
    '22 Time cap too short'       = 'Windows may kill the job before the work finishes.'
    '23 No retry after fail'      = 'One miss, then silence.'
    '24 Second copy ignored'      = 'If last night is still marked Running, tonight is thrown away.'
    '25 Dead clock'               = 'Every trigger is off, or the end date already passed.'
    '26 Maintenance window only'  = 'Waits for an automatic-maintenance window you never see.'
    '27 Stuck Running'            = 'Last start never came back.'
    '28 Windows refused the run'  = 'A condition box blocked it. The script may never have started.'
}

function Get-ResultWords {
    param([int]$Code)
    switch ([uint32]$Code) {
        0          { 'Windows says the program finished cleanly' }
        267008     { 'Waiting for the next scheduled time' }
        267009     { 'Still running' }
        267010     { 'Disabled' }
        267011     { 'Has not run yet' }
        267012     { 'No more times left on the schedule' }
        267014     { 'Stopped by a person' }
        2147942402 { 'File or program path not found' }
        2147942667 { 'Start-in folder does not exist' }
        2147943645 { 'Saved login is wrong or expired' }
        2147943726 { 'Logon failed' }
        2147943203 { 'Already running, new start ignored' }
        2147946720 { 'A start condition was not met' }
        3221225786 { 'The program was closed while running' }
        default    { "Windows code $Code" }
    }
}

function Test-RefusedCode {
    param([int]$Code)
    $u = [uint32]$Code
    return ($u -in 2147943203, 2147946720, 2147943645, 2147943726, 2147942402, 2147942667)
}

function Get-PowerHints {
    $hints = @{
        OnBattery     = $false
        BatterySaver  = $false
        HasBattery    = $false
        ModernStandby = $false
        WakeBlocked   = $false
    }
    try {
        $bat = @(Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue)
        if ($bat.Count -gt 0) { $hints.HasBattery = $true }
    } catch { }
    try {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class RnrPower {
  [StructLayout(LayoutKind.Sequential)]
  public struct SYSTEM_POWER_STATUS {
    public byte ACLineStatus;
    public byte BatteryFlag;
    public byte BatteryLifePercent;
    public byte SystemStatusFlag;
    public int BatteryLifeTime;
    public int BatteryFullLifeTime;
  }
  [DllImport("kernel32.dll")]
  public static extern bool GetSystemPowerStatus(out SYSTEM_POWER_STATUS sps);
}
'@ -ErrorAction SilentlyContinue
        $sps = New-Object RnrPower+SYSTEM_POWER_STATUS
        if ([RnrPower]::GetSystemPowerStatus([ref]$sps)) {
            if ($sps.ACLineStatus -eq 0) { $hints.OnBattery = $true }
            if ($sps.SystemStatusFlag -eq 1) { $hints.BatterySaver = $true }
            if ($sps.BatteryFlag -ne 128 -and $sps.BatteryFlag -ne 255) { $hints.HasBattery = $true }
        }
    } catch { }
    try {
        $avail = powercfg /a 2>$null | Out-String
        if ($avail -match 'Standby \(S0') { $hints.ModernStandby = $true }
        if ($avail -match 'unavailable' -and $avail -match 'Standby') { $hints.WakeBlocked = $true }
    } catch { }
    try {
        $wt = powercfg /waketimers 2>$null | Out-String
        if ($wt -match 'disabled' -or $wt -match 'not enabled') { $hints.WakeBlocked = $true }
    } catch { }
    return $hints
}

function Get-HistoryOn {
    try {
        $log = Get-WinEvent -ListLog 'Microsoft-Windows-TaskScheduler/Operational' -ErrorAction Stop
        return [bool]$log.IsEnabled
    } catch {
        return $null
    }
}

function Resolve-ExistingPath {
    param([string]$PathText)
    if ([string]::IsNullOrWhiteSpace($PathText)) { return $true }
    $p = $PathText.Trim().Trim('"')
    if ($p -match '^[A-Za-z]:\' ) {
        return (Test-Path -LiteralPath $p)
    }
    if ($p -match '^\\') {
        return $true
    }
    try {
        $cmd = Get-Command $p -ErrorAction SilentlyContinue
        if ($cmd) { return $true }
    } catch { }
    return $true
}

function Get-MachineHits {
    param($Power, $HistoryOn, $ServiceStatus)
    $hits = @()
    if ($HistoryOn -eq $false) { $hits += '01 History off' }
    if ($Power.WakeBlocked) { $hits += '02 Wake timers blocked' }
    if ($Power.ModernStandby) { $hits += '03 Connected sleep' }
    if ($ServiceStatus -and $ServiceStatus -ne 'Running') { $hits += '04 Scheduler service sick' }
    if ($Power.HasBattery) { $hits += '05 Laptop defaults' }
    return $hits
}

function Get-JobHits {
    param($Task, $Info, $Power)
    $hits = New-Object System.Collections.Generic.List[string]
    $settings = $Task.Settings
    $principal = $Task.Principal
    $result = 0
    try { $result = [int]$Info.LastTaskResult } catch { $result = 0 }
    $missed = 0
    try { $missed = [int]$Info.NumberOfMissedRuns } catch { $missed = 0 }
    $lastRun = $Info.LastRunTime
    $never = -not $lastRun -or $lastRun.Year -lt 2000 -or $result -eq 267011

    $exec = @()
    $args = @()
    $startIn = @()
    foreach ($a in @($Task.Actions)) {
        if ($a.Execute) { $exec += [string]$a.Execute }
        if ($a.Arguments) { $args += [string]$a.Arguments }
        if ($a.WorkingDirectory) { $startIn += [string]$a.WorkingDirectory }
    }
    $joined = (($exec + $args) -join ' ')

    $cmdHides = $false
    foreach ($e in $exec) {
        if ($e -match 'powershell' -or $e -match 'pwsh') {
            foreach ($g in $args) {
                if ($g -match '(?i)(^|\s)-Command(\s|$)|(^|\s)-c(\s|$)|\s-Enc') { $cmdHides = $true }
            }
        }
        if ($e -match '(?i)cmd(\.exe)?$') {
            foreach ($g in $args) {
                if ($g -match '(?i)/c') { $cmdHides = $true }
            }
        }
    }

    if ($result -eq 0 -and -not $never -and $cmdHides) { $hits.Add('06 Ready ≠ finished') }
    elseif ($result -eq 0 -and -not $never) { $hits.Add('06 Ready ≠ finished') }

    if ($never) { $hits.Add('07 Never ran') }
    if ($Task.State -eq 'Disabled' -or $settings.Enabled -eq $false) { $hits.Add('08 Turned off') }
    if ($missed -gt 0) { $hits.Add('09 Missed nights') }
    if (-not $settings.WakeToRun) { $hits.Add('10 Will not wake PC') }
    if ($settings.DisallowStartIfOnBatteries) { $hits.Add('11 Wall power only') }
    if ($settings.StopIfGoingOnBatteries) { $hits.Add('12 Dies on unplug') }
    if ($settings.RunOnlyIfIdle) { $hits.Add('13 Waits for idle') }
    try {
        if ($settings.IdleSettings -and $settings.IdleSettings.StopOnIdleEnd) { $hits.Add('14 Stops when you return') }
    } catch { }
    if (-not $settings.StartWhenAvailable) { $hits.Add('15 No catch-up') }

    $logon = [string]$principal.LogonType
    if ($result -in 2147943645, 2147943726) { $hits.Add('16 Stale or limited login') }
    elseif ($logon -eq 'Password' -or $logon -eq 'S4U') { $hits.Add('16 Stale or limited login') }

    if ($logon -eq 'Interactive' -or $logon -eq 'InteractiveToken' -or $logon -eq 'Group') {
        $hits.Add('17 Only while logged on')
    }

    $badPath = $false
    foreach ($e in $exec) {
        $clean = $e.Trim().Trim('"')
        if ($clean -match '^[A-Za-z]:\' -and -not (Test-Path -LiteralPath $clean)) { $badPath = $true }
    }
    foreach ($w in $startIn) {
        $clean = $w.Trim().Trim('"')
        if ($clean -and -not (Test-Path -LiteralPath $clean)) { $badPath = $true }
    }
    if ($startIn.Count -eq 0 -and $joined -match '(?i)\.ps1|\.bat|\.cmd|\.vbs') { $badPath = $true }
    if ($badPath) { $hits.Add('18 Bad path or Start-in') }

    if ($joined -match '(?i)(^|[^A-Za-z])[H-Z]:\') { $hits.Add('19 Mapped drive letter') }

    if ($settings.Hidden) { $hits.Add('20 Hidden') }
    if ($settings.RunOnlyIfNetworkAvailable) { $hits.Add('21 Needs a network') }

    try {
        $limit = $settings.ExecutionTimeLimit
        if ($limit -and $limit.TotalSeconds -gt 0 -and $limit.TotalMinutes -lt 15) {
            $hits.Add('22 Time cap too short')
        }
    } catch { }

    $restartCount = 0
    try { $restartCount = [int]$settings.RestartCount } catch { $restartCount = 0 }
    if ($result -ne 0 -and -not $never -and $restartCount -le 0) { $hits.Add('23 No retry after fail') }

    $multi = [string]$settings.MultipleInstances
    if ($multi -match 'Ignore' -or $multi -eq 'IgnoreNew') { $hits.Add('24 Second copy ignored') }

    $triggers = @($Task.Triggers)
    $deadClock = $false
    if ($triggers.Count -eq 0) {
        $deadClock = $true
    } else {
        $anyLive = $false
        foreach ($tr in $triggers) {
            $on = $true
            try { if ($tr.Enabled -eq $false) { $on = $false } } catch { }
            $ended = $false
            try {
                if ($tr.EndBoundary) {
                    $end = [datetime]$tr.EndBoundary
                    if ($end -lt (Get-Date)) { $ended = $true }
                }
            } catch { }
            if ($on -and -not $ended) { $anyLive = $true }
        }
        if (-not $anyLive) { $deadClock = $true }
    }
    if ($deadClock) { $hits.Add('25 Dead clock') }

    try {
        if ($settings.MaintenanceSettings) { $hits.Add('26 Maintenance window only') }
    } catch { }

    if ($Task.State -eq 'Running' -or $result -eq 267009) { $hits.Add('27 Stuck Running') }
    if (Test-RefusedCode $result) { $hits.Add('28 Windows refused the run') }

    return @($hits | Select-Object -Unique)
}

function Get-Verdict {
    param($Hits)
    if ($Hits -contains '08 Turned off') { return 'Disabled' }
    if ($Hits -contains '28 Windows refused the run' -and $Hits -contains '07 Never ran') { return 'Failed' }
    if ($Hits -contains '07 Never ran') { return 'Never ran' }
    if ($Hits -contains '09 Missed nights') { return 'Missed' }
    if ($Hits -contains '28 Windows refused the run') { return 'Failed' }
    if ($Hits -contains '27 Stuck Running') { return 'Failed' }
    $failish = $Hits | Where-Object { $_ -match '^23 ' }
    if ($failish) { return 'Failed' }
    if ($Hits.Count -gt 0) { return 'May skip' }
    return 'Looks OK'
}

function H([string]$s) {
    if ($null -eq $s) { return '' }
    ((($s -replace '&', '&') -replace '<', '<') -replace '>', '>') -replace '"', '"'
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

$power = Get-PowerHints
$historyOn = Get-HistoryOn
$svc = $null
try { $svc = [string](Get-Service Schedule -ErrorAction Stop).Status } catch { $svc = 'Unknown' }
$machineHits = Get-MachineHits -Power $power -HistoryOn $historyOn -ServiceStatus $svc

$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
if (-not $IncludeMicrosoft) {
    $tasks = @($tasks | Where-Object { $_.TaskPath -notlike '\Microsoft\*' })
}

$rows = @()
$hitCounts = @{}
foreach ($key in $Catalog.Keys) { $hitCounts[$key] = 0 }
foreach ($h in $machineHits) { $hitCounts[$h]++ }

foreach ($t in $tasks) {
    try { $info = Get-ScheduledTaskInfo -InputObject $t -ErrorAction Stop }
    catch { continue }

    $hits = Get-JobHits -Task $t -Info $info -Power $power
    foreach ($h in $hits) { if ($hitCounts.ContainsKey($h)) { $hitCounts[$h]++ } }

    $actions = @()
    foreach ($a in @($t.Actions)) {
        $line = [string]$a.Execute
        if ($a.Arguments) { $line = ($line + ' ' + [string]$a.Arguments).Trim() }
        if ($line) { $actions += $line }
    }

    $lastRun = $info.LastRunTime
    $nextRun = $info.NextRunTime
    $result = 0
    try { $result = [int]$info.LastTaskResult } catch { }
    $missed = 0
    try { $missed = [int]$info.NumberOfMissedRuns } catch { }

    $rows += [pscustomobject]@{
        Name         = $t.TaskName
        Folder       = $t.TaskPath
        Status       = [string]$t.State
        Verdict      = Get-Verdict $hits
        LastRun      = if ($lastRun -and $lastRun.Year -ge 2000) { $lastRun.ToString('yyyy-MM-dd HH:mm') } else { 'never' }
        NextRun      = if ($nextRun -and $nextRun.Year -ge 2000) { $nextRun.ToString('yyyy-MM-dd HH:mm') } else { 'none' }
        LastResult   = Get-ResultWords $result
        MissedNights = $missed
        Problems     = ($hits -join '; ')
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

$catalogRows = New-Object System.Text.StringBuilder
foreach ($key in $Catalog.Keys) {
    $n = [int]$hitCounts[$key]
    $tone = if ($n -gt 0) { '#fff4d6' } else { '#e7f6ec' }
    $mark = if ($n -gt 0) { "Found ($n)" } else { 'Clear' }
    [void]$catalogRows.Append("<tr style='background:$tone'><td>$(H $key)</td><td>$(H $Catalog[$key])</td><td><b>$(H $mark)</b></td></tr>")
}

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
    [void]$tr.Append("<tr style='background:$tone'><td>$(H $r.Name)</td><td>$(H $r.Folder)</td><td>$(H $r.Status)</td><td><b>$(H $r.Verdict)</b></td><td>$(H $r.LastRun)</td><td>$(H $r.NextRun)</td><td>$(H $r.LastResult)</td><td>$(H ([string]$r.MissedNights))</td><td>$(H $r.Problems)</td><td>$(H $r.Command)</td></tr>")
}

$counts = $rows | Group-Object Verdict | ForEach-Object { "$($_.Count) $($_.Name)" }
$summary = if ($counts) { $counts -join ' · ' } else { 'No jobs found' }
$pcLine = if ($machineHits.Count) { $machineHits -join ' · ' } else { 'No machine-wide traps found' }
$when = Get-Date -Format 'yyyy-MM-dd HH:mm'
$checked = $Catalog.Count

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
h2 { margin-top: 28px; }
table { border-collapse: collapse; width: 100%; font-size: 14px; margin-bottom: 16px; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: left; vertical-align: top; }
th { background: #f4f4f4; }
</style>
</head>
<body>
<h1>Ready ≠ Ran</h1>
<p class="sub">$when · $(H $summary) · $checked checks · This report only looks. It does not change jobs.</p>
<p><b>This PC:</b> $(H $pcLine)</p>
<h2>All checks</h2>
<table>
<thead><tr><th>Check</th><th>What it means</th><th>On this PC</th></tr></thead>
<tbody>
$($catalogRows.ToString())
</tbody>
</table>
<h2>Each job</h2>
<table>
<thead>
<tr><th>Name</th><th>Folder</th><th>Windows status</th><th>Verdict</th><th>Last run</th><th>Next run</th><th>What Windows stored</th><th>Missed</th><th>Problems found</th><th>Command</th></tr>
</thead>
<tbody>
$($tr.ToString())
</tbody>
</table>
</body>
</html>
"@

Set-Content -Path $htmlPath -Value $html -Encoding UTF8

Write-Host "Checks in catalog: $checked"
Write-Host "Jobs checked: $($rows.Count)"
Write-Host "This PC: $pcLine"
Write-Host $summary
Write-Host "HTML: $htmlPath"
Write-Host "CSV:  $csvPath"

try { Invoke-Item $htmlPath } catch { }
