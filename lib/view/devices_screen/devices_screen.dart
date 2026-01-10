import 'package:flutter/material.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';
import 'package:ip_tools/models/storage/router_network_data.dart';
import 'package:ip_tools/service/share_service/share_service.dart';
import 'package:ip_tools/view/device_details_screen/device_details_screen.dart';
import 'package:ip_tools/view/router_history_screen/router_history_screen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:ip_tools/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
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
    _initializeScanner();
  }

  void _initializeScanner() async {
    final networkVM = context.read<NetworkViewModel>();
    final scannerVM = context.read<NetworkScannerProvider>();

    // Initialize scanner with current network info
    if (networkVM.networkInfo != null) {
      await scannerVM.initializeWithNetworkInfo(networkVM.networkInfo!);
    }

    // Start scan after initialization
    if (scannerVM.isFirstApiCall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            scannerVM.startScan();
            scannerVM.isFirstApiCall = false;
          }
        });
      });
    }
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
                                  ? SizedBox()
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
                      Consumer<NetworkScannerProvider>(
                        builder: (context, provider, _) {
                          return GestureDetector(
                            onTap: provider.devices.isNotEmpty
                                ? () => _shareNetworkSummary(provider.devices)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: provider.devices.isNotEmpty
                                  ? BoxDecoration(
                                      color: const Color(
                                        0xFFD4A574,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              child: Icon(
                                Icons.share,
                                color: provider.devices.isNotEmpty
                                    ? const Color(0xFFD4A574)
                                    : Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.color
                                          ?.withValues(alpha: 0.3),
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RouterHistoryScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.history,
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
    final onlineDevices = provider.getOnlineDevices();
    final offlineDevices = provider.getOfflineDevices();
    final allDevices = provider.getAllDevicesWithStatus();

    // Filter devices based on selected filter
    List<StoredDevice> filteredDevices;
    switch (_selectedFilter) {
      case 'Online':
        filteredDevices = allDevices.where((d) => d.isOnline).toList();
        break;
      case 'Offline':
        filteredDevices = allDevices.where((d) => !d.isOnline).toList();
        break;
      default:
        filteredDevices = allDevices;
    }

    return Column(
      children: [
        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Online',
                count: onlineDevices.length,
                subtitle: 'Devices active',
                isOnline: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Offline',
                count: offlineDevices.length,
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
            _buildFilterTab('All', allDevices.length),
            const SizedBox(width: 12),
            _buildFilterTab('Online', onlineDevices.length),
            const SizedBox(width: 12),
            _buildFilterTab('Offline', offlineDevices.length),
          ],
        ),

        const SizedBox(height: 24),

        // Router Change Notification
        if (provider.hasRouterChanged)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A574).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4A574).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi, color: const Color(0xFFD4A574), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connected to different network. Loading stored data...',
                    style: TextStyle(
                      color: const Color(0xFFD4A574),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Section Header
        Row(
          children: [
            Text(
              _selectedFilter == 'All'
                  ? 'ALL DEVICES'
                  : _selectedFilter == 'Online'
                  ? 'ONLINE DEVICES'
                  : 'OFFLINE DEVICES',
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
          child: filteredDevices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: filteredDevices.length,
                  itemBuilder: (context, index) {
                    final device = filteredDevices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildStoredDeviceCard(device),
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

  Widget _buildStoredDeviceCard(StoredDevice device) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DeviceDetailsScreen(device: device.toScannedDevice()),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: device.isOnline
              ? const Color(0xFF2C2C2E)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: device.isOnline
              ? null
              : Border.all(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.2) ??
                      Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: device.isOnline ? 0.1 : 0.05,
              ),
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
                color: device.isOnline
                    ? Colors.white.withValues(alpha: 0.1)
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStoredDeviceIcon(device),
                color: device.isOnline
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getStoredDeviceName(device),
                          style: TextStyle(
                            color: device.isOnline
                                ? Colors.white
                                : Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.color
                                      ?.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!device.isOnline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OFFLINE',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        device.ip,
                        style: TextStyle(
                          color: device.isOnline
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
                        _getStoredConnectionType(device),
                        style: TextStyle(
                          color: device.isOnline
                              ? Colors.white70
                              : Theme.of(context).textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  if (!device.isOnline)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Last seen: ${_formatLastSeen(device.lastSeen)}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
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
                    color: device.isOnline
                        ? const Color(0xFFD4A574)
                        : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  device.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: device.isOnline
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

  IconData _getStoredDeviceIcon(StoredDevice device) {
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

  String _getStoredDeviceName(StoredDevice device) {
    if (device.isGateway) return 'Home Router';
    if (device.isSelf) return 'This Device';
    if (device.mdns != null) return device.mdns!;
    if (device.name != null) return device.name!;
    return 'Unknown Device';
  }

  String _getStoredConnectionType(StoredDevice device) {
    if (device.isGateway) return '';
    if (device.name?.toLowerCase().contains('gaming') == true) return 'Gigabit';
    if (device.name?.toLowerCase().contains('iphone') == true) return 'WiFi 6';
    return 'WiFi';
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
