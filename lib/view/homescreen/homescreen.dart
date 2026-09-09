import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/service/permission_manager/permission_manager.dart';
import 'package:ip_tools/view/devices_screen/devices_screen.dart';
import 'package:ip_tools/view/main_navigation/main_navigation.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:provider/provider.dart';

class Homescreen extends StatefulWidget {
  final VoidCallback? onStartScan;
  const Homescreen({super.key, this.onStartScan});

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
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: vm.isLocationActionNeeded
                                                ? 20
                                                : 32,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        if (vm.isLocationActionNeeded) ...[
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                vm.enableLocation(),
                                            icon: const Icon(
                                              Icons.location_on_rounded,
                                              size: 18,
                                              color: Color(0xFF5D64E6),
                                            ),
                                            label: Text(
                                              vm.locationActionLabel,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF5D64E6),
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(
                                                0xFF5D64E6,
                                              ),
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ],
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

                      // Section 1: WI-FI DETAILS
                      const Text(
                        'WI-FI DETAILS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Consumer<NetworkViewModel>(
                        builder: (context, vm, _) {
                          final info = vm.networkInfo;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildTableRow(
                                  icon: Icons.public,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'WiFi State:',
                                  customValueWidget: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: vm.isNetworkActive
                                              ? const Color(0xFF22C55E)
                                              : Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        vm.isNetworkActive
                                            ? 'Online'
                                            : 'Offline',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: vm.isNetworkActive
                                              ? const Color(0xFF16A34A)
                                              : Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: vm.isNetworkActive
                                      ? 'Online'
                                      : 'Offline',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.public,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Timezone:',
                                  value: info?.timezone ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.wifi,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'SSID:',
                                  value: info?.wifiName ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.public,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'ISP:',
                                  value: info?.isp ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.business,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Organization:',
                                  value: info?.organization ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.wifi,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'BSSID:',
                                  value: (info?.bssid != null &&
                                          info!.bssid!.isNotEmpty &&
                                          info.bssid != 'null')
                                      ? info.bssid!
                                      : 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.cell_tower,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'WiFi Broadcast:',
                                  value: info?.resolvedBroadcast ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.scatter_plot,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Subnet Mask:',
                                  value: info?.subnet != null
                                      ? '${info!.subnet}${info.cidr != null ? ' (${info.cidr})' : ''}'
                                      : 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.dns_outlined,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Default Gateway IP:',
                                  value: info?.gateway ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.public,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'IPv4:',
                                  value: info?.wifiIP ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.public,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'IPv6:',
                                  value: (info?.ipv6 != null &&
                                          info!.ipv6!.isNotEmpty &&
                                          info.ipv6 != 'null')
                                      ? info.ipv6!
                                      : 'N/A',
                                  showDivider: false,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // Section 2: LOCATION & PROVIDER DETAILS
                      const Text(
                        'LOCATION & PROVIDER DETAILS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Consumer<NetworkViewModel>(
                        builder: (context, vm, _) {
                          final info = vm.networkInfo;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildTableRow(
                                  icon: Icons.location_city,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'City:',
                                  value: info?.city ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.map_outlined,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Region:',
                                  value: info?.region ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.flag_outlined,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Country:',
                                  value: info?.country ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.explore_outlined,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Coordinates (Provider):',
                                  value: info?.coordinatesDisplay ?? 'N/A',
                                  showDivider: false,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // Section 3: NETWORK HOST & CONFIGURATION
                      const Text(
                        'HOST & NETWORK CONFIGURATION',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Consumer<NetworkViewModel>(
                        builder: (context, vm, _) {
                          final info = vm.networkInfo;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildTableRow(
                                  icon: Icons.lan_outlined,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Host (Public IP):',
                                  value: info?.publicIp ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.computer_outlined,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Localhost:',
                                  value: info?.localhost ?? '127.0.0.1',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.hub_outlined,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'ASN:',
                                  value: info?.asn ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.wifi,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Connection type:',
                                  value: info?.connectionType ?? 'WIFI',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.swap_horiz,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Usable IP Range:',
                                  value: info?.ipRange ?? 'N/A',
                                  showDivider: true,
                                ),
                                _buildTableRow(
                                  icon: Icons.devices,
                                  iconColor: const Color(0xFF38BDF8),
                                  label: 'Host Capacity:',
                                  value: info?.totalHosts ?? 'N/A',
                                  showDivider: false,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
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

                      if (!context.mounted) return;
                      if (hasPermission) {
                        if (widget.onStartScan != null) {
                          widget.onStartScan!();
                        } else {
                          final mainNav =
                              context.findAncestorStateOfType<MainNavigationState>();
                          if (mainNav != null) {
                            mainNav.switchTab(1, autoStartScan: true);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DevicesScreen(autoStartScan: true),
                              ),
                            );
                          }
                        }
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

  Widget _buildTableRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Widget? customValueWidget,
    bool showDivider = true,
  }) {
    final bool isNA = value == 'N/A' || value == '-' || value.isEmpty;

    return Column(
      children: [
        InkWell(
          onTap: isNA ? null : () => _copyToClipboard(value, label.replaceAll(':', '')),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
                const SizedBox(width: 14),

                // Label
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 12),

                // Value
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: customValueWidget ??
                        Text(
                          value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isNA
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Color(0xFFF3F4F6),
          ),
      ],
    );
  }
}
