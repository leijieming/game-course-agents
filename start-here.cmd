@echo off
setlocal

chcp 65001 >nul
set "SCRIPT_DIR=%~dp0"
set "START_MENU=%~dp0scripts\start-menu.ps1"

title Game Course Agents Installer
echo.
echo ========================================
echo  Game Course Agents setup menu
echo ========================================
echo.
echo Folder: %SCRIPT_DIR%
echo.

if not exist "%START_MENU%" (
  echo [FAIL] scripts\start-menu.ps1 was not found next to this launcher.
  echo Keep the repository folder intact, then try again.
  echo.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%START_MENU%" %*
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
  echo [PASS] Setup menu finished.
) else (
  echo [FAIL] Setup menu exited with code %EXIT_CODE%.
)
echo.
pause
exit /b %EXIT_CODE%
