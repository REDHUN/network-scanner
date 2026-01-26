# First Time Location Permission Guide

## Overview

The app now includes a first-time launch location permission system that automatically requests location permission only when the user opens the app for the very first time. **Once the user interacts with the permission screen (either grants or skips), it will never show again automatically.**

## How It Works

### 1. First Time Launch Detection
- The app tracks whether it's the first time being launched using `SharedPreferences`
- Key: `is_first_time_launch` (defaults to `true`)
- Additional tracking: `has_been_asked_on_first_launch` (defaults to `false`)
- Once the user interacts with the permission screen, both flags are updated

### 2. Permission Flow
1. **App Launch**: App checks if it's first time launch AND user hasn't been asked yet
2. **WiFi Check**: Ensures WiFi is connected first
3. **Permission Screen**: Shows location permission screen only on first launch if user hasn't been asked
4. **User Interaction**: User either grants permission or skips
5. **Mark as Asked**: App marks that user has been asked on first launch
6. **Mark as Launched**: App is marked as no longer first-time launch

### 3. Key Components

#### PermissionPreferencesService
- `isFirstTimeLaunch()`: Check if this is first time launch
- `hasBeenAskedOnFirstLaunch()`: Check if user has been asked on first launch
- `setAppLaunched()`: Mark app as launched (no longer first time)
- `setAskedOnFirstLaunch()`: Mark that user has been asked on first launch
- `resetFirstTimeLaunch()`: Reset both flags for testing (debug only)

#### PermissionManager
- `shouldShowLocationPermissionScreen()`: Enhanced logic that checks:
  1. Permission not already granted
  2. User hasn't chosen "don't show again"
  3. Is first time launch AND user hasn't been asked yet

#### AppWrapper
- Handles the permission screen display logic
- Shows permission screen between WiFi check and main app

#### LocationPermissionScreen
- Automatically marks app as launched AND asked when user interacts
- Works for both "Grant Permission" and "Skip" actions
- Ensures the screen won't show again after any interaction

## Testing the Feature

### Debug Options in Settings
1. Open the app and go to Settings
2. Tap on "DEBUG OPTIONS" to expand debug menu
3. Use these options:
   - **Reset First Time Launch**: Resets both first-time and asked flags
   - **Show Permission Status**: View current permission state including new flag
   - **Clear All Preferences**: Reset all permission preferences

### Testing Steps
1. Install the app fresh OR use "Clear All Preferences" in debug menu
2. Restart the app completely
3. The location permission screen should appear after WiFi connection
4. **Grant or skip permission** (either action will prevent it from showing again)
5. Restart the app again - permission screen should **NOT appear**
6. Even if you uninstall and reinstall, the permission screen will only show once per fresh install

## Technical Implementation

### Files Modified
- `lib/service/permission_preferences_service/permission_preferences_service.dart`
- `lib/service/permission_manager/permission_manager.dart`
- `lib/view/location_permission_screen/location_permission_screen.dart`
- `lib/view/app_wrapper/app_wrapper.dart`
- `lib/view/settings_screen/settings_screen.dart`

### Key Methods Added
```dart
// Check first time launch
Future<bool> isFirstTimeLaunch()

// Check if asked on first launch
Future<bool> hasBeenAskedOnFirstLaunch()

// Mark app as launched
Future<void> setAppLaunched()

// Mark as asked on first launch
Future<void> setAskedOnFirstLaunch()

// Reset for testing (resets both flags)
Future<void> resetFirstTimeLaunch()
```

## User Experience

### First Time Users
- See permission screen immediately after WiFi connection
- Clear explanation of why location permission is needed
- Option to grant or skip with "Don't show again" checkbox
- **Any interaction (grant/skip) ensures screen won't show again**

### Returning Users
- **No permission screen interruption ever**
- Can still access permission settings through app features if needed
- Smooth app startup experience

## Benefits

1. **Truly One-Time**: Only shows once per app installation
2. **User Respect**: Any user choice (grant/skip) is permanently respected
3. **Non-intrusive**: Never interrupts returning users
4. **User Choice**: Clear grant/skip options
5. **Testable**: Debug options for development
6. **Contextual**: Shows after WiFi connection when relevant

## Logic Flow

```
App Launch
    ↓
Is Permission Granted? → YES → Skip Permission Screen
    ↓ NO
User Chose "Don't Show Again"? → YES → Skip Permission Screen
    ↓ NO
Is First Time Launch? → NO → Skip Permission Screen
    ↓ YES
Has Been Asked On First Launch? → YES → Skip Permission Screen
    ↓ NO
Show Permission Screen
    ↓
User Interacts (Grant/Skip)
    ↓
Set Asked On First Launch = TRUE
Set App Launched = TRUE
    ↓
Never Show Again (unless user explicitly requests through app features)
```

## Notes

- Permission screen only appears if WiFi is connected
- If permission is already granted, screen is skipped
- Debug options are hidden by default in settings
- All preferences are stored locally using SharedPreferences
- **The screen will never show again after first interaction, regardless of user choice**