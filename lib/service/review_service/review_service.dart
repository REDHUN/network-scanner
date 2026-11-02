import 'dart:async';
import 'dart:developer' as developer;

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ReviewPromptCallback = FutureOr<void> Function();

class ReviewService {
  ReviewService._internal();

  static final ReviewService _instance = ReviewService._internal();

  static ReviewService get instance => _instance;

  final InAppReview _inAppReview = InAppReview.instance;

  static const String _keyScanCount = 'app_review_scan_count';
  static const String _keyLastPromptTime = 'app_review_last_prompt_time';
  static const String _keyReviewRequested = 'app_review_requested';

  Future<void> _scanOperation = Future<void>.value();
  Future<bool>? _nativeRequestInFlight;

  /// Check whether the native in-app review API is available
  /// on this platform/device.
  Future<bool> isAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (e, stackTrace) {
      developer.log(
        'Error checking in-app review availability',
        name: 'ReviewService',
        error: e,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  /// Request the native in-app review dialog.
  ///
  /// Note:
  /// Google Play / App Store decides whether the dialog
  /// is actually displayed.
  Future<void> requestReview() async {
    try {
      await _requestNativeReview();
    } catch (e, stackTrace) {
      developer.log(
        'Error requesting review',
        name: 'ReviewService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Open the app's store listing directly.
  ///
  /// Useful for a manual "Rate this app" button.
  Future<void> openStoreListing({String? appStoreId}) async {
    try {
      await _inAppReview.openStoreListing(appStoreId: appStoreId);
    } catch (e, stackTrace) {
      developer.log(
        'Error opening store listing',
        name: 'ReviewService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Track a successful scan.
  ///
  /// The native review request is made once after the
  /// 3rd successful scan.
  ///
  /// Google Play / App Store decides whether the review
  /// dialog is actually shown.
  Future<void> logScanAndCheckPrompt({
    int minScans = 3,
    ReviewPromptCallback? onPromptEligible,
  }) {
    // Scans are reported fire-and-forget by the scanner view model. Queue the
    // work so two completions cannot read and overwrite the same scan count,
    // or issue duplicate native review requests.
    final operation = _scanOperation.then(
      (_) => _logScanAndCheckPrompt(
        minScans: minScans,
        onPromptEligible: onPromptEligible,
      ),
    );
    _scanOperation = operation;
    return operation;
  }

  Future<void> _logScanAndCheckPrompt({
    required int minScans,
    required ReviewPromptCallback? onPromptEligible,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Increment successful scan count.
      final currentScans = (prefs.getInt(_keyScanCount) ?? 0) + 1;

      await prefs.setInt(_keyScanCount, currentScans);

      // Migrate users who were prompted by an older version. A legacy prompt
      // timestamp means a request already happened, so never prompt them
      // again after upgrading.
      final reviewRequested = prefs.getBool(_keyReviewRequested) ?? false;
      if (prefs.containsKey(_keyLastPromptTime)) {
        if (!reviewRequested) {
          await prefs.setBool(_keyReviewRequested, true);
        }
        await prefs.remove(_keyLastPromptTime);
        return;
      }

      if (reviewRequested) {
        return;
      }

      // Wait until the required number of scans.
      if (currentScans < minScans) {
        return;
      }

      // Do not show a review-related message when this platform cannot show
      // the native prompt. The message should describe an action the user can
      // actually take.
      if (!await isAvailable()) {
        return;
      }

      // Only show the contextual message at the threshold. If the native
      // request later fails and the service retries on a later scan, the
      // user is not shown the message again.
      if (currentScans == minScans && onPromptEligible != null) {
        try {
          await onPromptEligible();
        } catch (e, stackTrace) {
          developer.log(
            'Error showing review prompt context',
            name: 'ReviewService',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      // Mark as requested only after the native call succeeds. If the native
      // request throws, the next scan remains eligible to retry.
      if (await _requestNativeReview()) {
        await prefs.setBool(_keyReviewRequested, true);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error in logScanAndCheckPrompt',
        name: 'ReviewService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Reset review tracking.
  ///
  /// Useful during development/testing.
  Future<void> resetReviewData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyScanCount);
      await prefs.remove(_keyReviewRequested);
      await prefs.remove(_keyLastPromptTime);
    } catch (e, stackTrace) {
      developer.log(
        'Error resetting review data',
        name: 'ReviewService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _requestNativeReview() {
    final inFlight = _nativeRequestInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final request = _requestNativeReviewOnce();
    late final Future<bool> trackedRequest;
    trackedRequest = request.whenComplete(() {
      if (identical(_nativeRequestInFlight, trackedRequest)) {
        _nativeRequestInFlight = null;
      }
    });
    _nativeRequestInFlight = trackedRequest;
    return trackedRequest;
  }

  Future<bool> _requestNativeReviewOnce() async {
    if (!await isAvailable()) {
      return false;
    }

    await _inAppReview.requestReview();
    return true;
  }
}
