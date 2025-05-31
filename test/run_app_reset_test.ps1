# Questy App Reset Script for Windows
Write-Host "===== Questy App Reset Script =====" -ForegroundColor Cyan
Write-Host "This script will reset the app to a fresh install state, clearing all data." -ForegroundColor Cyan
Write-Host "WARNING: This will delete all habits, tasks, and user progress!" -ForegroundColor Yellow
Write-Host ""

# Check if Flutter is installed
try {
    $null = Get-Command flutter -ErrorAction Stop
}
catch {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Get a list of available devices
Write-Host "Checking for available devices..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "Select a device to run the reset on (enter the device ID shown above):" -ForegroundColor Green
$deviceId = Read-Host

if ([string]::IsNullOrEmpty($deviceId)) {
    Write-Host "No device ID entered. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "Running app reset script on device: $deviceId" -ForegroundColor Yellow
Write-Host "This will reset the app to a fresh install state!" -ForegroundColor Red
Write-Host ""

# Run the reset script
try {
    flutter run -d "$deviceId" test/app_reset_script.dart
}
catch {
    Write-Host "Error running the reset script: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "===== App reset completed =====" -ForegroundColor Cyan
