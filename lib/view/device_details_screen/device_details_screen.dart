import 'package:flutter/material.dart';
import 'package:ip_tools/models/network_model/open_port.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';
import 'package:ip_tools/service/port_scanner_service/port_scanner_service.dart';
import 'package:ip_tools/service/share_service/share_service.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final ScannedDevice device;

  const DeviceDetailsScreen({super.key, required this.device});

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C2C2E),
              const Color(0xFF1C1C1E),
              const Color(0xFF2C2C2E),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and device name
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _getDeviceName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _shareDeviceInfo,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Device Status Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.devices,
                          color: Color(0xFFD4A574),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DEVICE STATUS',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Online & Active',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF30A46C).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF30A46C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Color(0xFF30A46C),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Connection Details Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Connection Details Header
                          Row(
                            children: [
                              Text(
                                'Connection Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.headlineLarge?.color,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Updated just now',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // IP Address
                          _buildDetailCard(
                            'IP ADDRESS',
                            widget.device.ip,
                            Icons.devices,
                          ),
                          const SizedBox(height: 16),

                          // Port Scanning Section
                          _buildPortScanSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDeviceName() {
    if (widget.device.isGateway) return 'Home Router';
    if (widget.device.isSelf) return 'This Device';
    return widget.device.displayName;
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.6,
                    ),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.headlineLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.copy,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            Text(
              'Port Scanner',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.headlineLarge?.color,
              ),
            ),
            const Spacer(),
            // Help/Reference button
            GestureDetector(
              onTap: _showPortReferenceDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.help_outline,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCAN TYPE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildScanTypeButton(
                      'Common Ports',
                      'Quick scan of 16 common ports',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildScanTypeButton(
                      'Top 100',
                      'Scan top 100 most used ports',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _startPortScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isScanning
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFD4A574),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('Scanning $_scanType...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4A574),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.security,
                                  color: Color(0xFF2C2C2E),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('START $_scanType SCAN'),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_lastScanResult != null) ...[
          const SizedBox(height: 24),
          _buildScanResults(),
        ],
      ],
    );
  }

  Widget _buildScanTypeButton(String type, String description) {
    final isSelected = _scanType == type;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _isScanning ? null : () => setState(() => _scanType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.05)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4A574)
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFFD4A574)
                        : theme.textTheme.headlineLarge?.color,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4A574),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResults() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Scan Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.headlineLarge?.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF30A46C).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF30A46C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_lastScanResult!.openPortsCount} OPEN',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF30A46C),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScanStat(
                  'TOTAL SCANNED',
                  '${_lastScanResult!.totalPortsScanned}',
                  Icons.search,
                ),
              ),
              Expanded(
                child: _buildScanStat(
                  'OPEN PORTS',
                  '${_lastScanResult!.openPortsCount}',
                  Icons.lock_open,
                ),
              ),
              Expanded(
                child: _buildScanStat(
                  'SCAN TIME',
                  '${_lastScanResult!.scanDuration.inSeconds}s',
                  Icons.timer,
                ),
              ),
            ],
          ),
          if (_openPorts.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'OPEN PORTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...(_openPorts.take(5).map((port) => _buildPortItem(port))),
            if (_openPorts.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                'And ${_openPorts.length - 5} more ports...',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildScanStat(String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFFD4A574),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortItem(OpenPort port) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: port.isSecure
                  ? const Color(0xFF30A46C)
                  : const Color(0xFFFF9500),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${port.port}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.headlineLarge?.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              port.service,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ),
          if (port.isSecure)
            const Icon(Icons.security, color: Color(0xFF30A46C), size: 16),
        ],
      ),
    );
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

      setState(() {
        _lastScanResult = result;
        _openPorts = result.openPorts;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  void _showPortReferenceDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: theme.cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2C2C2E),
                        Color(0xFF1C1C1E),
                        Color(0xFF2C2C2E),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A574),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.book,
                          color: Color(0xFF2C2C2E),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Port Reference Guide',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dialog Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPortCategory(
                          'Common Secure Ports',
                          'These ports typically use encryption and are generally safe',
                          _getSecurePorts(),
                          const Color(0xFF30A46C),
                        ),
                        const SizedBox(height: 16),
                        _buildPortCategory(
                          'Web Services',
                          'Ports commonly used for web servers and HTTP services',
                          _getWebPorts(),
                          const Color(0xFF007AFF),
                        ),
                        const SizedBox(height: 16),
                        _buildPortCategory(
                          'Database Ports',
                          'Ports used by database management systems',
                          _getDatabasePorts(),
                          const Color(0xFF8E8E93),
                        ),
                        const SizedBox(height: 16),
                        _buildPortCategory(
                          'High Risk Ports',
                          'These ports may pose security risks if exposed',
                          _getHighRiskPorts(),
                          const Color(0xFFFF3B30),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortCategory(
    String title,
    String description,
    List<PortInfo> ports,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.headlineLarge?.color,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...ports.map((port) => _buildPortReferenceItem(port, color)),
        ],
      ),
    );
  }

  Widget _buildPortReferenceItem(PortInfo port, Color color) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${port.port}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  port.service,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.headlineLarge?.color,
                  ),
                ),
                Text(
                  port.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                if (port.riskLevel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRiskColor(
                        port.riskLevel,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${port.riskLevel} Risk',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getRiskColor(port.riskLevel),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF3B30);
      case 'medium':
        return const Color(0xFFFF9500);
      case 'low':
        return const Color(0xFF30A46C);
      default:
        return Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
            const Color(0xFF8E8E93);
    }
  }

  List<PortInfo> _getSecurePorts() {
    return [
      PortInfo(22, 'SSH', 'Secure Shell - encrypted remote access', 'Low'),
      PortInfo(443, 'HTTPS', 'HTTP Secure - encrypted web traffic', 'Low'),
      PortInfo(993, 'IMAPS', 'IMAP over SSL - secure email retrieval', 'Low'),
      PortInfo(995, 'POP3S', 'POP3 over SSL - secure email retrieval', 'Low'),
      PortInfo(465, 'SMTPS', 'SMTP over SSL - secure email sending', 'Low'),
      PortInfo(8443, 'HTTPS-Alt', 'Alternative HTTPS port', 'Low'),
    ];
  }

  List<PortInfo> _getWebPorts() {
    return [
      PortInfo(
        80,
        'HTTP',
        'HyperText Transfer Protocol - web traffic',
        'Medium',
      ),
      PortInfo(8080, 'HTTP-Alt', 'Alternative HTTP port - web proxy', 'Medium'),
      PortInfo(
        8000,
        'HTTP-Alt',
        'Alternative HTTP port - development',
        'Medium',
      ),
      PortInfo(3000, 'HTTP-Dev', 'Development web server', 'Medium'),
      PortInfo(8888, 'HTTP-Alt', 'Alternative HTTP port', 'Medium'),
    ];
  }

  List<PortInfo> _getDatabasePorts() {
    return [
      PortInfo(3306, 'MySQL', 'MySQL Database Server', 'High'),
      PortInfo(5432, 'PostgreSQL', 'PostgreSQL Database Server', 'High'),
      PortInfo(1433, 'MSSQL', 'Microsoft SQL Server', 'High'),
      PortInfo(27017, 'MongoDB', 'MongoDB Database Server', 'High'),
      PortInfo(6379, 'Redis', 'Redis In-Memory Database', 'High'),
      PortInfo(5984, 'CouchDB', 'CouchDB Database Server', 'High'),
    ];
  }

  List<PortInfo> _getHighRiskPorts() {
    return [
      PortInfo(21, 'FTP', 'File Transfer Protocol - unencrypted', 'High'),
      PortInfo(23, 'Telnet', 'Telnet - unencrypted remote access', 'High'),
      PortInfo(135, 'RPC', 'Microsoft RPC - often exploited', 'High'),
      PortInfo(139, 'NetBIOS', 'NetBIOS Session Service', 'High'),
      PortInfo(445, 'SMB', 'Server Message Block - file sharing', 'High'),
      PortInfo(1723, 'PPTP', 'Point-to-Point Tunneling Protocol', 'High'),
    ];
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A574),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2C2C2E),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          backgroundColor: const Color(0xFF2C2C2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  void _showShareErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class PortInfo {
  final int port;
  final String service;
  final String description;
  final String riskLevel;

  PortInfo(this.port, this.service, this.description, this.riskLevel);
}
