import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/common/widgets/app_icon.dart';
import 'package:ip_tools/core/loadstate/load_state.dart';
import 'package:ip_tools/service/permission_manager/permission_manager.dart';
import 'package:ip_tools/service/permission_service/permission_service.dart';
import 'package:ip_tools/view/devices_screen/devices_screen.dart';
import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:provider/provider.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize network information when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkVM = Provider.of<NetworkViewModel>(context, listen: false);
      networkVM.loadNetworkInfo();
      networkVM.startNetworkMonitoring();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background (e.g., returning from settings)
    if (state == AppLifecycleState.resumed) {
      final networkVM = Provider.of<NetworkViewModel>(context, listen: false);
      // Small delay to ensure system has updated permissions/settings
      Future.delayed(const Duration(milliseconds: 500), () {
        networkVM.loadNetworkInfo();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: () async {
            // Check location permission before navigating to devices screen
            final hasPermission =
                await PermissionManager.checkLocationPermissionForFeature(
                  context,
                  featureName: 'Network Scanning',
                );

            if (hasPermission && mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DevicesScreen()),
              );
            }
          },
          backgroundColor: const Color(0xFF2C2C2E),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A574),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const AppIcon(
              size: 16,
              showStatusIndicator: false,
              backgroundColor: Colors.black,
            ),
          ),
          label: const Text(
            'START SCAN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final networkVM = Provider.of<NetworkViewModel>(
              context,
              listen: false,
            );
            await networkVM.forceRefresh();
          },
          color: const Color(0xFFD4A574),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                            'DASHBOARD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'IP Tools : Network Scanner',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(
                                context,
                              ).textTheme.headlineLarge?.color,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const AppIcon(
                        size: 20,
                        showStatusIndicator: false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Main Network Card
                Consumer<NetworkViewModel>(
                  builder: (context, vm, _) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2C2C2E),
                            const Color(0xFF1C1C1E),
                            const Color(0xFF2C2C2E),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with WiFi icon and status
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      vm.isNetworkActive
                                          ? Icons.wifi
                                          : Icons.wifi_off,
                                      color: const Color(0xFFD4A574),
                                      size: 20,
                                    ),
                                    // Show subtle loading indicator when checking status
                                    if (vm.state == LoadState.loading)
                                      SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                const Color(
                                                  0xFFD4A574,
                                                ).withValues(alpha: 0.3),
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: vm.isNetworkActive
                                      ? const Color(
                                          0xFF30A46C,
                                        ).withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: vm.isNetworkActive
                                            ? const Color(0xFF30A46C)
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      vm.isNetworkActive
                                          ? 'CONNECTED'
                                          : 'DISCONNECTED',
                                      style: TextStyle(
                                        color: vm.isNetworkActive
                                            ? const Color(0xFF30A46C)
                                            : Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Network Name and Action Button
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vm.getWifiDisplayName(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      vm.state == LoadState.loading
                                          ? 'Loading network information...'
                                          : vm.state == LoadState.error
                                          ? 'Unable to load network info'
                                          : vm.locationStatus != null &&
                                                vm.locationStatus !=
                                                    LocationStatus.available
                                          ? 'WiFi name requires location access'
                                          : 'Monitoring active traffic',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Show enable button when location is not available
                              if (vm.locationStatus != null &&
                                  vm.locationStatus != LocationStatus.available)
                                Container(
                                  margin: const EdgeInsets.only(left: 12),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (vm.locationStatus ==
                                          LocationStatus.serviceDisabled) {
                                        await vm.openLocationSettings();
                                      } else if (vm.locationStatus ==
                                          LocationStatus.permissionDenied) {
                                        await vm.requestLocationPermission();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4A574),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      vm.locationStatus ==
                                              LocationStatus.serviceDisabled
                                          ? 'Enable'
                                          : 'Grant',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Signal Strength Bars
                          _buildSignalBars(),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Details Section
                Row(
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.headlineLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Updated just now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Network Details Cards
                Consumer<NetworkViewModel>(
                  builder: (context, vm, _) {
                    return Column(
                      children: [
                        _buildDetailCard(
                          'LOCAL IP',
                          vm.networkInfo?.wifiIP ?? '',
                          Icons.devices,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailCard(
                          'GATEWAY',
                          vm.networkInfo?.gateway ?? '',
                          Icons.router,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailCard(
                          'SUBNET MASK',
                          vm.networkInfo?.subnet ?? '',
                          Icons.grid_view,
                        ),

                        const SizedBox(
                          height: 80,
                        ), // Extra bottom padding for FAB
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Widget _buildSignalBars() {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(20, (index) {
          final heights = [
            0.3,
            0.4,
            0.6,
            0.5,
            0.8,
            0.9,
            1.0,
            0.7,
            0.8,
            0.9,
            1.0,
            0.8,
            0.6,
            0.7,
            0.9,
            0.5,
            0.4,
            0.6,
            0.3,
            0.4,
          ];
          final isActive = index < 15; // Show first 15 bars as active

          return Container(
            width: 5,
            height: 24 * heights[index],
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFD4A574)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
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
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.copy,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
