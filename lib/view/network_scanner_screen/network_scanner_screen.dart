import 'package:flutter/material.dart';
import 'package:ip_tools/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:provider/provider.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NetworkScannerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Scan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: vm.startScan),
        ],
      ),
      body: ListView.builder(
        itemCount: vm.devices.length,
        itemBuilder: (_, i) {
          final d = vm.devices[i];
          return ListTile(
            leading: Icon(d.icon),
            title: Text(d.displayName),
            subtitle: Text(d.ip),
          );
        },
      ),
    );
  }
}
