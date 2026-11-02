import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/service/review_service/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'migrates legacy prompt data and reset clears all review data',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_review_scan_count': 2,
        'app_review_last_prompt_time': 123,
      });

      final service = ReviewService.instance;
      await service.logScanAndCheckPrompt(minScans: 99);

      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_review_scan_count'), 3);
      expect(prefs.getBool('app_review_requested'), isTrue);
      expect(prefs.containsKey('app_review_last_prompt_time'), isFalse);

      await service.resetReviewData();

      prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('app_review_scan_count'), isFalse);
      expect(prefs.containsKey('app_review_requested'), isFalse);
      expect(prefs.containsKey('app_review_last_prompt_time'), isFalse);
    },
  );

  test(
    'notifies once at the review threshold before retrying silently',
    () async {
      final channel = MethodChannel('dev.britannio.in_app_review');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'isAvailable') return true;
            if (call.method == 'requestReview') return null;
            return null;
          });

      final service = ReviewService.instance;
      await service.resetReviewData();
      SharedPreferences.setMockInitialValues({'app_review_scan_count': 2});

      var callbackCount = 0;
      Future<void> showContext() async {
        callbackCount++;
      }

      await service.logScanAndCheckPrompt(onPromptEligible: showContext);
      expect(callbackCount, 1);

      // A failed/unavailable native request remains retryable, but the context
      // message belongs to the threshold scan and is not repeated.
      await service.logScanAndCheckPrompt(onPromptEligible: showContext);
      expect(callbackCount, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_review_scan_count'), 4);
      await service.resetReviewData();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
}
