@echo off
setlocal
cd /d "%~dp0"
if exist "%~dp0ReadyNotRan-UI.ps1" (
  powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0ReadyNotRan-UI.ps1"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ReadyNotRan.ps1"
)
if errorlevel 1 pause
