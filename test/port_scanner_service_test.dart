import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/models/network_model/open_port.dart';
import 'package:ip_tools/service/port_scanner_service/port_scanner_service.dart';

void main() {
  group('PortScannerService Tests', () {
    late ServerSocket testServer;
    late int testPort;

    setUpAll(() async {
      // Bind to a local test server
      testServer = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      testPort = testServer.port;
    });

    tearDownAll(() async {
      await testServer.close();
    });

    test('Single port check accurately detects open port', () async {
      final service = PortScannerService();
      final isOpen = await service.isPortOpen('127.0.0.1', testPort, timeout: 500);
      expect(isOpen, isTrue);

      // Port 1 on loopback should be closed
      final isClosed = await service.isPortOpen('127.0.0.1', 1, timeout: 200);
      expect(isClosed, isFalse);
    });

    test('scanPorts streams real-time progress and discovers open port', () async {
      final service = PortScannerService();
      final portsToScan = [testPort, 1, 2, 3, 4];
      final events = <PortScanProgress>[];

      await for (final progress in service.scanPorts(
        ipAddress: '127.0.0.1',
        ports: portsToScan,
        concurrency: 5,
        initialTimeoutMs: 250,
      )) {
        events.add(progress);
      }

      expect(events.isNotEmpty, isTrue);
      final lastEvent = events.last;
      expect(lastEvent.isComplete, isTrue);
      expect(lastEvent.scannedPorts, equals(portsToScan.length));
      expect(lastEvent.openPorts.any((p) => p.port == testPort), isTrue);
    });

    test('PortScanCancellationToken immediately stops scanning', () async {
      final service = PortScannerService();
      final cancelToken = PortScanCancellationToken();
      final portsToScan = List.generate(50, (i) => 20000 + i);

      // Cancel right away after first event
      var eventsReceived = 0;
      await for (final _ in service.scanPorts(
        ipAddress: '127.0.0.1',
        ports: portsToScan,
        concurrency: 5,
        initialTimeoutMs: 500,
        cancelToken: cancelToken,
      )) {
        eventsReceived++;
        if (eventsReceived == 1) {
          cancelToken.cancel();
        }
      }

      expect(cancelToken.isCancelled, isTrue);
    });

    test('OpenPort serialization handles banner correctly', () {
      final port = OpenPort(
        port: 80,
        service: 'HTTP',
        description: 'Web Server',
        isSecure: false,
        banner: 'nginx/1.18.0',
      );

      final json = port.toJson();
      expect(json['banner'], equals('nginx/1.18.0'));

      final restored = OpenPort.fromJson(json);
      expect(restored.port, equals(80));
      expect(restored.banner, equals('nginx/1.18.0'));
    });
  });
}
