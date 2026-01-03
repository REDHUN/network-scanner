import 'package:flutter/material.dart';
import 'package:netra/common/appconstants/app_colors.dart';
import 'package:netra/common/appconstants/common_style_constants.dart';
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
            return const Center(child: CircularProgressIndicator());

          case LoadState.error:
            return Center(child: Text(vm.error ?? 'Unknown error'));

          case LoadState.success:
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: CommonStyleConstants.commonContainerDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wifi,
                                color: AppColors.iconPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Network Information',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vm.isNetworkActive
                                      ? 'Connected'
                                      : 'Disconnected',
                                  style: const TextStyle(
                                    color: AppColors.iconPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _infoRow(
                          'Wi-Fi Name',
                          vm.networkInfo?.wifiName ?? 'N/A',
                        ),
                        _infoRow('Local IP', vm.networkInfo?.wifiIP ?? 'N/A'),
                        _infoRow('Subnet', vm.networkInfo?.subnet ?? 'N/A'),
                        _infoRow('Gateway', vm.networkInfo?.gateway ?? 'N/A'),

                        const SizedBox(height: 16),

                        /// Status
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: vm.isNetworkActive
                                    ? AppColors.greenAccent
                                    : AppColors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              vm.isNetworkActive
                                  ? 'Network Active'
                                  : 'Network Inactive',
                              style: const TextStyle(
                                color: AppColors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

          case LoadState.idle:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.white60, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
