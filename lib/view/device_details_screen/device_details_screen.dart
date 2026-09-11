import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/models/network_model/open_port.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';
import 'package:ip_tools/service/device_storage_service/device_storage_service.dart';
import 'package:ip_tools/service/port_scanner_service/port_scanner_service.dart';
import 'package:ip_tools/service/share_service/share_service.dart';
import 'package:ip_tools/view/ping_screen/ping_screen.dart';
import 'package:ip_tools/view/traceroute_screen/traceroute_screen.dart';
import 'package:ip_tools/view/wol_screen/wol_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final ScannedDevice device;
  final bool isOnline;
  final bool isHistory;
  final DateTime? lastSeen;
  final PortScanResult? historicalPortScanResult;

  const DeviceDetailsScreen({
    super.key,
    required this.device,
    this.isOnline = true,
    this.isHistory = false,
    this.lastSeen,
    this.historicalPortScanResult,
  });

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  final PortScannerService _portScanner = PortScannerService();
  final ShareService _shareService = ShareService();

  List<OpenPort> _openPorts = [];
  bool _isScanning = false;
  String _scanType = 'Common Ports';
  PortScanResult? _lastScanResult;

  // Custom Input Controllers
  late final TextEditingController _timeoutController;
  late final TextEditingController _rangeController;

  // Real-time scan state
  double _scanProgress = 0.0;
  int _scannedPortsCount = 0;
  int _totalPortsToScan = 0;
  StreamSubscription<PortScanProgress>? _scanSubscription;
  PortScanCancellationToken? _cancellationToken;

  @override
  void initState() {
    super.initState();
    _timeoutController = TextEditingController(text: '300');
    _rangeController = TextEditingController(text: '1-1000');

    if (widget.isHistory && widget.historicalPortScanResult != null) {
      _lastScanResult = widget.historicalPortScanResult;
      _openPorts = _lastScanResult!.openPorts;
    }
  }

  @override
  void dispose() {
    _timeoutController.dispose();
    _rangeController.dispose();
    _cancellationToken?.cancel();
    _scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF656CEB),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getDeviceName(),
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareDeviceInfo,
        backgroundColor: const Color(0xFF656CEB),
        icon: const Icon(Icons.share, color: Colors.white),
        label: const Text(
          'Share',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Header Icon with Online Dot
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _getDeviceIcon(),
                        color: const Color(0xFF656CEB),
                        size: 50,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Device Status Text
              Text(
                widget.isHistory
                    ? (widget.isOnline
                          ? 'Previously Online'
                          : 'Previously Offline')
                    : (widget.isOnline ? 'Online' : 'Offline'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isHistory && widget.lastSeen != null
                    ? 'Last seen: ${_formatDateTime(widget.lastSeen!)}'
                    : '${_getDeviceName()} Status',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 32),

              // Connection Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONNECTION DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF656CEB),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow('IP Address', widget.device.ip),

                    if (widget.device.mac != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                      ),
                      _buildDetailRow('MAC Address', widget.device.mac!),
                    ],

                    if (widget.device.name != null &&
                        widget.device.name != widget.device.displayName) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                      ),
                      _buildDetailRow('Device Name', widget.device.name!),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ),
                    _buildDetailRow('Manufacturer', _getManufacturer()),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Device Quick Utilities Card
              _buildDeviceUtilitiesCard(),

              const SizedBox(height: 24),

              // Port Scanner Card (Only available for online devices)
              if (widget.isOnline &&
                  (!widget.isHistory ||
                      (widget.isHistory && _lastScanResult != null)))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.radar,
                            color: Color(0xFF656CEB),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'PORT SCANNER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF656CEB),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          if (_isScanning)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF656CEB).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF656CEB),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_openPorts.length} FOUND',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF656CEB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      if (!widget.isHistory) ...[
                        const SizedBox(height: 20),

                        // Scan Type Options (Disabled while scanning)
                        _buildPortScanOption(
                          title: 'Common Ports',
                          subtitle: 'Scan ~20 popular ports (HTTP, SSH, etc.)',
                          selected: _scanType == 'Common Ports',
                          onTap: () =>
                              setState(() => _scanType = 'Common Ports'),
                        ),
                        const SizedBox(height: 10),
                        _buildPortScanOption(
                          title: 'Top 100',
                          subtitle: 'Most frequent open services & DBs',
                          selected: _scanType == 'Top 100',
                          onTap: () => setState(() => _scanType = 'Top 100'),
                        ),
                        const SizedBox(height: 10),
                        _buildPortScanOption(
                          title: 'Custom Range',
                          subtitle: 'Specify custom port range & timeout',
                          selected: _scanType == 'Custom Range',
                          onTap: () =>
                              setState(() => _scanType = 'Custom Range'),
                        ),

                        // Custom Range & Timeout Input Fields (Image 2 style)
                        if (_scanType == 'Custom Range') ...[
                          _buildCustomRangeFields(),
                        ],

                        // Active Scan Live Progress Card
                        if (_isScanning) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Scanning ${widget.device.ip}...',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    Text(
                                      '${(_scanProgress * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF656CEB),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: _scanProgress,
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFFE5E7EB),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF656CEB),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_scannedPortsCount / $_totalPortsToScan ports scanned',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Action Button (Start / Stop)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                _isScanning ? _stopPortScan : _startPortScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isScanning
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF656CEB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: _isScanning
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.stop_circle_outlined, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'STOP SCAN',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.radar, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'START PORT SCAN',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],

                      // Scan Results (Live during scan or summary after)
                      if (_lastScanResult != null || (_isScanning && _openPorts.isNotEmpty)) ...[
                        const SizedBox(height: 20),
                        _buildScanResults(),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRangeFields() {
    return Column(
      children: [
        const SizedBox(height: 14),
        TextField(
          controller: _timeoutController,
          enabled: !_isScanning,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            labelText: 'Timeout (ms)',
            labelStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF656CEB),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rangeController,
          enabled: !_isScanning,
          keyboardType: TextInputType.text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            labelText: 'Range:',
            labelStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF656CEB),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        GestureDetector(
          onTap: () => _copyToClipboard(value, label),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortScanOption({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isScanning ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEEDFF).withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF656CEB)
                : const Color(0xFFE5E7EB),
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF656CEB)
                      : const Color(0xFFD1D5DB),
                  width: selected ? 5.5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF111827)
                          : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResults() {
    final hasCompletedResult = _lastScanResult != null;
    final totalScanned = hasCompletedResult
        ? _lastScanResult!.totalPortsScanned
        : _scannedPortsCount;
    final durationSeconds = hasCompletedResult
        ? _lastScanResult!.scanDuration.inSeconds
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isScanning ? 'DISCOVERED OPEN PORTS' : 'SCAN RESULTS',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
                letterSpacing: 1.1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_openPorts.length} OPEN',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        if (hasCompletedResult && !_isScanning) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox('SCANNED', '$totalScanned'),
              _buildStatBox('OPEN', '${_openPorts.length}', color: const Color(0xFF656CEB)),
              _buildStatBox('TIME', '${durationSeconds}s'),
            ],
          ),
        ],
        if (_openPorts.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._openPorts.map((port) => _buildPortItem(port)),
        ] else if (!_isScanning && hasCompletedResult) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No open ports detected in this range.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatBox(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildPortItem(OpenPort port) {
    final risk = _portScanner.getPortRiskLevel(port.port);
    Color riskColor;
    if (risk == 'High') {
      riskColor = const Color(0xFFEF4444);
    } else if (risk == 'Medium') {
      riskColor = const Color(0xFFF59E0B);
    } else {
      riskColor = const Color(0xFF10B981);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: riskColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 54,
            child: Text(
              '${port.port}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      port.service,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                    if (port.isSecure) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF10B981),
                        size: 13,
                      ),
                    ],
                  ],
                ),
                if (port.banner != null && port.banner!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    port.banner!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF656CEB),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Text(
                    port.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<int> _getSelectedPorts() {
    switch (_scanType) {
      case 'Top 100':
        return PortScannerService.top100Ports;
      case 'Custom Range':
        return _parseCustomPorts();
      case 'Common Ports':
      default:
        return PortScannerService.commonPorts;
    }
  }

  List<int> _parseCustomPorts() {
    final input = _rangeController.text.trim();
    if (input.isEmpty) {
      return List.generate(1000, (i) => i + 1);
    }

    final ports = <int>{};
    final parts = input.split(RegExp(r'[,;\s]+'));

    for (final part in parts) {
      if (part.isEmpty) continue;
      if (part.contains('-')) {
        final rangeParts = part.split('-');
        if (rangeParts.length == 2) {
          final start = int.tryParse(rangeParts[0].trim());
          final end = int.tryParse(rangeParts[1].trim());
          if (start != null && end != null) {
            final minP = start.clamp(1, 65535);
            final maxP = end.clamp(1, 65535);
            final actualStart = minP < maxP ? minP : maxP;
            final actualEnd = minP < maxP ? maxP : minP;
            for (int p = actualStart; p <= actualEnd; p++) {
              ports.add(p);
            }
          }
        }
      } else {
        final singlePort = int.tryParse(part);
        if (singlePort != null && singlePort >= 1 && singlePort <= 65535) {
          ports.add(singlePort);
        }
      }
    }

    if (ports.isEmpty) {
      return List.generate(1000, (i) => i + 1);
    }

    final sortedList = ports.toList()..sort();
    return sortedList;
  }

  int _parseTimeout() {
    final val = int.tryParse(_timeoutController.text.trim());
    if (val == null || val < 50) return 300;
    if (val > 5000) return 5000;
    return val;
  }

  void _startPortScan() {
    final targetPorts = _getSelectedPorts();
    final timeout = _scanType == 'Custom Range' ? _parseTimeout() : 350;

    if (targetPorts.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter a valid port range.');
      return;
    }

    _cancellationToken?.cancel();
    _scanSubscription?.cancel();

    _cancellationToken = PortScanCancellationToken();

    setState(() {
      _isScanning = true;
      _openPorts = [];
      _scanProgress = 0.0;
      _scannedPortsCount = 0;
      _totalPortsToScan = targetPorts.length;
    });

    _scanSubscription = _portScanner
        .scanPorts(
      ipAddress: widget.device.ip,
      ports: targetPorts,
      concurrency: 25,
      initialTimeoutMs: timeout,
      enableBannerProbing: true,
      cancelToken: _cancellationToken,
    )
        .listen(
      (progress) {
        if (!mounted) return;
        setState(() {
          _scanProgress = progress.progress;
          _scannedPortsCount = progress.scannedPorts;
          _openPorts = progress.openPorts;
        });

        if (progress.isComplete && !progress.isCancelled) {
          _onScanCompleted(progress, targetPorts.length);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isScanning = false);
        SnackbarUtils.showError(context, 'Scan failed: ${error.toString()}');
      },
      onDone: () {
        if (!mounted) return;
        if (_isScanning) {
          setState(() => _isScanning = false);
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> _onScanCompleted(PortScanProgress progress, int totalCount) async {
    final result = PortScanResult(
      ipAddress: widget.device.ip,
      openPorts: progress.openPorts,
      scanTime: DateTime.now(),
      scanDuration: progress.elapsed,
      totalPortsScanned: totalCount,
    );

    await DeviceStorageService().savePortScanResult(widget.device.ip, result);

    if (!mounted) return;
    setState(() {
      _lastScanResult = result;
      _isScanning = false;
    });
  }

  void _stopPortScan() {
    _cancellationToken?.cancel();
    _scanSubscription?.cancel();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
      SnackbarUtils.showInfo(context, 'Port scan stopped.');
    }
  }

  String _getDeviceName() {
    if (widget.device.isGateway) return 'Home Router';
    if (widget.device.isSelf) return 'This Device';
    return widget.device.displayName;
  }

  String _getManufacturer() {
    if (widget.device.isGateway) return 'TP-Link';
    if (widget.device.name?.toLowerCase().contains('apple') == true) {
      return 'Apple';
    }
    return 'Unknown';
  }

  IconData _getDeviceIcon() {
    if (widget.device.isGateway) return Icons.router;
    if (widget.device.isSelf) return Icons.smartphone;
    if (widget.device.name?.toLowerCase().contains('macbook') == true) {
      return Icons.laptop_mac;
    }
    if (widget.device.name?.toLowerCase().contains('iphone') == true) {
      return Icons.phone_iphone;
    }
    if (widget.device.name?.toLowerCase().contains('tv') == true) {
      return Icons.tv;
    }
    return Icons.devices;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _copyToClipboard(String value, String label) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) {
        SnackbarUtils.showCopySuccess(context, label);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to copy: ${e.toString()}');
      }
    }
  }

  Future<void> _shareDeviceInfo() async {
    try {
      if (_lastScanResult != null) {
        await _shareService.shareDeviceWithPorts(
          widget.device,
          _lastScanResult,
        );
        _showShareSuccessMessage('Security report shared successfully!');
      } else {
        await _shareService.shareDeviceInfo(widget.device);
        _showShareSuccessMessage('Device information shared successfully!');
      }
    } catch (e) {
      _showShareErrorMessage('Failed to share: ${e.toString()}');
    }
  }

  void _showShareSuccessMessage(String message) {
    if (mounted) {
      SnackbarUtils.showSuccess(context, message);
    }
  }

  void _showShareErrorMessage(String message) {
    if (mounted) {
      SnackbarUtils.showError(context, message);
    }
  }

  Widget _buildDeviceUtilitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEVICE UTILITIES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF656CEB),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDeviceUtilityButton(
                  title: 'Ping',
                  subtitle: 'Test Latency',
                  icon: Icons.speed_rounded,
                  color: const Color(0xFF0075FF),
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PingScreen(initialHost: widget.device.ip),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDeviceUtilityButton(
                  title: 'Trace',
                  subtitle: 'Route Path',
                  icon: Icons.alt_route_rounded,
                  color: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFFF5F3FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TracerouteScreen(initialHost: widget.device.ip),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDeviceUtilityButton(
                  title: 'Wake (WoL)',
                  subtitle: 'Power On',
                  icon: Icons.power_settings_new_rounded,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WolScreen(
                          initialMac: widget.device.mac,
                          deviceName: _getDeviceName(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (widget.device.isGateway) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final ip = widget.device.ip.trim();
                final uri = Uri.parse('http://$ip');
                try {
                  bool launched = false;
                  try {
                    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                  if (!launched) {
                    try {
                      launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
                    } catch (_) {}
                  }
                  if (!launched && context.mounted) {
                    SnackbarUtils.showError(context, 'Could not open router page http://$ip');
                  }
                } catch (e) {
                  if (context.mounted) {
                    SnackbarUtils.showError(context, 'Error opening router admin: ${e.toString()}');
                  }
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0075FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Open Router Admin Console',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'http://${widget.device.ip}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0075FF),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF0075FF)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceUtilityButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
