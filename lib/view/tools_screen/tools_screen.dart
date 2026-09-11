import 'package:flutter/material.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/models/network_model/scanned_device.dart';
import 'package:ip_tools/view/device_details_screen/device_details_screen.dart';
import 'package:ip_tools/view/dns_lookup_screen/dns_lookup_screen.dart';
import 'package:ip_tools/view/ping_screen/ping_screen.dart';
import 'package:ip_tools/view/subnet_calculator_screen/subnet_calculator_screen.dart';
import 'package:ip_tools/view/traceroute_screen/traceroute_screen.dart';
import 'package:ip_tools/view/wol_screen/wol_screen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openRouterAdmin(BuildContext context, String gatewayIp) async {
    final cleanIp = gatewayIp.trim().replaceAll(RegExp(r'^https?://'), '').split('/')[0];
    if (cleanIp.isEmpty || cleanIp == '0.0.0.0' || cleanIp == 'Unknown') {
      if (context.mounted) {
        SnackbarUtils.showWarning(context, 'No active router gateway IP detected. Connect to Wi-Fi.');
      }
      return;
    }

    final httpUri = Uri.parse('http://$cleanIp');
    final httpsUri = Uri.parse('https://$cleanIp');

    try {
      // 1. Try launching in external application (system browser)
      bool launched = false;
      try {
        launched = await launchUrl(httpUri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      // 2. Fallback to platform default
      if (!launched) {
        try {
          launched = await launchUrl(httpUri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      // 3. Fallback to HTTPS
      if (!launched) {
        try {
          launched = await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      if (!launched && context.mounted) {
        SnackbarUtils.showError(context, 'Could not open router page http://$cleanIp');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Error launching router admin: ${e.toString()}');
      }
    }
  }

  void _openPortScanner(BuildContext context, String gatewayIp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailsScreen(
          device: ScannedDevice(
            ip: gatewayIp,
            name: 'Router Gateway',
            isGateway: true,
          ),
          isOnline: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final networkVM = Provider.of<NetworkViewModel>(context);
    final gatewayIp = networkVM.networkInfo?.gateway ?? '192.168.1.1';
    final deviceIp = networkVM.networkInfo?.wifiIP ?? '192.168.1.100';

    final allTools = [
      _ToolItem(
        title: 'Ping & Latency Tester',
        description: 'Measure continuous ICMP/TCP ping, jitter, and packet loss in real-time.',
        category: 'DIAGNOSTICS',
        icon: Icons.speed_rounded,
        iconColor: const Color(0xFF0075FF),
        bgColor: const Color(0xFFEFF6FF),
        badgeText: 'Essential',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PingScreen(initialHost: gatewayIp)),
        ),
      ),
      _ToolItem(
        title: 'Traceroute Visualizer',
        description: 'Trace network hops from device to destination with interactive timeline.',
        category: 'DIAGNOSTICS',
        icon: Icons.alt_route_rounded,
        iconColor: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
        badgeText: 'Visual',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TracerouteScreen(initialHost: 'google.com')),
        ),
      ),
      _ToolItem(
        title: 'Wake-on-LAN (WoL)',
        description: 'Remotely power on computers, laptops, and NAS servers on the local network.',
        category: 'DIAGNOSTICS',
        icon: Icons.power_settings_new_rounded,
        iconColor: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
        badgeText: 'Remote',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WolScreen()),
        ),
      ),
      _ToolItem(
        title: 'Port Scanner',
        description: 'Audit open TCP ports, detect running services, and evaluate security.',
        category: 'SECURITY',
        icon: Icons.security_rounded,
        iconColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7),
        badgeText: 'Audit',
        onTap: () => _openPortScanner(context, gatewayIp),
      ),
      _ToolItem(
        title: 'Subnet & IP Calculator',
        description: 'Calculate CIDR masks, broadcast address, usable host ranges, and binary.',
        category: 'CALCULATORS',
        icon: Icons.calculate_rounded,
        iconColor: const Color(0xFF06B6D4),
        bgColor: const Color(0xFFECFEFF),
        badgeText: 'CIDR',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SubnetCalculatorScreen(initialIp: deviceIp)),
        ),
      ),
      _ToolItem(
        title: 'DNS & WHOIS Lookup',
        description: 'Query A, AAAA, MX, TXT, NS, and CNAME records using Cloudflare/Google DoH.',
        category: 'CALCULATORS',
        icon: Icons.dns_rounded,
        iconColor: const Color(0xFF6366F1),
        bgColor: const Color(0xFFEEF2FF),
        badgeText: 'DoH',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DnsLookupScreen(initialDomain: 'google.com')),
        ),
      ),
      _ToolItem(
        title: 'Router Admin Console',
        description: 'Quick access to the router web management interface ($gatewayIp).',
        category: 'UTILITIES',
        icon: Icons.router_rounded,
        iconColor: const Color(0xFFEC4899),
        bgColor: const Color(0xFFFDF2F8),
        badgeText: 'HTTP',
        onTap: () => _openRouterAdmin(context, gatewayIp),
      ),
    ];

    final filteredTools = _searchQuery.isEmpty
        ? allTools
        : allTools.where((t) {
            return t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.category.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NETWORK UTILITIES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0075FF),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tools Suite',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Comprehensive diagnostic and calculation tools for professional network analysis.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search tools (e.g. ping, subnet, dns)...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0075FF), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tools List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tool = filteredTools[index];
                    return _buildToolCard(tool);
                  },
                  childCount: filteredTools.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(_ToolItem tool) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: tool.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tool.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(tool.icon, color: tool.iconColor, size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Tool Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tool.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tool.bgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tool.badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: tool.iconColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tool.description,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String badgeText;
  final VoidCallback onTap;

  _ToolItem({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.badgeText,
    required this.onTap,
  });
}
