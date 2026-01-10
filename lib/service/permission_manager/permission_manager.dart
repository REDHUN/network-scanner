import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ip_tools/service/permission_preferences_service/permission_preferences_service.dart';
import 'package:ip_tools/service/permission_service/permission_service.dart';
import 'package:ip_tools/view/location_permission_screen/location_permission_screen.dart';

class PermissionManager {
  static final _permissionService = PermissionService();
  static final _preferencesService = PermissionPreferencesService();

  /// Check if we should show the location permission screen
  static Future<bool> shouldShowLocationPermissionScreen() async {
    try {
      // Check if permission is already granted
      final isGranted = await _permissionService.isLocationPermissionGranted();
      if (isGranted) {
        log('Location permission already granted');
        return false;
      }

      // Check if user has chosen "don't show again"
      final shouldShow = await _preferencesService.shouldShowLocationWarning();
      if (!shouldShow) {
        log('User chose not to show location warning again');
        return false;
      }

      log('Should show location permission screen');
      return true;
    } catch (e) {
      log('Error checking if should show permission screen: $e');
      return true; // Default to showing if there's an error
    }
  }

  /// Show location permission screen as a modal
  static Future<bool?> showLocationPermissionScreen(
    BuildContext context,
  ) async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const LocationPermissionScreen(),
          fullscreenDialog: true,
        ),
      );

      log('Location permission screen result: $result');
      return result;
    } catch (e) {
      log('Error showing location permission screen: $e');
      return null;
    }
  }

  /// Show location permission screen as a replacement (for initial app launch)
  static Future<bool?> showLocationPermissionScreenReplacement(
    BuildContext context,
    Widget homeScreen,
  ) async {
    try {
      final result = await Navigator.of(context).pushReplacement<bool, void>(
        MaterialPageRoute(
          builder: (context) => LocationPermissionScreen(
            onPermissionGranted: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => homeScreen),
              );
            },
            onSkipped: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => homeScreen),
              );
            },
          ),
        ),
      );

      log('Location permission screen replacement result: $result');
      return result;
    } catch (e) {
      log('Error showing location permission screen replacement: $e');
      return null;
    }
  }

  /// Check and handle location permission on app startup
  static Future<void> handleLocationPermissionOnStartup(
    BuildContext context,
    Widget homeScreen,
  ) async {
    try {
      final shouldShow = await shouldShowLocationPermissionScreen();

      if (shouldShow) {
        log('Showing location permission screen on startup');
        await showLocationPermissionScreenReplacement(context, homeScreen);
      } else {
        log('Skipping location permission screen on startup');
      }
    } catch (e) {
      log('Error handling location permission on startup: $e');
    }
  }

  /// Quick permission check for features that require location
  static Future<bool> checkLocationPermissionForFeature(
    BuildContext context, {
    String? featureName,
    bool showDialogIfDenied = true,
  }) async {
    try {
      final isGranted = await _permissionService.isLocationPermissionGranted();

      if (isGranted) {
        return true;
      }

      if (showDialogIfDenied) {
        final shouldShow = await _preferencesService
            .shouldShowLocationWarning();

        if (shouldShow) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Permission Required'),
              content: Text(
                featureName != null
                    ? '$featureName requires location permission to access network information.'
                    : 'This feature requires location permission to access network information.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          );

          if (result == true) {
            return await showLocationPermissionScreen(context) ?? false;
          }
        }
      }

      return false;
    } catch (e) {
      log('Error checking location permission for feature: $e');
      return false;
    }
  }

  /// Get permission status summary for debugging
  static Future<Map<String, dynamic>> getPermissionStatusSummary() async {
    try {
      final isGranted = await _permissionService.isLocationPermissionGranted();
      final isPermanentlyDenied = await _permissionService
          .isLocationPermissionPermanentlyDenied();
      final statusString = await _permissionService
          .getLocationPermissionStatusString();
      final preferences = await _preferencesService.getPermissionSummary();

      return {
        'isGranted': isGranted,
        'isPermanentlyDenied': isPermanentlyDenied,
        'statusString': statusString,
        'preferences': preferences,
        'shouldShowScreen': await shouldShowLocationPermissionScreen(),
      };
    } catch (e) {
      log('Error getting permission status summary: $e');
      return {'error': e.toString()};
    }
  }

  /// Reset all permission preferences (for debugging/testing)
  static Future<void> resetPermissionPreferences() async {
    try {
      await _preferencesService.clearAllPermissionPreferences();
      log('Reset all permission preferences');
    } catch (e) {
      log('Error resetting permission preferences: $e');
    }
  }
}
