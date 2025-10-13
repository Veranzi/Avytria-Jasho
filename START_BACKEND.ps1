Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Starting Jasho Backend Server" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location "$scriptPath\python-backend"

Write-Host "[1/3] Activating virtual environment..." -ForegroundColor Yellow
& "$scriptPath\.venv\Scripts\Activate.ps1"

Write-Host "[2/3] Starting backend on http://localhost:8000..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press CTRL+C to stop the server" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

