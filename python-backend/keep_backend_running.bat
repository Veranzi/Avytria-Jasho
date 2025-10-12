@echo off
:start
echo ========================================
echo   Jasho Backend - Auto-Restart Enabled
echo ========================================
echo.

cd /d "%~dp0"

echo Starting backend on port 8000...
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

echo.
echo Backend stopped. Restarting in 5 seconds...
echo Press CTRL+C to stop completely
timeout /t 5

goto start

