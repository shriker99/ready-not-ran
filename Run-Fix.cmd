@echo off
setlocal
cd /d "%~dp0"
echo Ready Not Ran will fix the easy settings on this PC.
echo It will ask you to type YES first.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-ReadyNotRan.ps1"
if errorlevel 1 pause
