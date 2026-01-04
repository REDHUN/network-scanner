import 'package:flutter/material.dart';
import 'package:netra/models/network_model/scanned_device.dart';
import 'package:netra/view/device_details_screen/device_details_screen.dart';
import 'package:netra/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:netra/service/share_service/share_service.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Devices',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.headlineLarge?.color,
                          ),
                        ),
                        Consumer<NetworkScannerProvider>(
                          builder: (context, provider, _) {
                            final deviceCount = provider.devices.length;
                            return Text(
                              '$deviceCount devices found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Consumer<NetworkScannerProvider>(
                    builder: (context, provider, _) {
                      return Row(
                        children: [
                          // Share button
                          GestureDetector(
                            onTap: provider.devices.isNotEmpty
                                ? () => _shareNetworkSummary(provider.devices)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? 0.2
                                          : 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.share,
                                color: provider.devices.isNotEmpty
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.3),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Refresh button
                          GestureDetector(
                            onTap: () async {
                              if (provider.state != ScanState.scanning) {
                                // Use Future.microtask to prevent UI blocking
                                Future.microtask(() => provider.startScan());
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? 0.2
                                          : 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
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
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Consumer<NetworkScannerProvider>(
                  builder: (context, provider, _) {
                    return provider.state == ScanState.scanning
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              child: const CircularProgressIndicator(),
                            ),
                          )
                        : provider.state == ScanState.error
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scan failed',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      Text(
                                        provider.error ?? 'Unknown error',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Network Overview Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Network Overview',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color
                                                  ?.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.circle,
                                                color: Color(0xFF10B981),
                                                size: 8,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '7 Online',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge?.color,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(
                                                Icons.circle,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color
                                                    ?.withValues(alpha: 0.7),
                                                size: 8,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '1 Offline',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF374151)
                                            : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.filter_list,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Filter Tabs
                              Row(
                                children: [
                                  _buildFilterTab(
                                    'All',
                                    _selectedFilter == 'All',
                                  ),
                                  const SizedBox(width: 12),
                                  _buildFilterTab(
                                    'Online',
                                    _selectedFilter == 'Online',
                                  ),
                                  const SizedBox(width: 12),
                                  _buildFilterTab(
                                    'Offline',
                                    _selectedFilter == 'Offline',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Devices List
                              Expanded(
                                child: Consumer<NetworkScannerProvider>(
                                  builder: (context, scannerVM, child) {
                                    if (scannerVM.devices.isEmpty) {
                                      return _buildEmptyState();
                                    }

                                    return ListView.separated(
                                      itemCount: _getFilteredDevices(
                                        scannerVM.devices,
                                      ).length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final device = _getFilteredDevices(
                                          scannerVM.devices,
                                        )[index];
                                        return _buildDeviceCard(device);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isSelected) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
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
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(ScannedDevice device) {
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.2
                    : 0.05,
              ),
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
                color: _getDeviceColor(device),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getDeviceIcon(device),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDeviceName(device),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.ip,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDeviceManufacturer(device),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConnectionTypeColor(device),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getConnectionType(device),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF06B6D4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  size: 20,
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
          const SizedBox(height: 24),
          Consumer<NetworkScannerProvider>(
            builder: (context, provider, _) {
              return ElevatedButton.icon(
                onPressed: provider.state == ScanState.scanning
                    ? null
                    : () => Future.microtask(() => provider.startScan()),
                icon: provider.state == ScanState.scanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find),
                label: Text(
                  provider.state == ScanState.scanning
                      ? 'Scanning...'
                      : 'Start Scan',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<ScannedDevice> _getFilteredDevices(List<ScannedDevice> devices) {
    // For demo purposes, return all devices
    // In real implementation, filter based on _selectedFilter
    return devices;
  }

  Color _getDeviceColor(ScannedDevice device) {
    if (device.isGateway) return const Color(0xFF6366F1);
    if (device.isSelf) return const Color(0xFF8B5CF6);
    if (device.name?.toLowerCase().contains('iphone') == true) {
      return const Color(0xFF8B5CF6);
    }
    if (device.name?.toLowerCase().contains('macbook') == true) {
      return const Color(0xFF06B6D4);
    }
    if (device.name?.toLowerCase().contains('tv') == true) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF3B82F6);
  }

  IconData _getDeviceIcon(ScannedDevice device) {
    if (device.isGateway) return Icons.router;
    if (device.isSelf) return Icons.smartphone;
    if (device.name?.toLowerCase().contains('iphone') == true) {
      return Icons.phone_iphone;
    }
    if (device.name?.toLowerCase().contains('macbook') == true) {
      return Icons.laptop_mac;
    }
    if (device.name?.toLowerCase().contains('tv') == true) return Icons.tv;
    return Icons.computer;
  }

  String _getDeviceName(ScannedDevice device) {
    if (device.isGateway) return 'Home Router';
    if (device.isSelf) return 'This Device';
    if (device.name?.toLowerCase().contains('iphone') == true) {
      return 'iPhone 14 Pro';
    }
    if (device.name?.toLowerCase().contains('macbook') == true) {
      return 'MacBook Pro';
    }
    if (device.name?.toLowerCase().contains('tv') == true) return 'Smart TV';
    return device.displayName;
  }

  String _getDeviceManufacturer(ScannedDevice device) {
    if (device.isGateway) return 'TP-Link';
    if (device.name?.toLowerCase().contains('iphone') == true) {
      return 'Apple Inc.';
    }
    if (device.name?.toLowerCase().contains('macbook') == true) {
      return 'Apple Inc.';
    }
    if (device.name?.toLowerCase().contains('tv') == true) return 'Samsung';
    return 'Intel Corporation';
  }

  String _getConnectionType(ScannedDevice device) {
    if (device.isGateway) return 'LAN';
    return 'Wi-Fi';
  }

  Color _getConnectionTypeColor(ScannedDevice device) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF0F3460) // Dark blue for dark theme
        : const Color(0xFFDCFCE7); // Light green for light theme
  }

  Future<void> _shareNetworkSummary(List<ScannedDevice> devices) async {
    try {
      await _shareService.shareNetworkSummary(devices, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Network summary shared successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
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
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
