import 'dart:developer' as developer;
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  ReviewService._internal();
  static final ReviewService _instance = ReviewService._internal();
  static ReviewService get instance => _instance;

  final InAppReview _inAppReview = InAppReview.instance;

  static const String _keyScanCount = 'app_review_scan_count';
  static const String _keyLastPromptTime = 'app_review_last_prompt_time';

  /// Check if in-app review dialog is available on this platform/device
  Future<bool> isAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (e) {
      developer.log('Error checking in-app review availability: $e', name: 'ReviewService');
      return false;
    }
  }

  /// Request the native in-app review dialog from Google Play / App Store.
  /// Note: The OS/store decides whether to actually display the dialog.
  Future<void> requestReview() async {
    try {
      if (await isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      developer.log('Error requesting review: $e', name: 'ReviewService');
    }
  }

  /// Open the store listing directly (Google Play / App Store) for manual rating.
  Future<void> openStoreListing({String? appStoreId}) async {
    try {
      await _inAppReview.openStoreListing(appStoreId: appStoreId);
    } catch (e) {
      developer.log('Error opening store listing: $e', name: 'ReviewService');
    }
  }

  /// Track a scan event and request native review if positive milestone conditions are met
  /// (e.g. at least 2 completed scans and a cooldown between requests)
  Future<void> logScanAndCheckPrompt({
    int minScans = 2,
    int cooldownDays = 3,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Increment scan count
      final currentScans = (prefs.getInt(_keyScanCount) ?? 0) + 1;
      await prefs.setInt(_keyScanCount, currentScans);

      // Check scan count threshold (e.g. after 2nd scan)
      if (currentScans < minScans) {
        return;
      }

      // Check cooldown from last prompt request
      final lastPromptMillis = prefs.getInt(_keyLastPromptTime);
      if (lastPromptMillis != null) {
        final daysSinceLastPrompt = now.difference(
          DateTime.fromMillisecondsSinceEpoch(lastPromptMillis),
        ).inDays;
        if (daysSinceLastPrompt < cooldownDays) {
          return;
        }
      }

      // Request native in-app review dialog
      if (await isAvailable()) {
        await _inAppReview.requestReview();
        await prefs.setInt(_keyLastPromptTime, now.millisecondsSinceEpoch);
      }
    } catch (e) {
      developer.log('Error in logScanAndCheckPrompt: $e', name: 'ReviewService');
    }
  }

  /// Reset review tracking (useful for testing/debugging)
  Future<void> resetReviewData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyScanCount);
      await prefs.remove(_keyLastPromptTime);
    } catch (e) {
      developer.log('Error resetting review data: $e', name: 'ReviewService');
    }
  }
}

