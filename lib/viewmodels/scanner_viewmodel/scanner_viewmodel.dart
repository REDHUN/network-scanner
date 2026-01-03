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
  ScanSettings settings = const ScanSettings();
  String? error;

  StreamSubscription<ScannedDevice>? _sub;

  void startScan() {
    if (state == ScanState.scanning) return;

    devices.clear();
    state = ScanState.scanning;
    notifyListeners();

    _sub = _scanner.scan(settings).listen(
          (device) {
        if (!devices.contains(device)) {
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
  }

  void stopScan() {
    _sub?.cancel();
    state = ScanState.done;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
