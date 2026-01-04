import 'package:flutter/material.dart';
import 'package:netra/models/network_model/scanned_device.dart';
import 'package:netra/service/share_service/share_service.dart';
import 'package:netra/view/device_details_screen/device_details_screen.dart';
import 'package:netra/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:provider/provider.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String _selectedFilter = 'All';
  final ShareService _shareService = ShareService();

  @override
  void initState() {
    super.initState();
    initFunction();
  }

  void initFunction() {
    final networkScannerProvider = context.read<NetworkScannerProvider>();

    // Delay the scan start to allow navigation to complete smoothly
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          networkScannerProvider.startScan();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).textTheme.headlineLarge?.color,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Devices',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.headlineLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Consumer<NetworkScannerProvider>(
                        builder: (context, provider, _) {
                          return GestureDetector(
                            onTap: () async {
                              if (provider.state != ScanState.scanning) {
                                Future.microtask(() => provider.startScan());
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: provider.state == ScanState.scanning
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.headlineLarge?.color,
                                      size: 24,
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // Settings or filter action
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.settings,
                            color: Theme.of(
                              context,
                            ).textTheme.headlineLarge?.color,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Consumer<NetworkScannerProvider>(
                  builder: (context, provider, _) {
                    if (provider.state == ScanState.scanning) {
                      return _buildScanningState();
                    } else if (provider.state == ScanState.error) {
                      return _buildErrorState(provider);
                    } else {
                      return _buildDevicesList(provider);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scanning network...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(NetworkScannerProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF3B30)),
          const SizedBox(height: 16),
          Text(
            'Scan failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => provider.startScan(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList(NetworkScannerProvider provider) {
    final devices = provider.devices;
    final onlineDevices =
        devices.length; // Assume all scanned devices are online
    final offlineDevices = 0; // For demo purposes

    return Column(
      children: [
        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Online',
                count: onlineDevices,
                subtitle: 'Devices active',
                isOnline: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Offline',
                count: offlineDevices,
                subtitle: 'Last 24 hours',
                isOnline: false,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Filter Tabs
        Row(
          children: [
            _buildFilterTab('All', devices.length),
            const SizedBox(width: 12),
            _buildFilterTab('Online', onlineDevices),
            const SizedBox(width: 12),
            _buildFilterTab('Offline', offlineDevices),
          ],
        ),

        const SizedBox(height: 24),

        // Section Header
        Row(
          children: [
            Text(
              'CONNECTED DEVICES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              'Sort by Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Device List
        Expanded(
          child: devices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDeviceCard(device),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required String subtitle,
    required bool isOnline,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFF2C2C2E)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                color: isOnline
                    ? const Color(0xFFD4A574)
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isOnline
                      ? const Color(0xFFD4A574)
                      : Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              color: isOnline
                  ? Colors.white
                  : Theme.of(context).textTheme.headlineLarge?.color,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isOnline
                  ? Colors.white70
                  : Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, int count) {
    final isSelected = _selectedFilter == title;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2C2C2E)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(ScannedDevice device) {
    final isOnline = true; // Assume all scanned devices are online

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetailsScreen(device: device),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isOnline
              ? const Color(0xFF2C2C2E)
              : Theme.of(context).cardTheme.color?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Device Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOnline
                    ? Colors.white.withValues(alpha: 0.1)
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getDeviceIcon(device),
                color: isOnline
                    ? Colors.white
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // Device Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDeviceName(device),
                    style: TextStyle(
                      color: isOnline
                          ? Colors.white
                          : Theme.of(context).textTheme.headlineLarge?.color
                                ?.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        device.ip,
                        style: TextStyle(
                          color: isOnline
                              ? Colors.white70
                              : Theme.of(context).textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _getConnectionType(device),
                        style: TextStyle(
                          color: isOnline
                              ? Colors.white70
                              : Theme.of(context).textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Indicators
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFFD4A574)
                        : Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: isOnline
                      ? Colors.white70
                      : Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the refresh button to scan for devices',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(ScannedDevice device) {
    if (device.isGateway) return Icons.router;
    if (device.isSelf) return Icons.smartphone;
    if (device.name?.toLowerCase().contains('macbook') == true)
      return Icons.laptop_mac;
    if (device.name?.toLowerCase().contains('iphone') == true)
      return Icons.phone_iphone;
    if (device.name?.toLowerCase().contains('tv') == true) return Icons.tv;
    if (device.name?.toLowerCase().contains('gaming') == true)
      return Icons.sports_esports;
    if (device.name?.toLowerCase().contains('printer') == true)
      return Icons.print;
    return Icons.devices;
  }

  String _getDeviceName(ScannedDevice device) {
    if (device.isGateway) return 'Home Router';
    if (device.isSelf) return 'This Device';
    return device.displayName;
  }

  String _getConnectionType(ScannedDevice device) {
    if (device.isGateway) return '5GHz';
    if (device.name?.toLowerCase().contains('gaming') == true) return 'Gigabit';
    if (device.name?.toLowerCase().contains('iphone') == true) return 'WiFi 6';
    return 'WiFi';
  }

  Future<void> _shareNetworkSummary(List<ScannedDevice> devices) async {
    try {
      await _shareService.shareNetworkSummary(devices, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Network summary shared successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF30A46C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }
}
