# Questy Automated Goal Testing Script for Windows
Write-Host "===== Questy Automated Goal Testing Script =====" -ForegroundColor Cyan
Write-Host "This script will run automated tests to create and complete goals." -ForegroundColor Cyan
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
Write-Host "Select a device to run the tests on (enter the device ID shown above):" -ForegroundColor Green
$deviceId = Read-Host

if ([string]::IsNullOrEmpty($deviceId)) {
    Write-Host "No device ID entered. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "Running automated goal test on device: $deviceId" -ForegroundColor Yellow
Write-Host ""

# Run the test script
try {
    flutter run -d "$deviceId" test/automated_goal_script.dart
}
catch {
    Write-Host "Error running the test script: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "===== Test execution completed =====" -ForegroundColor Cyan 