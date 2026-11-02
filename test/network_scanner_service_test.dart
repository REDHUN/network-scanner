import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/models/network_model/network_info_model.dart';
import 'package:ip_tools/models/network_model/scan_settings.dart';
import 'package:ip_tools/service/network_scanner_service/network_scanner_service.dart';

void main() {
  test(
    'network scanner service keeps the progress stream API on fallback',
    () async {
      final events = await NetworkScannerService()
          .scanWithProgress(
            const ScanSettings(firstHost: 1, lastHost: 1),
            networkInfo: const NetworkInfoModel(
              wifiIP: '127.0.0.1',
              gateway: '127.0.0.1',
              subnet: '255.0.0.0',
            ),
          )
          .toList();

      expect(events, isNotEmpty);
      expect(events.last.isComplete, isTrue);
      expect(events.last.progress, 1.0);
      expect(events.any((event) => event.foundDevice?.isSelf == true), isTrue);
    },
  );
}
