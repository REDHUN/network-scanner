import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/view/wifi_connection_screen/wifi_connection_screen.dart';

void main() {
  testWidgets(
    'opens scroll-safe Wi-Fi instructions with accessible close action',
    (tester) async {
      final channel = MethodChannel('ip_tools/wifi_settings');
       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
           .setMockMethodCallHandler(
             channel,
             (call) async => throw PlatformException(
               code: 'SETTINGS_UNAVAILABLE',
             ),
           );

      await tester.pumpWidget(
        MaterialApp(home: WiFiConnectionScreen(onWiFiConnected: _noop)),
      );

      final connectButton = find.byType(ElevatedButton).last;
      await tester.ensureVisible(connectButton);
      await tester.tap(connectButton);
      await tester.pumpAndSettle();

      expect(find.text('Connect to WiFi'), findsOneWidget);
      expect(find.byTooltip('Close instructions'), findsOneWidget);
      expect(find.bySemanticsLabel('Close instructions'), findsOneWidget);
      expect(tester.getSize(find.byTooltip('Close instructions')).height, 44);

      await tester.tap(find.byTooltip('Close instructions'));
      await tester.pumpAndSettle();
      expect(find.text('Connect to WiFi'), findsNothing);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  testWidgets(
    'opens platform settings without leaving an instructions dialog open',
    (tester) async {
      final channel = MethodChannel('ip_tools/wifi_settings');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => 'wifi_settings');

      await tester.pumpWidget(
        MaterialApp(home: WiFiConnectionScreen(onWiFiConnected: _noop)),
      );

      final connectButton = find.byType(ElevatedButton).last;
      await tester.ensureVisible(connectButton);
      await tester.tap(connectButton);
      await tester.pumpAndSettle();

      expect(find.text('Connect to WiFi'), findsNothing);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
}

void _noop() {}
