import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class PermissionPreferencesService {
  static const String _dontShowLocationWarningKey =
      'dont_show_location_warning';
  static const String _locationPermissionAskedKey = 'location_permission_asked';
  static const String _locationPermissionDeniedCountKey =
      'location_permission_denied_count';
  static const String _isFirstTimeLaunchKey = 'is_first_time_launch';
  static const String _hasBeenAskedOnFirstLaunchKey =
      'has_been_asked_on_first_launch';

  /// Check if user has chosen "Don't show again" for location warning
  Future<bool> shouldShowLocationWarning() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dontShow = prefs.getBool(_dontShowLocationWarningKey) ?? false;
      return !dontShow;
    } catch (e) {
      log('Error checking location warning preference: $e');
      return true; // Default to showing warning
    }
  }

  /// Set user preference to not show location warning again
  Future<void> setDontShowLocationWarning(bool dontShow) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dontShowLocationWarningKey, dontShow);
      log('Set dont show location warning: $dontShow');
    } catch (e) {
      log('Error setting location warning preference: $e');
    }
  }

  /// Check if location permission has been asked before
  Future<bool> hasLocationPermissionBeenAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_locationPermissionAskedKey) ?? false;
    } catch (e) {
      log('Error checking location permission asked status: $e');
      return false;
    }
  }

  /// Mark that location permission has been asked
  Future<void> setLocationPermissionAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationPermissionAskedKey, true);
      log('Marked location permission as asked');
    } catch (e) {
      log('Error setting location permission asked status: $e');
    }
  }

  /// Get the number of times location permission has been denied
  Future<int> getLocationPermissionDeniedCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_locationPermissionDeniedCountKey) ?? 0;
    } catch (e) {
      log('Error getting location permission denied count: $e');
      return 0;
    }
  }

  /// Increment the location permission denied count
  Future<void> incrementLocationPermissionDeniedCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = await getLocationPermissionDeniedCount();
      await prefs.setInt(_locationPermissionDeniedCountKey, currentCount + 1);
      log(
        'Incremented location permission denied count to: ${currentCount + 1}',
      );
    } catch (e) {
      log('Error incrementing location permission denied count: $e');
    }
  }

  /// Reset location permission denied count (when permission is granted)
  Future<void> resetLocationPermissionDeniedCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_locationPermissionDeniedCountKey, 0);
      log('Reset location permission denied count');
    } catch (e) {
      log('Error resetting location permission denied count: $e');
    }
  }

  /// Clear all permission preferences (for reset/debugging)
  Future<void> clearAllPermissionPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dontShowLocationWarningKey);
      await prefs.remove(_locationPermissionAskedKey);
      await prefs.remove(_locationPermissionDeniedCountKey);
      await prefs.remove(_isFirstTimeLaunchKey);
      await prefs.remove(_hasBeenAskedOnFirstLaunchKey);
      log('Cleared all permission preferences');
    } catch (e) {
      log('Error clearing permission preferences: $e');
    }
  }

  /// Get permission summary for debugging
  Future<Map<String, dynamic>> getPermissionSummary() async {
    return {
      'shouldShowWarning': await shouldShowLocationWarning(),
      'hasBeenAsked': await hasLocationPermissionBeenAsked(),
      'deniedCount': await getLocationPermissionDeniedCount(),
      'isFirstTimeLaunch': await isFirstTimeLaunch(),
      'hasBeenAskedOnFirstLaunch': await hasBeenAskedOnFirstLaunch(),
    };
  }

  /// Check if this is the first time the app is launched
  Future<bool> isFirstTimeLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isFirstTimeLaunchKey) ?? true;
    } catch (e) {
      log('Error checking first time launch status: $e');
      return true; // Default to first time launch
    }
  }

  /// Mark that the app has been launched (no longer first time)
  Future<void> setAppLaunched() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isFirstTimeLaunchKey, false);
      log('Marked app as launched (no longer first time)');
    } catch (e) {
      log('Error setting app launched status: $e');
    }
  }

  /// Reset first time launch status (for testing/debugging)
  Future<void> resetFirstTimeLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isFirstTimeLaunchKey, true);
      await prefs.setBool(_hasBeenAskedOnFirstLaunchKey, false);
      log('Reset first time launch status and asked status');
    } catch (e) {
      log('Error resetting first time launch status: $e');
    }
  }

  /// Check if user has been asked for permission on first launch
  Future<bool> hasBeenAskedOnFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasBeenAskedOnFirstLaunchKey) ?? false;
    } catch (e) {
      log('Error checking first launch asked status: $e');
      return false;
    }
  }

  /// Mark that user has been asked for permission on first launch
  Future<void> setAskedOnFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasBeenAskedOnFirstLaunchKey, true);
      log('Marked as asked on first launch');
    } catch (e) {
      log('Error setting first launch asked status: $e');
    }
  }
}
