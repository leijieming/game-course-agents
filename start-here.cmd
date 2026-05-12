@echo off
setlocal

chcp 65001 >nul
set "SCRIPT_DIR=%~dp0"
set "INSTALLER=%~dp0install.ps1"

title Game Course Agents Installer
echo.
echo ========================================
echo  Game Course Agents one-click installer
echo ========================================
echo.
echo Folder: %SCRIPT_DIR%
echo.

if not exist "%INSTALLER%" (
  echo [FAIL] install.ps1 was not found next to this launcher.
  echo Put start-here.cmd in the same folder as install.ps1, then try again.
  echo.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%" %*
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
  echo [PASS] Installer finished.
) else (
  echo [FAIL] Installer exited with code %EXIT_CODE%.
)
echo.
pause
exit /b %EXIT_CODE%
