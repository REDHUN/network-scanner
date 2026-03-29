import 'package:flutter/material.dart';
import 'package:ip_tools/models/storage/router_network_data.dart';
import 'package:ip_tools/view/device_details_screen/device_details_screen.dart';

class HistoryDevicesScreen extends StatefulWidget {
  final RouterNetworkData router;

  const HistoryDevicesScreen({super.key, required this.router});

  @override
  State<HistoryDevicesScreen> createState() => _HistoryDevicesScreenState();
}

class _HistoryDevicesScreenState extends State<HistoryDevicesScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final allDevices = widget.router.devices;
    final onlineDevices = allDevices.where((d) => d.isOnline).toList();
    final offlineDevices = allDevices.where((d) => !d.isOnline).toList();

    List<StoredDevice> filteredDevices;
    switch (_selectedFilter) {
      case 'Online':
        filteredDevices = onlineDevices;
        break;
      case 'Offline':
        filteredDevices = offlineDevices;
        break;
      default:
        filteredDevices = allDevices;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF656CEB),
                        size: 26,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.router.wifiName ?? 'Unknown Network',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'History Devices',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top Divider
            Divider(
              height: 1,
              color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'ONLINE',
                            count: onlineDevices.length,
                            isOnline: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            title: 'OFFLINE',
                            count: offlineDevices.length,
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

                    const SizedBox(height: 32),

                    // Section Header
                    Row(
                      children: [
                        Text(
                          _selectedFilter == 'All'
                              ? 'STORED DEVICES'
                              : _selectedFilter == 'Online'
                              ? 'ONLINE DEVICES'
                              : 'OFFLINE DEVICES',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Device List
                    filteredDevices.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredDevices.length,
                            itemBuilder: (context, index) {
                              final device = filteredDevices[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildStoredDeviceCard(device),
                              );
                            },
                          ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required bool isOnline,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
        ),
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
              Icon(
                isOnline ? Icons.check_circle : Icons.cancel,
                color: isOnline
                    ? const Color(0xFF10B981)
                    : const Color(0xFF9CA3AF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isOnline
                      ? const Color(0xFF10B981)
                      : const Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1,
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
          color: isSelected ? const Color(0xFF656CEB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF111827)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStoredDeviceCard(StoredDevice device) {
    final backgroundColor = device.isOnline
        ? Colors.white
        : const Color(0xFFF3F4F6);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetailsScreen(
              device: device.toScannedDevice(),
              isOnline: device.isOnline,
              isHistory: true,
              lastSeen: device.lastSeen,
              historicalPortScanResult: device.portScanResult,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: device.isOnline
              ? null
              : Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: device.isOnline ? 0.03 : 0.0,
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: device.isOnline
                    ? const Color(0xFFEEEDFF)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getStoredDeviceIcon(device),
                color: device.isOnline
                    ? const Color(0xFF656CEB)
                    : const Color(0xFF6B7280),
                size: 24,
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
                      Flexible(
                        child: Text(
                          _getStoredDeviceName(device),
                          style: TextStyle(
                            color: device.isOnline
                                ? const Color(0xFF111827)
                                : const Color(0xFF4B5563),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: device.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFF9CA3AF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getConnectionIcon(device),
                        size: 14,
                        color: device.isOnline
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_getStoredConnectionType(device)}  •  ${device.ip}',
                        style: TextStyle(
                          color: device.isOnline
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chevron trailing
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 24),
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
          const SizedBox(height: 40),
          Icon(
            Icons.devices_other,
            size: 64,
            color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No devices stored',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
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
    if (device.name?.toLowerCase().contains('work station') == true ||
        device.name?.toLowerCase().contains('desktop') == true)
      return Icons.desktop_windows;
    if (device.name?.toLowerCase().contains('tv') == true) return Icons.tv;
    if (device.name?.toLowerCase().contains('gaming') == true)
      return Icons.sports_esports;
    if (device.name?.toLowerCase().contains('printer') == true)
      return Icons.print;
    return Icons.devices;
  }

  IconData _getConnectionIcon(StoredDevice device) {
    if (device.isGateway ||
        _getStoredConnectionType(device).toLowerCase().contains('ethernet')) {
      return Icons.settings_ethernet;
    }
    return Icons.wifi;
  }

  String _getStoredDeviceName(StoredDevice device) {
    if (device.isGateway) return 'Home Router';
    if (device.isSelf) return 'This Device';
    if (device.mdns != null) return device.mdns!;
    if (device.name != null) return device.name!;
    return 'Unknown Device';
  }

  String _getStoredConnectionType(StoredDevice device) {
    if (device.isGateway ||
        device.name?.toLowerCase().contains('work station') == true)
      return 'Ethernet';
    return 'WiFi';
  }
}
