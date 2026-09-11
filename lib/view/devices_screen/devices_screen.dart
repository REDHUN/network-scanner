import 'package:flutter/material.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/models/network_model/network_info_model.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';
import 'package:ip_tools/models/storage/router_network_data.dart';
import 'package:ip_tools/service/share_service/share_service.dart';
import 'package:ip_tools/view/device_details_screen/device_details_screen.dart';
import 'package:ip_tools/view/router_history_screen/router_history_screen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:ip_tools/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:provider/provider.dart';

class DevicesScreen extends StatefulWidget {
  final bool autoStartScan;
  const DevicesScreen({super.key, this.autoStartScan = false});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final ShareService _shareService = ShareService();
  String _selectedFilter = 'All'; // 'All', 'Online', 'Offline', 'Gateways'
  String _selectedSort = 'Default'; // 'Default', 'IP', 'Name'
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeScanner();
      }
    });
  }

  void _initializeScanner() async {
    if (!mounted) return;
    final networkVM = context.read<NetworkViewModel>();
    final scannerVM = context.read<NetworkScannerProvider>();

    // Initialize scanner with current network info
    if (networkVM.networkInfo != null) {
      await scannerVM.initializeWithNetworkInfo(networkVM.networkInfo!);
    }

    if (!mounted) return;

    // Start scan immediately on initial open without delay
    if (scannerVM.isFirstApiCall || widget.autoStartScan) {
      scannerVM.isFirstApiCall = false;
      if (mounted) {
        scannerVM.startScan();
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void didUpdateWidget(DevicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.autoStartScan && widget.autoStartScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final scannerVM = context.read<NetworkScannerProvider>();
          scannerVM.startScan();
        }
      });
    }
  }

  String _getSubnetDisplay(NetworkInfoModel? info) {
    if (info == null) return 'Subnet: Scanning...';
    if (info.wifiIP != null && info.subnet != null) {
      try {
        final ipParts = info.wifiIP!.split('.').map(int.parse).toList();
        final subParts = info.subnet!.split('.').map(int.parse).toList();
        if (ipParts.length == 4 && subParts.length == 4) {
          final net = List.generate(4, (i) => (ipParts[i] & subParts[i]));
          final cidr = info.cidr ?? '/24';
          return 'Subnet: ${net.join('.')}$cidr';
        }
      } catch (_) {}
    }
    if (info.wifiIP != null) {
      final parts = info.wifiIP!.split('.');
      if (parts.length == 4) {
        return 'Subnet: ${parts[0]}.${parts[1]}.${parts[2]}.0/24';
      }
    }
    return 'Subnet: 10.0.2.0/24';
  }

  @override
  Widget build(BuildContext context) {
    final networkVM = context.watch<NetworkViewModel>();
    final scannerVM = context.watch<NetworkScannerProvider>();
    final subnetText = _getSubnetDisplay(networkVM.networkInfo);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _buildTopHeader(scannerVM, subnetText),

            // Content
            Expanded(
              child:
                  scannerVM.state == ScanState.error &&
                      scannerVM.devices.isEmpty
                  ? _buildErrorState(scannerVM)
                  : _buildDevicesContent(scannerVM),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(NetworkScannerProvider scannerVM, String subnetText) {
    final isScanning = scannerVM.state == ScanState.scanning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Subnet
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Devices',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subnetText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          // Top Action Buttons
          Row(
            children: [
              // History Icon Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RouterHistoryScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF475569),
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Stop / Scan Pill Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (isScanning) {
                      scannerVM.stopScan();
                    } else {
                      scannerVM.startScan();
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isScanning
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isScanning
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFBFDBFE),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isScanning
                              ? Icons.stop_rounded
                              : Icons.refresh_rounded,
                          size: 16,
                          color: isScanning
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0075FF),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isScanning ? 'Stop' : 'Scan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isScanning
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF0075FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesContent(NetworkScannerProvider provider) {
    final onlineDevices = provider.getOnlineDevices();
    final offlineDevices = provider.getOfflineDevices();
    final allDevices = provider.getAllDevicesWithStatus();
    final gatewayDevices = allDevices.where((d) => d.isGateway).toList();
    final isScanning = provider.state == ScanState.scanning || _isInitializing;

    // Filter devices
    List<StoredDevice> filteredDevices;
    switch (_selectedFilter) {
      case 'Online':
        filteredDevices = onlineDevices;
        break;
      case 'Offline':
        filteredDevices = offlineDevices;
        break;
      case 'Gateways':
        filteredDevices = gatewayDevices;
        break;
      default:
        filteredDevices = allDevices;
        break;
    }

    // Sort devices: Online devices always first, Offline devices always last
    filteredDevices = List.from(filteredDevices);
    filteredDevices.sort((a, b) {
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;

      if (_selectedSort == 'IP') {
        return _compareIp(a.ip, b.ip);
      } else if (_selectedSort == 'Name') {
        return _getDeviceDisplayName(
          a,
        ).toLowerCase().compareTo(_getDeviceDisplayName(b).toLowerCase());
      } else {
        // Default: Self first, then Gateway, then by IP
        if (a.isSelf) return -1;
        if (b.isSelf) return 1;
        if (a.isGateway) return -1;
        if (b.isGateway) return 1;
        return _compareIp(a.ip, b.ip);
      }
    });

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Live Scanning Progress Banner Card (visible only while scanning)
          if (isScanning)
            _buildScanProgressBanner(provider, onlineDevices.length),

          const SizedBox(height: 14),

          // 2. Status Stats Summary Cards (ONLINE & OFFLINE)
          Row(
            children: [
              Expanded(child: _buildOnlineStatCard(onlineDevices.length)),
              const SizedBox(width: 14),
              Expanded(child: _buildOfflineStatCard(offlineDevices.length)),
            ],
          ),

          const SizedBox(height: 18),

          // 3. Filter Tabs Chips
          _buildFilterChipsRow(
            allCount: allDevices.length,
            onlineCount: onlineDevices.length,
            offlineCount: offlineDevices.length,
            gatewaysCount: gatewayDevices.length,
          ),

          const SizedBox(height: 20),

          // 4. Section Header with Live indicator & Sort Menu
          _buildSectionHeader(filteredDevices.length, isScanning),

          const SizedBox(height: 12),

          // 5. Device List
          if (filteredDevices.isEmpty && isScanning)
            _buildInitialScanningState()
          else if (filteredDevices.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDevices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = filteredDevices[index];
                return _buildModernDeviceCard(device);
              },
            ),

          // 6. Probing In-Progress Card (shown while scanning)
          if (isScanning) ...[
            const SizedBox(height: 12),
            _buildProbingCard(provider),
          ],

          const SizedBox(height: 24),

          // 7. Share Scan Results Full-Width Button
          _buildShareButton(allDevices),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  int _compareIp(String a, String b) {
    try {
      final aParts = a.split('.').map(int.parse).toList();
      final bParts = b.split('.').map(int.parse).toList();
      for (int i = 0; i < 4; i++) {
        if (aParts[i] != bParts[i]) {
          return aParts[i].compareTo(bParts[i]);
        }
      }
    } catch (_) {}
    return a.compareTo(b);
  }

  Widget _buildScanProgressBanner(
    NetworkScannerProvider provider,
    int onlineCount,
  ) {
    final percent = (provider.progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFF6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Scanned Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scanning Local Network...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: provider.progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Percentage Circular Badge
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Subtitle Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.scannedCount} of ${provider.totalCount} hosts checked',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$onlineCount found',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStatCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF10B981),
                  size: 12,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ONLINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Count & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineStatCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF94A3B8),
                  size: 12,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'OFFLINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Count & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count > 0 ? '$count past' : 'All linked',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow({
    required int allCount,
    required int onlineCount,
    required int offlineCount,
    required int gatewaysCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', allCount),
          const SizedBox(width: 8),
          _buildFilterChip('Online', onlineCount),
          const SizedBox(width: 8),
          _buildFilterChip('Offline', offlineCount),
          const SizedBox(width: 8),
          _buildFilterChip('Gateways', gatewaysCount),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = label),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int count, bool isScanning) {
    return Row(
      children: [
        Text(
          'DETECTED DEVICES ($count)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        if (isScanning)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.fiber_manual_record,
                  color: Color(0xFF10B981),
                  size: 8,
                ),
                SizedBox(width: 4),
                Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        // Sort Menu
        PopupMenuButton<String>(
          initialValue: _selectedSort,
          onSelected: (val) => setState(() => _selectedSort = val),
          offset: const Offset(0, 36),
          color: Colors.white,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFDBEAFE),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sort: $_selectedSort',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0075FF),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF0075FF),
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            _buildSortMenuItem(
              'Default',
              'Default (Router first)',
              Icons.auto_awesome_rounded,
            ),
            _buildSortMenuItem(
              'IP',
              'IP Address',
              Icons.numbers_rounded,
            ),
            _buildSortMenuItem(
              'Name',
              'Device Name',
              Icons.sort_by_alpha_rounded,
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedSort == value;
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF0075FF)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0075FF)
                      : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Color(0xFF0075FF),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDeviceCard(StoredDevice device) {
    final displayName = _getDeviceDisplayName(device);
    final isGateway = device.isGateway;
    final isSelf = device.isSelf;

    // Role badge
    final String roleTag;
    final Color roleBg;
    final Color roleTextColor;

    if (isSelf) {
      roleTag = 'You';
      roleBg = const Color(0xFFEEF2FF);
      roleTextColor = const Color(0xFF4F46E5);
    } else if (isGateway) {
      roleTag = 'Gateway';
      roleBg = const Color(0xFFFAF5FF);
      roleTextColor = const Color(0xFF9333EA);
    } else {
      roleTag = 'Node';
      roleBg = const Color(0xFFF1F5F9);
      roleTextColor = const Color(0xFF64748B);
    }

    final iconData = _getDeviceIcon(device);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailsScreen(
                device: device.toScannedDevice(),
                isOnline: device.isOnline,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelf
                      ? const Color(0xFFEEF2FF)
                      : isGateway
                      ? const Color(0xFFFAF5FF)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  iconData,
                  color: isSelf
                      ? const Color(0xFF4F46E5)
                      : isGateway
                      ? const Color(0xFF9333EA)
                      : const Color(0xFF64748B),
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // Device Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Role Badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            roleTag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: roleTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Subtitle: IP • Connection info
                    Row(
                      children: [
                        Text(
                          device.ip,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isGateway
                              ? Icons.settings_ethernet_rounded
                              : Icons.wifi_rounded,
                          size: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status Dot, Delete Button & Arrow
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!device.isOnline) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete offline device',
                      onPressed: () =>
                          _confirmDeleteOfflineDevice(context, device),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: device.isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFFCBD5E1),
                      shape: BoxShape.circle,
                      boxShadow: device.isOnline
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProbingCard(NetworkScannerProvider provider) {
    final nextHost = (provider.scannedCount + 1).clamp(1, 254);
    final prefix = _getIpPrefix(provider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
      ),
      child: Row(
        children: [
          // Spinner
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),

          const SizedBox(width: 14),

          // Probing details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Probing $prefix.$nextHost...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Testing ARP & socket probes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // In Progress Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'In progress',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIpPrefix(NetworkScannerProvider provider) {
    if (provider.currentNetworkInfo?.wifiIP != null) {
      final parts = provider.currentNetworkInfo!.wifiIP!.split('.');
      if (parts.length == 4) {
        return '${parts[0]}.${parts[1]}.${parts[2]}';
      }
    }
    return '10.0.2';
  }

  Widget _buildShareButton(List<StoredDevice> allDevices) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final scanned = allDevices.map((d) => d.toScannedDevice()).toList();
            _shareNetworkSummary(scanned);
          },
          borderRadius: BorderRadius.circular(18),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Share Scan Results',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialScanningState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: const [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Scanning network...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Discovering connected hosts on your LAN',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: const [
            Icon(
              Icons.devices_other_rounded,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 14),
            Text(
              'No devices found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap Scan above to discover devices on your LAN',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(NetworkScannerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            const Text(
              'Scan Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.error ?? 'Unable to scan network devices.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => provider.startScan(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDeviceDisplayName(StoredDevice device) {
    if (device.isSelf) return 'This Device';
    if (device.isGateway) return 'Home Router';
    if (device.mdns != null && device.mdns!.isNotEmpty) return device.mdns!;
    if (device.name != null &&
        device.name!.isNotEmpty &&
        !device.name!.startsWith('Device (')) {
      return device.name!;
    }
    return 'Desktop PC';
  }

  IconData _getDeviceIcon(StoredDevice device) {
    if (device.isSelf) return Icons.smartphone_rounded;
    if (device.isGateway) return Icons.router_rounded;
    final nameLower = (device.name ?? device.mdns ?? '').toLowerCase();
    if (nameLower.contains('macbook') || nameLower.contains('laptop')) {
      return Icons.laptop_mac_rounded;
    }
    if (nameLower.contains('iphone') || nameLower.contains('android')) {
      return Icons.phone_iphone_rounded;
    }
    if (nameLower.contains('tv')) return Icons.tv_rounded;
    if (nameLower.contains('printer')) return Icons.print_rounded;
    return Icons.desktop_windows_rounded;
  }

  void _confirmDeleteOfflineDevice(BuildContext context, StoredDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trash Icon Badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),

              const SizedBox(height: 18),

              // Title
              const Text(
                'Delete Offline Device',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 10),

              // Description
              Text(
                'Are you sure you want to remove ${_getDeviceDisplayName(device)} (${device.ip}) from your saved offline devices?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons Row
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Delete Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context
                            .read<NetworkScannerProvider>()
                            .deleteOfflineDevice(device.ip);
                        SnackbarUtils.showSuccess(
                          context,
                          'Device ${device.ip} removed from storage',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareNetworkSummary(List<ScannedDevice> devices) async {
    try {
      await _shareService.shareNetworkSummary(devices, null);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to share: ${e.toString()}');
      }
    }
  }
}
