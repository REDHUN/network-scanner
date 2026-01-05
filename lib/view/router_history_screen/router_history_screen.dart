import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jaal/models/storage/router_network_data.dart';
import 'package:jaal/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
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
        print('🔍 Debug: Router ${router.routerId} - ${router.wifiName} (${router.devices.length} devices)');
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
                    'Network History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.headlineLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // Balance the back button
                  
                  // Debug button (remove in production)
                  if (kDebugMode)
                    GestureDetector(
                      onTap: _testDeleteFunctionality,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.bug_report,
                          color: Theme.of(context).textTheme.headlineLarge?.color,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
          Icon(
            Icons.router,
            size: 64,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No Network History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to different networks to see history',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouterList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A574).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Color(0xFFD4A574),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Network History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_routers.length} networks stored',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section Header
          Text(
            'STORED NETWORKS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Router List
          Expanded(
            child: ListView.builder(
              itemCount: _routers.length,
              itemBuilder: (context, index) {
                final router = _routers[index];
                final isCurrent = router.routerId == _currentRouterId;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRouterCard(router, isCurrent),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouterCard(RouterNetworkData router, bool isCurrent) {
    final onlineDevices = router.devices.where((d) => d.isOnline).length;
    final offlineDevices = router.devices.where((d) => !d.isOnline).length;
    final totalDevices = router.devices.length;

    return GestureDetector(
      onTap: () {
        // Show router details or switch to this router
        _showRouterDetails(router, isCurrent);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCurrent 
              ? const Color(0xFF2C2C2E)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: isCurrent 
              ? Border.all(color: const Color(0xFFD4A574), width: 2)
              : null,
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCurrent 
                        ? const Color(0xFFD4A574).withValues(alpha: 0.2)
                        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.router,
                    color: isCurrent 
                        ? const Color(0xFFD4A574)
                        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                                    ? Colors.white
                                    : Theme.of(context).textTheme.headlineLarge?.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4A574),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        router.gatewayIp,
                        style: TextStyle(
                          color: isCurrent 
                              ? Colors.white70
                              : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Device Stats
            Row(
              children: [
                _buildStatChip(
                  'Total',
                  totalDevices.toString(),
                  isCurrent ? Colors.white70 : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  'Online',
                  onlineDevices.toString(),
                  const Color(0xFF30A46C),
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  'Offline',
                  offlineDevices.toString(),
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Last Scan Time
            Text(
              'Last scan: ${_formatDateTime(router.lastScanTime)}',
              style: TextStyle(
                color: isCurrent 
                    ? Colors.white54
                    : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              router.wifiName ?? 'Unknown Network',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gateway: ${router.gatewayIp}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            if (!isCurrent)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _switchToRouter(router.routerId);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Devices'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A574),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeleteRouter(router);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Network Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchToRouter(String routerId) async {
    final scannerVM = context.read<NetworkScannerProvider>();
    await scannerVM.switchToRouter(routerId);
    
    if (mounted) {
      Navigator.pop(context); // Go back to devices screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Switched to network history view'),
          backgroundColor: const Color(0xFFD4A574),
        ),
      );
    }
  }

  void _confirmDeleteRouter(RouterNetworkData router) {
    final isCurrent = router.routerId == _currentRouterId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Network Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete all stored data for "${router.wifiName ?? 'Unknown Network'}"?',
            ),
            const SizedBox(height: 12),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is your current network. Deleting it will clear all current device data.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRouter(router.routerId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDeletingCurrentRouter 
                  ? 'Current network data deleted successfully'
                  : 'Network data deleted successfully'
            ),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete network data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Debug method to test delete functionality
  void _testDeleteFunctionality() async {
    print('🧪 Testing delete functionality...');
    
    try {
      final scannerVM = context.read<NetworkScannerProvider>();
      final allRouters = await scannerVM.getAllRouterNetworks();
      
      print('📊 Current routers before test:');
      for (final router in allRouters) {
        print('   - ${router.routerId}: ${router.wifiName}');
      }
      
      if (allRouters.isNotEmpty) {
        // Test with the first non-current router
        final currentRouterId = await scannerVM.getCurrentRouterId();
        final testRouter = allRouters.firstWhere(
          (r) => r.routerId != currentRouterId,
          orElse: () => allRouters.first,
        );
        
        print('🎯 Testing delete for: ${testRouter.routerId}');
        
        // Show confirmation
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug: Test Delete'),
            content: Text('Delete ${testRouter.wifiName} for testing?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          await scannerVM.deleteRouterData(testRouter.routerId);
          await _loadRouterData();
          print('✅ Test delete completed');
        }
      } else {
        print('⚠️ No routers to test delete');
      }
    } catch (e) {
      print('❌ Test delete failed: $e');
    }
  }
}