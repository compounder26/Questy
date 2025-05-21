#!/bin/bash

# Exit on error
set -e

echo "===== Questy Automated Goal Testing Script ====="
echo "This script will run automated tests to create and complete goals."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
  echo "Error: Flutter is not installed or not in PATH"
  exit 1
fi

# Get a list of available devices
echo "Checking for available devices..."
flutter devices

echo ""
echo "Select a device to run the tests on (enter the device ID shown above):"
read device_id

if [ -z "$device_id" ]; then
  echo "No device ID entered. Exiting."
  exit 1
fi

echo "Running automated goal test on device: $device_id"
echo ""

# Run the test script
flutter run -d "$device_id" test/automated_goal_script.dart

echo ""
echo "===== Test execution completed =====" 