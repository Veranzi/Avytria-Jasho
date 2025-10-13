Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   STARTING JASHO FLUTTER APP" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location -Path "$PSScriptRoot\jashoo"

Write-Host "[*] Building Flutter app for Chrome..." -ForegroundColor Yellow
Write-Host "[*] Chrome will open automatically..." -ForegroundColor Yellow
Write-Host ""

flutter run -d chrome

