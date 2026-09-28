# Ready ≠ Ran — put the old settings back from the last spare copy

[CmdletBinding()]
param([switch]$Yes)

$ErrorActionPreference = 'Continue'
$latest = Join-Path $env:LOCALAPPDATA 'ReadyNotRan\backups\LATEST.txt'
if (-not (Test-Path -LiteralPath $latest)) {
    Write-Host 'No spare copy was found. Run the fixer first.'
    exit 1
}
$dir = (Get-Content -LiteralPath $latest -TotalCount 1).Trim()
if (-not (Test-Path -LiteralPath $dir)) {
    Write-Host 'The spare copy folder is missing.'
    exit 1
}

if (-not $Yes) {
    Write-Host "This puts back the jobs saved in:`n$dir"
    $answer = Read-Host 'Type YES to put the old settings back'
    if ($answer -ne 'YES') {
        Write-Host 'No changes were made.'
        exit 0
    }
}

$ok = 0
$bad = 0
Get-ChildItem -LiteralPath $dir -Filter '*.xml' | ForEach-Object {
    try {
        $xml = Get-Content -LiteralPath $_.FullName -Raw
        # Task name is the file stem after the last underscore-ish path; use XML instead
        $doc = [xml]$xml
        $name = $doc.Task.RegistrationInfo.URI
        if (-not $name) { throw 'Could not read job name from the spare copy.' }
        Register-ScheduledTask -Xml $xml -TaskName (Split-Path $name -Leaf) -TaskPath ((Split-Path $name -Parent) + '\') -Force -ErrorAction Stop | Out-Null
        $ok++
        Write-Host "Restored $name"
    }
    catch {
        $bad++
        Write-Host ("Could not restore " + $_.Name + ": " + $_.Exception.Message)
    }
}
Write-Host "Put back: $ok  Could not: $bad"
