@echo off
title JASHO - Main Control
color 0A
cls

echo.
echo     ================================================
echo          JASHO APP - QUICK START  
echo     ================================================
echo.
echo     This will open 2 windows:
echo     [1] Backend Server (Python)
echo     [2] Flutter App (Chrome browser)
echo.
echo     ================================================
echo.
pause

REM Start Backend in new window
echo [*] Starting Backend Server...
start "JASHO BACKEND" cmd /k "cd /d %~dp0python-backend && color 0B && title JASHO BACKEND SERVER && echo. && echo ========================================== && echo    JASHO BACKEND SERVER && echo ========================================== && echo. && python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

echo [*] Waiting for backend to initialize (10 seconds)...
timeout /t 10 /nobreak > nul

REM Start Flutter
echo [*] Launching Flutter App on Chrome...
cd /d %~dp0jashoo
start "JASHO FLUTTER" cmd /k "color 0E && title JASHO FLUTTER APP && flutter run -d chrome"

echo.
echo ================================================
echo   DONE! Check the 2 windows that opened:
echo   1. JASHO BACKEND SERVER (blue)
echo   2. JASHO FLUTTER APP (yellow)
echo ================================================
echo.
echo Chrome should open automatically with your app!
echo.
pause
exit

