@echo off
setlocal
cd /d "%~dp0"
echo Installing Ready Not Ran for this Windows user...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
if errorlevel 1 (
  echo Install did not finish.
  pause
  exit /b 1
)
echo.
pause
