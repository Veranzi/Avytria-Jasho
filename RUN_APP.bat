@echo off
color 0A
echo ================================================
echo    JASHO APP - COMPLETE STARTUP
echo ================================================
echo.

echo [1/3] Starting Backend Server...
echo Opening new window for backend...
start "Jasho Backend Server" cmd /k "cd /d %~dp0python-backend && echo Starting Python Backend... && python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

echo.
echo [2/3] Waiting 8 seconds for backend to initialize...
timeout /t 8 /nobreak

echo.
echo [3/3] Starting Flutter App on Chrome...
cd /d %~dp0jashoo
echo Building Flutter app for web...
flutter run -d chrome

echo.
echo ================================================
echo    App should be running in Chrome now!
echo    Backend: http://localhost:8000
echo    API Docs: http://localhost:8000/docs
echo ================================================
pause

