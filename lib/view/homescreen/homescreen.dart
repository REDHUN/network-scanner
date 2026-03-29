import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/service/permission_manager/permission_manager.dart';
import 'package:ip_tools/view/devices_screen/devices_screen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:provider/provider.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final networkVM = Provider.of<NetworkViewModel>(
              context,
              listen: false,
            );
            await networkVM.forceRefresh();
          },
          color: const Color(0xFF656CEB),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'DASHBOARD',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Main Network Card
                      Consumer<NetworkViewModel>(
                        builder: (context, vm, _) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF656CEB,
                                  ).withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Stack(
                                children: [
                                  // Background Gradient
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF7076F1), // Lighter purple
                                          Color(0xFF5D64E6), // Deep purple-blue
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Status Row
                                        Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: vm.isNetworkActive
                                                    ? const Color(0xFF4ADE80)
                                                    : Colors.redAccent,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        (vm.isNetworkActive
                                                                ? const Color(
                                                                    0xFF4ADE80,
                                                                  )
                                                                : Colors
                                                                      .redAccent)
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              vm.isNetworkActive
                                                  ? 'CONNECTED'
                                                  : 'DISCONNECTED',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),

                                        // Network Name
                                        Text(
                                          vm.getWifiDisplayName(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Router Info & Details Button
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.router_outlined,
                                                  color: Colors.white70,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  vm.networkInfo?.gateway ??
                                                      'Unknown Router',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Decorative Wifi Icon
                                  Positioned(
                                    top: -20,
                                    right: -20,
                                    child: Icon(
                                      Icons.wifi,
                                      size: 180,
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 36),

                      // Section Title
                      const Text(
                        'NETWORK DETAILS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280),
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Network Details Cards
                      Consumer<NetworkViewModel>(
                        builder: (context, vm, _) {
                          return Column(
                            children: [
                              _buildDetailCard(
                                'Local IP',
                                vm.networkInfo?.wifiIP ?? '-',
                                Icons.account_tree_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildDetailCard(
                                'Gateway',
                                vm.networkInfo?.gateway ?? '-',
                                Icons.mediation_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildDetailCard(
                                'Subnet Mask',
                                vm.networkInfo?.subnet ?? '-',
                                Icons.grid_view_rounded,
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      final hasPermission =
                          await PermissionManager.checkLocationPermissionForFeature(
                            context,
                            featureName: 'Network Scanning',
                          );

                      if (hasPermission && mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DevicesScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF656CEB),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(
                        0xFF656CEB,
                      ).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Start Network Scan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
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

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF656CEB), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _copyToClipboard(value, label),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.copy, color: Color(0xFF9CA3AF), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
