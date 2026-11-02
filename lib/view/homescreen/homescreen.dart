import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/service/permission_manager/permission_manager.dart';
import 'package:ip_tools/view/devices_screen/devices_screen.dart';
import 'package:ip_tools/view/main_navigation/main_navigation.dart';
import 'package:ip_tools/view/ping_screen/ping_screen.dart';
import 'package:ip_tools/view/traceroute_screen/traceroute_screen.dart';
import 'package:ip_tools/view/wol_screen/wol_screen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:provider/provider.dart';

class Homescreen extends StatefulWidget {
  final VoidCallback? onStartScan;
  const Homescreen({super.key, this.onStartScan});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
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

  Future<void> _startNetworkScan() async {
    final hasPermission =
        await PermissionManager.checkLocationPermissionForFeature(
          context,
          featureName: 'Network Scanning',
        );

    if (!mounted) return;
    if (hasPermission) {
      if (widget.onStartScan != null) {
        widget.onStartScan!();
      } else {
        final mainNav = context.findAncestorStateOfType<MainNavigationState>();
        if (mainNav != null) {
          mainNav.switchTab(1, autoStartScan: true);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const DevicesScreen(autoStartScan: true),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final networkVM = Provider.of<NetworkViewModel>(
              context,
              listen: false,
            );
            await networkVM.forceRefresh();
          },
          color: Theme.of(context).colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Subtitle
                Text(
                  'NETWORK UTILITY',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),

                // Dashboard Title & Scan Pill Button
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _startNetworkScan,
                      icon: const Icon(Icons.radar_rounded, size: 18),
                      label: const Text('Scan'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Main Gradient Network Card
                Consumer<NetworkViewModel>(
                  builder: (context, vm, _) {
                    final wifiName = vm.getWifiDisplayName();
                    final routerIp = vm.networkInfo?.gateway ?? 'Not available';
                    final isConnected = vm.isNetworkActive;

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0075FF),
                            Color(0xFF1469DF),
                            Color(0xFF1554AD),
                          ],
                          stops: [0.0, 0.65, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0075FF,
                            ).withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          children: [
                            // Graphic on right (Wi-Fi Icon)
                            Positioned(
                              right: 24,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.wifi_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Status Pill Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1E1B4B,
                                      ).withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: isConnected
                                                ? const Color(0xFF4ADE80)
                                                : const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isConnected
                                              ? 'CONNECTED'
                                              : 'DISCONNECTED',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Wi-Fi SSID
                                  Text(
                                    wifiName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  if (vm.isLocationActionNeeded) ...[
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => vm.enableLocation(),
                                      icon: const Icon(
                                        Icons.location_on_rounded,
                                        size: 16,
                                        color: Color(0xFF0075FF),
                                      ),
                                      label: Text(
                                        vm.locationActionLabel,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0075FF),
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF0075FF,
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 8),

                                  // Router Info
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.settings_outlined,
                                        color: Colors.white70,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Router: $routerIp',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Quick Utilities Section
                const Text(
                  'QUICK UTILITIES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                Consumer<NetworkViewModel>(
                  builder: (context, vm, _) {
                    final gateway = vm.networkInfo?.gateway ?? '1.1.1.1';
                    return _buildQuickUtilitiesGrid(context, gateway);
                  },
                ),

                const SizedBox(height: 28),

                // Section 1: WI-FI DETAILS
                const Text(
                  'WI-FI DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),

                Consumer<NetworkViewModel>(
                  builder: (context, vm, _) {
                    final info = vm.networkInfo;
                    final isConnected = vm.isNetworkActive;

                    return _buildCardContainer(
                      children: [
                        _buildDetailRow(
                          icon: Icons.ssid_chart_rounded,
                          label: 'WiFi State',
                          value: isConnected ? 'Online' : 'Offline',
                          customValueWidget: _buildStatusPill(isConnected),
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.language_rounded,
                          label: 'Timezone',
                          value: info?.timezone ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.wifi_tethering_rounded,
                          label: 'SSID',
                          value: info?.wifiName ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.dns_rounded,
                          label: 'ISP',
                          value: info?.isp ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.shield_outlined,
                          label: 'Organization',
                          value: info?.organization ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.memory_rounded,
                          label: 'BSSID',
                          value:
                              (info?.bssid != null &&
                                  info!.bssid!.isNotEmpty &&
                                  info.bssid != 'null')
                              ? info.bssid!
                              : 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.desktop_windows_outlined,
                          label: 'WiFi Broadcast',
                          value: info?.resolvedBroadcast ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.tune_rounded,
                          label: 'Subnet Mask',
                          value: info?.subnet != null
                              ? '${info!.subnet}${info.cidr != null ? ' (${info.cidr})' : ''}'
                              : 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.router_outlined,
                          label: 'Default Gateway IP',
                          value: info?.gateway ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.tag_rounded,
                          label: 'IPv4',
                          value: info?.wifiIP ?? 'N/A',
                        ),
                        if (info?.ipv6 != null &&
                            info!.ipv6!.isNotEmpty &&
                            info.ipv6 != 'null') ...[
                          _buildDivider(),
                          _buildDetailRow(
                            icon: Icons.numbers_rounded,
                            label: 'IPv6',
                            value: info.ipv6!,
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Section 2: LOCATION & PROVIDER DETAILS
                const Text(
                  'LOCATION & PROVIDER DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),

                Consumer<NetworkViewModel>(
                  builder: (context, vm, _) {
                    final info = vm.networkInfo;

                    return _buildCardContainer(
                      children: [
                        _buildDetailRow(
                          icon: Icons.location_city_rounded,
                          label: 'City',
                          value: info?.city ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.map_outlined,
                          label: 'Region',
                          value: info?.region ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.flag_outlined,
                          label: 'Country',
                          value: info?.country ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.explore_outlined,
                          label: 'Coordinates (Provider)',
                          value: info?.coordinatesDisplay ?? 'N/A',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Section 3: HOST & NETWORK CONFIGURATION
                const Text(
                  'HOST & NETWORK CONFIGURATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),

                Consumer<NetworkViewModel>(
                  builder: (context, vm, _) {
                    final info = vm.networkInfo;

                    return _buildCardContainer(
                      children: [
                        _buildDetailRow(
                          icon: Icons.lan_outlined,
                          label: 'Host (Public IP)',
                          value: info?.publicIp ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.computer_outlined,
                          label: 'Localhost',
                          value: info?.localhost ?? '127.0.0.1',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.hub_outlined,
                          label: 'ASN',
                          value: info?.asn ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.wifi_rounded,
                          label: 'Connection type',
                          value: info?.connectionType ?? 'WIFI',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Usable IP Range',
                          value: info?.ipRange ?? 'N/A',
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.devices_rounded,
                          label: 'Host Capacity',
                          value: info?.totalHosts ?? 'N/A',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 18,
      color: Color(0xFFF1F5F9),
    );
  }

  Widget _buildStatusPill(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? customValueWidget,
  }) {
    final isNA = value == 'N/A' || value == '-' || value.isEmpty;
    final valueWidget =
        customValueWidget ??
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isNA ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    final iconWidget = Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF0075FF), size: 20),
    );
    final labelWidget = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );

    return InkWell(
      onTap: isNA ? null : () => _copyToClipboard(value, label),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 300) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      iconWidget,
                      const SizedBox(width: 12),
                      Expanded(child: labelWidget),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 50),
                    child: valueWidget,
                  ),
                ],
              );
            }
            return Row(
              children: [
                iconWidget,
                const SizedBox(width: 14),
                Expanded(flex: 3, child: labelWidget),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: valueWidget,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickUtilitiesGrid(BuildContext context, String defaultGateway) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final cards = <Widget>[
          _buildUtilityCard(
            title: 'Ping & Jitter',
            subtitle: 'Latency test',
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF0075FF),
            bgColor: const Color(0xFFEFF6FF),
            compact: compact,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PingScreen(initialHost: defaultGateway),
                ),
              );
            },
          ),
          _buildUtilityCard(
            title: 'Traceroute',
            subtitle: 'Hop path',
            icon: Icons.alt_route_rounded,
            iconColor: const Color(0xFF0075FF),
            bgColor: const Color(0xFFEFF6FF),
            compact: compact,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const TracerouteScreen(initialHost: 'google.com'),
                ),
              );
            },
          ),
          _buildUtilityCard(
            title: 'Wake-on-LAN',
            subtitle: 'Remote boot',
            icon: Icons.power_settings_new_rounded,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            compact: compact,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WolScreen()),
              );
            },
          ),
        ];
        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUtilityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    required bool compact,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Flex(
            direction: compact ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 18)),
              ),
              if (compact)
                const SizedBox(width: 12)
              else
                const SizedBox(height: 10),
              if (compact)
                Expanded(child: _buildUtilityLabel(title, subtitle))
              else
                _buildUtilityLabel(title, subtitle),
              if (compact)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
