import 'package:flutter/material.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/models/storage/router_network_data.dart';
import 'package:ip_tools/view/history_devices_screen/history_devices_screen.dart';
import 'package:ip_tools/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
import 'package:provider/provider.dart';

class RouterHistoryScreen extends StatefulWidget {
  const RouterHistoryScreen({super.key});

  @override
  State<RouterHistoryScreen> createState() => _RouterHistoryScreenState();
}

class _RouterHistoryScreenState extends State<RouterHistoryScreen> {
  List<RouterNetworkData> _routers = [];
  String? _currentRouterId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouterData();
  }

  Future<void> _loadRouterData() async {
    final scannerVM = context.read<NetworkScannerProvider>();

    try {
      setState(() {
        _isLoading = true;
      });

      final routers = await scannerVM.getAllRouterNetworks();
      final currentRouterId = await scannerVM.getCurrentRouterId();

      print('🔍 Debug: Loaded ${routers.length} routers');
      print('🔍 Debug: Current router ID: $currentRouterId');
      for (final router in routers) {
        print(
          '🔍 Debug: Router ${router.routerId} - ${router.wifiName} (${router.devices.length} devices)',
        );
      }

      setState(() {
        _routers = routers;
        _currentRouterId = currentRouterId;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading router data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  if (Navigator.canPop(context))
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
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      letterSpacing: -0.5,
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF656CEB),
                        ),
                      ),
                    )
                  : _routers.isEmpty
                  ? _buildEmptyState()
                  : _buildRouterList(),
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
          const SizedBox(height: 40),
          Icon(
            Icons.router,
            size: 64,
            color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Network History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to different networks to see history',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF6B7280).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouterList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Color(0xFF656CEB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stored Networks',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_routers.length} networks found',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Section Header
          const Text(
            'NETWORK HISTORY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Router List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _routers.length,
            itemBuilder: (context, index) {
              final router = _routers[index];
              final isCurrent = router.routerId == _currentRouterId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRouterCard(router, isCurrent),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRouterCard(RouterNetworkData router, bool isCurrent) {
    final onlineDevices = router.devices.where((d) => d.isOnline).length;
    final offlineDevices = router.devices.where((d) => !d.isOnline).length;
    final totalDevices = router.devices.length;

    // The current network gets a slightly highlighted border or background
    final backgroundColor = isCurrent ? Colors.white : const Color(0xFFF9FAFB);

    return GestureDetector(
      onTap: () {
        // Show router details or switch to this router
        _showRouterDetails(router, isCurrent);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: isCurrent
              ? Border.all(
                  color: const Color(0xFF656CEB).withValues(alpha: 0.3),
                  width: 2,
                )
              : Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isCurrent ? 0.04 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFFEEEDFF)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.router,
                    color: isCurrent
                        ? const Color(0xFF656CEB)
                        : const Color(0xFF6B7280),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              router.wifiName ?? 'Unknown Network',
                              style: TextStyle(
                                color: isCurrent
                                    ? const Color(0xFF111827)
                                    : const Color(0xFF4B5563),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        router.gatewayIp,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Device Stats
            Row(
              children: [
                _buildStatChip(
                  'Total',
                  totalDevices.toString(),
                  const Color(0xFF4B5563),
                  const Color(0xFFF3F4F6),
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  'Online',
                  onlineDevices.toString(),
                  const Color(0xFF10B981),
                  const Color(0xFF10B981).withValues(alpha: 0.1),
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  'Offline',
                  offlineDevices.toString(),
                  const Color(0xFF9CA3AF),
                  const Color(0xFFF3F4F6), // offline devices gray background
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Last Scan Time
            Text(
              'Last scan: ${_formatDateTime(router.lastScanTime)}',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
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

  void _showRouterDetails(RouterNetworkData router, bool isCurrent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              router.wifiName ?? 'Unknown Network',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gateway: ${router.gatewayIp}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            if (!isCurrent)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HistoryDevicesScreen(router: router),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text(
                    'View Devices',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF656CEB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

            if (!isCurrent) const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeleteRouter(router);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  'Delete Network Data',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRouter(RouterNetworkData router) {
    final isCurrent = router.routerId == _currentRouterId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Network Data',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete all stored data for "${router.wifiName ?? 'Unknown Network'}"?',
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 15),
            ),
            const SizedBox(height: 16),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED), // orange 50
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFEDD5), // orange 100
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF97316),
                      size: 24,
                    ), // orange 500
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is your current network. Deleting it will clear all current device data.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isCurrent) const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRouter(router.routerId);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteRouter(String routerId) async {
    print('🗑️ Starting deletion process for router: $routerId');

    try {
      final scannerVM = context.read<NetworkScannerProvider>();

      // Check if we're deleting the current router
      final currentRouterId = await scannerVM.getCurrentRouterId();
      final isDeletingCurrentRouter = currentRouterId == routerId;

      print('🔍 Current router ID: $currentRouterId');
      print('🔍 Is deleting current router: $isDeletingCurrentRouter');

      // Call the storage service to delete router data
      await scannerVM.deleteRouterData(routerId);
      print('✅ Storage service delete completed');

      // Refresh the router list
      await _loadRouterData();
      print('✅ Router list refreshed');

      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          isDeletingCurrentRouter
              ? 'Current network data deleted successfully'
              : 'Network data deleted successfully',
        );

        // If we deleted the current router, go back to devices screen
        if (isDeletingCurrentRouter) {
          print('🔄 Navigating back to devices screen');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('❌ Error in delete process: $e');
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to delete network data: $e');
      }
    }
  }
}
