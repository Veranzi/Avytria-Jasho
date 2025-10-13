@echo off
echo ================================================
echo   Starting Jasho Backend Server
echo ================================================
echo.

cd /d "%~dp0python-backend"

echo [1/3] Activating virtual environment...
call "%~dp0.venv\Scripts\activate.bat"

echo [2/3] Starting backend on http://localhost:8000...
echo.
echo Press CTRL+C to stop the server
echo ================================================
echo.

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

pause

