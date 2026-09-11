import 'package:flutter/material.dart';
import 'package:flutter_network_scanner/flutter_network_scanner.dart';

void main() {
  runApp(const ScannerExampleApp());
}

class ScannerExampleApp extends StatelessWidget {
  const ScannerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_network_scanner Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ScannerHomePage(),
    );
  }
}

class ScannerHomePage extends StatefulWidget {
  const ScannerHomePage({super.key});

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  bool _isScanning = false;
  NetworkInfoModel? _networkInfo;
  List<DiscoveredDevice> _devices = [];
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    try {
      final info = await FlutterNetworkScanner.getNetworkInfo();
      setState(() {
        _networkInfo = info;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load network info: $e';
      });
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = null;
    });

    try {
      final results = await FlutterNetworkScanner.scanNetwork(timeoutMs: 250);
      setState(() {
        _devices = results;
        _isScanning = false;
        _statusMessage = 'Found ${results.length} active devices';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Scanner Plugin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_networkInfo != null)
            Card(
              elevation: 0,
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected: ${_networkInfo!.ssid ?? _networkInfo!.ifaceName ?? "Wi-Fi"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('Local IP: ${_networkInfo!.ip} | Gateway: ${_networkInfo!.gateway ?? "Unknown"}'),
                    Text('Subnet Mask: ${_networkInfo!.subnet}'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _statusMessage!,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Scanning /24 subnet...'),
                  ],
                ),
              ),
            )
          else if (_devices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No devices found yet. Tap "Scan Network" to begin.'),
              ),
            )
          else
            ..._devices.map(
              (d) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(d.isGateway ? Icons.router : Icons.devices),
                  ),
                  title: Text(d.displayName),
                  subtitle: Text(
                    '${d.ip}${d.vendor != null ? " • ${d.vendor}" : ""}\n'
                    'Ports: ${d.openPorts.isEmpty ? "None" : d.openPorts.join(", ")}',
                  ),
                  trailing: Text('${d.pingMs} ms'),
                  isThreeLine: true,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : _startScan,
        label: Text(_isScanning ? 'Scanning...' : 'Scan Network'),
        icon: const Icon(Icons.radar),
      ),
    );
  }
}
