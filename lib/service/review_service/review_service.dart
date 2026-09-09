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
  static const String _keyHasReviewed = 'app_review_has_reviewed';
  static const String _keyFirstOpenTime = 'app_review_first_open_time';

  /// Check if in-app review dialog is available on this platform/device
  Future<bool> isAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (e) {
      developer.log('Error checking in-app review availability: $e', name: 'ReviewService');
      return false;
    }
  }

  /// Request in-app review dialog.
  /// If in-app review dialog is not supported/available, opens the app store listing.
  Future<void> requestReview({String? appStoreId}) async {
    try {
      final available = await isAvailable();
      if (available) {
        await _inAppReview.requestReview();
      } else {
        await openStoreListing(appStoreId: appStoreId);
      }
      _markAsReviewed();
    } catch (e) {
      developer.log('Error requesting review: $e', name: 'ReviewService');
      // Fallback to store listing
      await openStoreListing(appStoreId: appStoreId);
    }
  }

  /// Open the store listing (Google Play / App Store) directly for the user to rate.
  Future<void> openStoreListing({String? appStoreId}) async {
    try {
      await _inAppReview.openStoreListing(appStoreId: appStoreId);
      _markAsReviewed();
    } catch (e) {
      developer.log('Error opening store listing: $e', name: 'ReviewService');
    }
  }

  /// Mark review as completed or prompted so we don't nag the user repeatedly
  Future<void> _markAsReviewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasReviewed, true);
      await prefs.setInt(
        _keyLastPromptTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      developer.log('Error saving review preferences: $e', name: 'ReviewService');
    }
  }

  /// Track a scan event and prompt for review automatically if conditions are met
  /// (e.g. at least 3 scans, at least 2 days after first open, and at least 14 days since last prompt)
  Future<void> logScanAndCheckPrompt({
    int minScans = 3,
    int minDaysSinceFirstOpen = 2,
    int cooldownDays = 14,
    String? appStoreId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();

      // Initialize first open time if not present
      if (!prefs.containsKey(_keyFirstOpenTime)) {
        await prefs.setInt(_keyFirstOpenTime, now.millisecondsSinceEpoch);
      }

      // Increment scan count
      final currentScans = (prefs.getInt(_keyScanCount) ?? 0) + 1;
      await prefs.setInt(_keyScanCount, currentScans);

      // Check if user already reviewed
      final hasReviewed = prefs.getBool(_keyHasReviewed) ?? false;
      if (hasReviewed) return;

      // Check scan count threshold
      if (currentScans < minScans) return;

      // Check days since first open
      final firstOpenMillis = prefs.getInt(_keyFirstOpenTime) ?? now.millisecondsSinceEpoch;
      final daysSinceFirstOpen = now.difference(
        DateTime.fromMillisecondsSinceEpoch(firstOpenMillis),
      ).inDays;
      if (daysSinceFirstOpen < minDaysSinceFirstOpen) return;

      // Check cooldown from last prompt
      final lastPromptMillis = prefs.getInt(_keyLastPromptTime);
      if (lastPromptMillis != null) {
        final daysSinceLastPrompt = now.difference(
          DateTime.fromMillisecondsSinceEpoch(lastPromptMillis),
        ).inDays;
        if (daysSinceLastPrompt < cooldownDays) return;
      }

      // If in-app review is available, prompt silently
      final available = await isAvailable();
      if (available) {
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
      await prefs.remove(_keyHasReviewed);
      await prefs.remove(_keyFirstOpenTime);
    } catch (e) {
      developer.log('Error resetting review data: $e', name: 'ReviewService');
    }
  }
}
