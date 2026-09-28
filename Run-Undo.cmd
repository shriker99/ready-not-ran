@echo off
setlocal
cd /d "%~dp0"
echo This puts the old night-job settings back.
echo It will ask you to type YES first.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Undo-ReadyNotRan.ps1"
if errorlevel 1 pause
