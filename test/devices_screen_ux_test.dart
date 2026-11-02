import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/core/theme/app_theme.dart';
import 'package:ip_tools/common/widgets/wavy_scan_progress_indicator.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';
import 'package:ip_tools/models/storage/router_network_data.dart';
import 'package:ip_tools/service/network_connectivity_service/network_connectivity_service.dart';
import 'package:ip_tools/service/network_service/network_service.dart';
import 'package:ip_tools/service/permission_service/permission_service.dart';
import 'package:ip_tools/view/devices_screen/devices_screen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:ip_tools/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'distinguishes live findings from saved history on narrow screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final permissions = PermissionService();
      final network = NetworkViewModel(
        NetworkService(),
        permissions,
        ConnectivityService(),
      );
      final scanner = NetworkScannerProvider()..isFirstApiCall = false;
      scanner
        ..state = ScanState.done
        ..progress = 1
        ..devices.add(const ScannedDevice(ip: '192.168.1.7', name: 'Phone'))
        ..offlineDevices.add(
          StoredDevice(
            ip: '192.168.1.3',
            name: 'Speaker',
            firstSeen: DateTime(2026),
            lastSeen: DateTime(2026),
            isOnline: false,
          ),
        );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NetworkViewModel>.value(value: network),
            ChangeNotifierProvider<NetworkScannerProvider>.value(
              value: scanner,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DevicesScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Local network not available'), findsOneWidget);
      expect(find.text('Scan complete · 1 found now'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Speaker'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('192.168.1.0/24'), findsNothing);
      expect(find.text('Probing 10.0.2.1...'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Online (1)'));
      await tester.pump();
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Speaker'), findsNothing);

      await tester.ensureVisible(find.text('Gateways (0)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gateways (0)'));
      await tester.pump();
      expect(find.text('No gateways'), findsOneWidget);
      await tester.tap(find.text('Show all devices'));
      await tester.pump();
      expect(find.text('Speaker'), findsOneWidget);

      scanner
        ..state = ScanState.scanning
        ..progress = 0.2
        ..scannedCount = 52
        ..notifyListeners();
      await tester.pump();
      expect(find.byType(WavyScanProgressIndicator), findsOneWidget);
      expect(find.text('52 of 254 hosts checked'), findsOneWidget);
      expect(find.textContaining('Probing 10.0.2'), findsNothing);
      expect(tester.takeException(), isNull);
      scanner
        ..state = ScanState.done
        ..progress = 1
        ..notifyListeners();
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      network.dispose();
      scanner.dispose();
      permissions.dispose();
    },
  );
}
