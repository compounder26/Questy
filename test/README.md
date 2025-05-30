# Questy Automated Testing

This directory contains automated test scripts for the Questy app, which allow you to create and complete goals programmatically without manual intervention.

## Available Tests

1. **Widget Tests**: Standard Flutter widget tests (widget_test.dart)
2. **Goal Creation and Completion Test**: Flutter test for creating and completing goals (goal_test.dart)
3. **Standalone Goal Test Script**: A script that can be run directly to create and complete multiple goals (automated_goal_script.dart)

## Required Dependencies

The automated tests use these dependencies that should already be in your pubspec.yaml:
- provider: For state management
- hive/hive_flutter: For data persistence
- uuid: For generating unique IDs
- path_provider: For file system access

If you're missing any dependencies, run:
```bash
flutter pub get
```

## Running the Automated Goal Tests

### Option 1: Using the Helper Scripts

#### For Unix/macOS/Linux:
1. Make the script executable: `chmod +x run_goal_tests.sh`
2. Run the script: `./run_goal_tests.sh`
3. When prompted, enter the device ID where you want to run the test

#### For Windows:
1. Open PowerShell
2. Navigate to the test directory: `cd path\to\questy\test`
3. Run the script: `.\run_goal_tests.ps1`
4. When prompted, enter the device ID where you want to run the test

### Option 2: Direct Command

If you prefer to run the test directly, use the following command:

```bash
flutter run -d <device_id> test/automated_goal_script.dart
```

Replace `<device_id>` with your actual device ID (get it by running `flutter devices`).

### Option 3: Run Flutter Tests

To run the standard Flutter tests:

```bash
flutter test
```

## What the Automated Goal Script Does

The automated goal script (automated_goal_script.dart):

1. Initializes the app environment
2. Creates 3 test goals, each with 3 tasks
3. Completes all tasks for each goal
4. Verifies that the goals are properly marked as completed
5. Reports the results

This is useful for:
- Testing the goal creation and completion functionality
- Checking for any issues with the Habit and HabitTask models
- Verifying that the database is working correctly
- Automating repetitive testing scenarios

## Customizing the Tests

You can modify the automated_goal_script.dart file to:
- Change the number of goals created
- Modify the types of tasks
- Simulate different user scenarios
- Test edge cases or specific features

## Troubleshooting

If you encounter issues:

1. Make sure you have all the required dependencies
2. Ensure the app is not already running on the target device
3. Check that Hive is properly initialized
4. Verify that you're using a valid device ID 