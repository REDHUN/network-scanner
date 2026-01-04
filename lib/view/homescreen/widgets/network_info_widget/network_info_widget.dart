import 'package:flutter/material.dart';
import 'package:netra/common/widgets/network_pattern_painter.dart';
import 'package:netra/core/loadstate/load_state.dart';
import 'package:netra/viewmodels/network_viewmodel/network_viewmodel.dart';
import 'package:provider/provider.dart';

class NetworkInfoWidget extends StatefulWidget {
  const NetworkInfoWidget({super.key});

  @override
  State<NetworkInfoWidget> createState() => _NetworkInfoWidgetState();
}

class _NetworkInfoWidgetState extends State<NetworkInfoWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<NetworkViewModel>();
      // prevent duplicate calls
      if (vm.state == LoadState.idle) {
        // Initial load
        vm.loadNetworkInfo();
        vm.startNetworkMonitoring();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkViewModel>(
      builder: (_, vm, __) {
        switch (vm.state) {
          case LoadState.loading:
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            );

          case LoadState.error:
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFEF4444),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vm.error ?? 'Unknown error',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );

          case LoadState.success:
            final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkTheme ? 0.2 : 0.05,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Simple light background pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SimpleNetworkPatternPainter(
                          isDarkTheme: isDarkTheme,
                        ),
                      ),
                    ),
                    // Content
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  vm.isNetworkActive
                                      ? Icons.wifi
                                      : Icons.wifi_off,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Network Information',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.headlineMedium?.color,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: vm.isNetworkActive
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          vm.isNetworkActive
                                              ? 'Connected'
                                              : 'Disconnected',
                                          style: TextStyle(
                                            color: vm.isNetworkActive
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Network Details
                          _infoRow(
                            'Wi-Fi Name',
                            vm.networkInfo?.wifiName ?? 'N/A',
                            context: context,
                          ),
                          _infoRow(
                            'Local IP',
                            vm.networkInfo?.wifiIP ?? 'N/A',
                            context: context,
                          ),
                          _infoRow(
                            'Subnet',
                            vm.networkInfo?.subnet ?? 'N/A',
                            context: context,
                          ),
                          _infoRow(
                            'Gateway',
                            vm.networkInfo?.gateway ?? 'N/A',
                            context: context,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );

          case LoadState.idle:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _infoRow(String label, String value, {required BuildContext context}) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              height: 1.3,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkTheme
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
