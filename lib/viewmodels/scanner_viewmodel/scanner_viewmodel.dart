import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:netra/models/network_model/scan_settings.dart';
import 'package:netra/models/network_model/scanned_device.dart';
import 'package:netra/service/network_scanner_service/network_scanner_service.dart';

enum ScanState { idle, scanning, done, error }

class NetworkScannerProvider extends ChangeNotifier {
  final _scanner = NetworkScannerService();

  ScanState state = ScanState.idle;
  final List<ScannedDevice> devices = [];
  ScanSettings settings = const ScanSettings(
    firstHost: 1,
    lastHost: 50, // Reduce initial scan range for better performance
    pingTimeout: 1,
  );
  String? error;

  StreamSubscription<ScannedDevice>? _sub;

  Future<void> startScan({bool fullScan = false}) async {
    if (state == ScanState.scanning) return;

    stopScan();

    state = ScanState.scanning;
    error = null;
    devices.clear();
    notifyListeners();

    // Use different settings based on scan type
    final scanSettings = fullScan
        ? const ScanSettings(firstHost: 1, lastHost: 254, pingTimeout: 1)
        : const ScanSettings(firstHost: 1, lastHost: 50, pingTimeout: 1);

    // Start scanning asynchronously to prevent UI blocking
    try {
      _sub = _scanner
          .scan(scanSettings)
          .listen(
            (device) {
              if (!devices.any((d) => d.ip == device.ip)) {
                devices.add(device);
                notifyListeners();
              }
            },
            onError: (e) {
              error = e.toString();
              state = ScanState.error;
              notifyListeners();
            },
            onDone: () {
              state = ScanState.done;
              notifyListeners();
            },
          );
    } catch (e) {
      error = e.toString();
      state = ScanState.error;
      notifyListeners();
    }
  }

  void stopScan() {
    _sub?.cancel();
    state = ScanState.done;
    notifyListeners();
  }

  void resetScan() {
    _sub?.cancel();
    state = ScanState.idle;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
