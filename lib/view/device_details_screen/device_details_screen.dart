import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/models/network_model/open_port.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';
import 'package:ip_tools/service/device_storage_service/device_storage_service.dart';
import 'package:ip_tools/service/port_scanner_service/port_scanner_service.dart';
import 'package:ip_tools/service/share_service/share_service.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.isHistory && widget.historicalPortScanResult != null) {
      _lastScanResult = widget.historicalPortScanResult;
      _openPorts = _lastScanResult!.openPorts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      // Set the status bar theme for light background
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF656CEB)),
            onPressed: () {
              // Handle action
            },
          ),
        ],
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

              const SizedBox(height: 24),

              // Port Scanner Card
              if (!widget.isHistory ||
                  (widget.isHistory && _lastScanResult != null))
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
                            Icons.search,
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
                        ],
                      ),

                      if (!widget.isHistory) ...[
                        const SizedBox(height: 24),

                        // Radio Options
                        _buildPortScanOption(
                          title: 'Common Ports',
                          subtitle: 'Scan HTTP, FTP, SSH, etc.',
                          selected: _scanType == 'Common Ports',
                          onTap: () =>
                              setState(() => _scanType = 'Common Ports'),
                        ),
                        const SizedBox(height: 12),
                        _buildPortScanOption(
                          title: 'Top 100',
                          subtitle: 'Most frequent open ports',
                          selected: _scanType == 'Top 100',
                          onTap: () => setState(() => _scanType = 'Top 100'),
                        ),
                        const SizedBox(height: 12),
                        _buildPortScanOption(
                          title: 'Full Range',
                          subtitle: 'Scan ports 1-65535',
                          selected: _scanType == 'Full Range',
                          onTap: () => setState(() => _scanType = 'Full Range'),
                        ),

                        const SizedBox(height: 24),

                        // Start Scan Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isScanning ? null : _startPortScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF656CEB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isScanning
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'SCANNING...',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
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
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],

                      if (_lastScanResult != null) ...[
                        if (!widget.isHistory) const SizedBox(height: 24),
                        if (widget.isHistory) const SizedBox(height: 8),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF656CEB).withValues(alpha: 0.1)
                : const Color(0xFFF3F4F6),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF656CEB).withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Custom Radio Button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF656CEB)
                      : const Color(0xFFD1D5DB),
                  width: selected ? 6 : 1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SCAN RESULTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_lastScanResult!.openPortsCount} OPEN',
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SCANNED',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_lastScanResult!.totalPortsScanned}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OPEN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_lastScanResult!.openPortsCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF656CEB),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIME',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_lastScanResult!.scanDuration.inSeconds}s',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_openPorts.isNotEmpty) ...[
          const SizedBox(height: 20),
          ...(_openPorts.take(5).map((port) => _buildPortItem(port))),
          if (_openPorts.length > 5) ...[
            const SizedBox(height: 8),
            Text(
              'And ${_openPorts.length - 5} more ports...',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPortItem(OpenPort port) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: port.isSecure
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
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
            child: Text(
              port.service,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
          ),
          if (port.isSecure)
            const Icon(Icons.security, color: Color(0xFF10B981), size: 16),
        ],
      ),
    );
  }

  String _getDeviceName() {
    if (widget.device.isGateway) return 'Home Router';
    if (widget.device.isSelf) return 'This Device';
    return widget.device.displayName;
  }

  String _getManufacturer() {
    if (widget.device.isGateway)
      return 'TP-Link'; // Hardcoded based on image, replace with true mac lookup if needed
    if (widget.device.name?.toLowerCase().contains('apple') == true)
      return 'Apple';
    return 'Unknown';
  }

  IconData _getDeviceIcon() {
    if (widget.device.isGateway) return Icons.router;
    if (widget.device.isSelf) return Icons.smartphone;
    if (widget.device.name?.toLowerCase().contains('macbook') == true)
      return Icons.laptop_mac;
    if (widget.device.name?.toLowerCase().contains('iphone') == true)
      return Icons.phone_iphone;
    if (widget.device.name?.toLowerCase().contains('tv') == true)
      return Icons.tv;
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

  Future<void> _startPortScan() async {
    setState(() {
      _isScanning = true;
      _openPorts.clear();
    });

    try {
      final result = await _portScanner.performComprehensiveScan(
        widget.device.ip,
        useCommonPorts: _scanType == 'Common Ports',
        useTop100: _scanType == 'Top 100',
        timeout: 1000,
      );

      // Save the scan result to storage so it appears in history later
      await DeviceStorageService().savePortScanResult(widget.device.ip, result);

      setState(() {
        _lastScanResult = result;
        _openPorts = result.openPorts;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        SnackbarUtils.showError(context, 'Scan failed: ${e.toString()}');
      }
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
      // If we have port scan results, share the complete security report
      // Otherwise, share basic device information
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
}
