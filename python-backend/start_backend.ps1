Write-Host "========================================" -ForegroundColor Green
Write-Host "   Starting Jasho Python Backend" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Set-Location $PSScriptRoot

Write-Host "Checking Python installation..." -ForegroundColor Cyan
python --version

Write-Host ""
Write-Host "Installing/Updating dependencies..." -ForegroundColor Cyan
pip install -q -r requirements.txt

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "   Backend Starting on http://localhost:8000" -ForegroundColor Yellow
Write-Host "   API Docs: http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host "   Health Check: http://localhost:8000/health" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

