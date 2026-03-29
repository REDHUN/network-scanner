import 'package:flutter/material.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/service/permission_preferences_service/permission_preferences_service.dart';
import 'package:ip_tools/service/permission_service/permission_service.dart';

class LocationPermissionScreen extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onSkipped;

  const LocationPermissionScreen({
    super.key,
    this.onPermissionGranted,
    this.onSkipped,
  });

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  final _permissionService = PermissionService();
  final _preferencesService = PermissionPreferencesService();

  bool _isLoading = false;
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    // Keep this method if any future initialization requires it, or just empty it out
    // Since we aren\'t displaying status anymore, we just don't set state
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await _permissionService.requestWifiPermission();

      if (granted) {
        // Permission granted
        if (_dontShowAgain) {
          await _preferencesService.setDontShowLocationWarning(true);
        }

        // Mark app as launched since user interacted with permission screen
        await _preferencesService.setAppLaunched();

        // Mark that user has been asked on first launch
        await _preferencesService.setAskedOnFirstLaunch();

        if (widget.onPermissionGranted != null) {
          widget.onPermissionGranted!();
        } else {
          Navigator.of(context).pop(true);
        }
      } else {
        // Permission denied
        await _loadPermissionStatus();

        if (mounted) {
          SnackbarUtils.showWarning(
            context,
            'Location permission is required for network scanning',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Error requesting permission: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skip() async {
    if (_dontShowAgain) {
      await _preferencesService.setDontShowLocationWarning(true);
    }

    // Mark app as launched since user interacted with permission screen
    await _preferencesService.setAppLaunched();

    // Mark that user has been asked on first launch
    await _preferencesService.setAskedOnFirstLaunch();

    if (widget.onSkipped != null) {
      widget.onSkipped!();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48, // Account for padding
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // App Bar / Back Button area (if applicable, though usually Scaffold app bar handles it)
                  // Let's add a custom top area
                  // Align(
                  //   alignment: Alignment.centerLeft,
                  //   child: IconButton(
                  //     icon: const Icon(Icons.arrow_back),
                  //     onPressed: () => Navigator.of(context).pop(),
                  //     padding: EdgeInsets.zero,
                  //     constraints: const BoxConstraints(),
                  //   ),
                  // ),

                  // Center title next to back button? Actually the design shows them inline
                  // Let's build a custom header
                  Transform.translate(
                    offset: const Offset(
                      0,
                      -24,
                    ), // Adjust to align with back button
                    child: const Center(
                      child: Text(
                        'Location Access',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Top Map Image
                  // Container(
                  //   width: double.infinity,
                  //   height: 200,
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(24),
                  //     image: const DecorationImage(
                  //       image: AssetImage(
                  //         'assets/images/map_placeholder.jpg',
                  //       ), // Ensure this exists or use a network image for now
                  //       fit: BoxFit.cover,
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Enable Location\nPermission',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color:
                          Theme.of(context).textTheme.headlineLarge?.color ??
                          const Color(0xFF1C1C1E),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'To provide accurate network analysis\nand device discovery, we need access\nto your location data.',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.7) ??
                          const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Features that require permission
                  _buildFeatureItem(
                    Icons.radar,
                    'Network Discovery',
                    'Find and identify local network\ninfrastructure automatically.',
                    const Color(0xFFE5E7FA),
                    const Color(0xFF656CEB),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.cell_wifi,
                    'Network Information',
                    'Access detailed Wi-Fi and\ncellular connectivity data in real-time.',
                    const Color(0xFFE5E7FA),
                    const Color(0xFF656CEB),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.devices_other,
                    'Device Detection',
                    'Detect and catalog all devices\nconnected to your secure network.',
                    const Color(0xFFE5E7FA),
                    const Color(0xFF656CEB),
                  ),

                  const Spacer(),
                  const SizedBox(height: 32),

                  // Action buttons
                  Column(
                    children: [
                      // Grant Permission button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _requestPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF656CEB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Grant Permission',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Skip button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isLoading ? null : _skip,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Skip for Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.6) ??
                                  const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'You can change this anytime in your system settings.\nWe respect your privacy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.5) ??
                              const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // We replaced the entire list with individual cards
  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    Color iconBgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        Theme.of(context).textTheme.headlineLarge?.color ??
                        const Color(0xFF1C1C1E),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                        const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
