# Common Snackbar Usage Guide

## Overview
The `SnackbarUtils` class provides a consistent snackbar experience across all screens using the app's primary color `Color(0xFF2C2C2E)`.

## Import
```dart
import 'package:ip_tools/common/utils/snackbar_utils.dart';
```

## Available Methods

### 1. Success Snackbar
```dart
SnackbarUtils.showSuccess(context, 'Operation completed successfully!');
```
- **Color**: Dark background with white checkmark icon
- **Use for**: Successful operations, confirmations

### 2. Error Snackbar
```dart
SnackbarUtils.showError(context, 'Something went wrong!');
```
- **Color**: Dark background with red error icon
- **Use for**: Errors, failures, exceptions

### 3. Info Snackbar
```dart
SnackbarUtils.showInfo(context, 'Information message');
```
- **Color**: Dark background with golden accent icon
- **Use for**: General information, status updates

### 4. Warning Snackbar
```dart
SnackbarUtils.showWarning(context, 'Please check your settings');
```
- **Color**: Dark background with orange warning icon
- **Use for**: Warnings, cautions, important notices

### 5. Copy Success (Specialized)
```dart
SnackbarUtils.showCopySuccess(context, 'IP Address');
// Shows: "IP Address copied to clipboard"
```
- **Use for**: Copy operations

### 6. Custom Snackbar
```dart
SnackbarUtils.showCustom(
  context,
  'Custom message',
  icon: Icons.star,
  iconColor: Colors.purple,
);
```

### 7. Simple Snackbar (No Icon)
```dart
SnackbarUtils.showSimple(context, 'Simple message');
```

## Design Features

### Consistent Styling
- **Background**: `Color(0xFF2C2C2E)` (App's primary dark color)
- **Text**: White, 14px, medium weight
- **Shape**: Rounded corners (12px radius)
- **Behavior**: Floating with 16px margin
- **Elevation**: 8px shadow

### Icons
- **Success**: White checkmark
- **Error**: Red error icon
- **Info**: Golden accent info icon
- **Warning**: Orange warning icon
- **Custom**: User-defined icon and color

## Usage Examples

### Copy Functionality
```dart
Future<void> _copyToClipboard(String value, String label) async {
  try {
    await Clipboard.setData(ClipboardData(text: value));
    SnackbarUtils.showCopySuccess(context, label);
  } catch (e) {
    SnackbarUtils.showError(context, 'Failed to copy: $e');
  }
}
```

### Network Operations
```dart
// Success
SnackbarUtils.showSuccess(context, 'Network scan completed');

// Error
SnackbarUtils.showError(context, 'Network scan failed');

// Info
SnackbarUtils.showInfo(context, 'Scanning network...');

// Warning
SnackbarUtils.showWarning(context, 'Location permission required');
```

### Share Operations
```dart
try {
  await shareService.shareData();
  SnackbarUtils.showSuccess(context, 'Data shared successfully');
} catch (e) {
  SnackbarUtils.showError(context, 'Failed to share: $e');
}
```

## Migration from Old Snackbars

### Before (Old Way)
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Icon(Icons.check_circle, color: Colors.white, size: 20),
        SizedBox(width: 12),
        Text('Success message'),
      ],
    ),
    backgroundColor: Color(0xFF30A46C),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);
```

### After (New Way)
```dart
SnackbarUtils.showSuccess(context, 'Success message');
```

## Benefits

1. **Consistency**: All snackbars use the same styling and colors
2. **Maintainability**: Easy to update styling across the entire app
3. **Simplicity**: One-line method calls instead of complex SnackBar widgets
4. **App Branding**: Uses the app's primary color scheme
5. **Type Safety**: Predefined methods for common use cases
6. **Mounted Check**: Built-in context.mounted checks for safety

## Updated Files

The following files have been updated to use the common snackbar utility:
- ✅ `lib/view/homescreen/homescreen.dart`
- ✅ `lib/view/devices_screen/devices_screen.dart`
- ✅ `lib/view/location_permission_screen/location_permission_screen.dart`
- ✅ `lib/view/router_history_screen/router_history_screen.dart`
- ✅ `lib/view/device_details_screen/device_details_screen.dart`

All snackbars now use the consistent `Color(0xFF2C2C2E)` background with appropriate icon colors for different message types.