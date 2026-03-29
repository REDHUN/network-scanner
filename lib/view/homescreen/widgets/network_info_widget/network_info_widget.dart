// import 'package:flutter/material.dart';
// import 'package:ip_tools/core/loadstate/load_state.dart';
// import 'package:ip_tools/service/permission_service/permission_service.dart';
// import 'package:ip_tools/viewmodels/network_viewmodel/network_viewmodel.dart';
// import 'package:provider/provider.dart';

// class NetworkInfoWidget extends StatefulWidget {
//   const NetworkInfoWidget({super.key});

//   @override
//   State<NetworkInfoWidget> createState() => _NetworkInfoWidgetState();
// }

// class _NetworkInfoWidgetState extends State<NetworkInfoWidget> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final vm = context.read<NetworkViewModel>();
//       // prevent duplicate calls
//       if (vm.state == LoadState.idle) {
//         // Initial load
//         vm.loadNetworkInfo();
//         vm.startNetworkMonitoring();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<NetworkViewModel>(
//       builder: (_, vm, __) {
//         switch (vm.state) {
//           case LoadState.loading:
//             return Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(40),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).cardColor,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.1),
//                     blurRadius: 20,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     Theme.of(context).colorScheme.primary,
//                   ),
//                 ),
//               ),
//             );

//           case LoadState.error:
//             return Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).cardColor,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.1),
//                     blurRadius: 20,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Column(
//                   children: [
//                     const Icon(
//                       Icons.error_outline,
//                       color: Color(0xFFFF3B30),
//                       size: 48,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       vm.error ?? 'Unknown error',
//                       style: TextStyle(
//                         color: Theme.of(context).textTheme.bodyLarge?.color,
//                         fontSize: 16,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             );

//           case LoadState.success:
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 4),
//                   child: Text(
//                     'Network Information',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).textTheme.headlineLarge?.color,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Network Cards Grid
//                 GridView.count(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   crossAxisCount: 2,
//                   mainAxisSpacing: 16,
//                   crossAxisSpacing: 16,
//                   childAspectRatio: 1.1,
//                   children: [
//                     _buildNetworkCard(
//                       context: context,
//                       icon: vm.isNetworkActive ? Icons.wifi : Icons.wifi_off,
//                       title: 'Connection',
//                       value: vm.isNetworkActive ? 'Connected' : 'Disconnected',
//                       isActive: vm.isNetworkActive,
//                       hasGoldenIcon: vm.isNetworkActive,
//                     ),
//                     _buildNetworkCard(
//                       context: context,
//                       icon: Icons.router,
//                       title: 'Gateway',
//                       value: _formatValue(vm.networkInfo?.gateway ?? 'N/A'),
//                       isActive: vm.networkInfo?.gateway != null,
//                     ),
//                     _buildNetworkCard(
//                       context: context,
//                       icon: Icons.devices,
//                       title: 'Local IP',
//                       value: _formatValue(vm.networkInfo?.wifiIP ?? 'N/A'),
//                       isActive: vm.networkInfo?.wifiIP != null,
//                     ),
//                     _buildNetworkCard(
//                       context: context,
//                       icon: Icons.network_wifi,
//                       title: 'Wi-Fi Name',
//                       value: _formatWifiName(vm),
//                       isActive:
//                           vm.locationStatus == LocationStatus.available &&
//                           vm.networkInfo?.wifiName != null,
//                       hasGoldenIcon:
//                           vm.locationStatus == LocationStatus.available &&
//                           vm.networkInfo?.wifiName != null,
//                       showLocationButton:
//                           vm.locationStatus != null &&
//                           vm.locationStatus != LocationStatus.available,
//                       onLocationAction: () async {
//                         if (vm.locationStatus ==
//                             LocationStatus.serviceDisabled) {
//                           await vm.openLocationSettings();
//                         } else if (vm.locationStatus ==
//                             LocationStatus.permissionDenied) {
//                           await vm.requestLocationPermission();
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             );

//           case LoadState.idle:
//             return const SizedBox.shrink();
//         }
//       },
//     );
//   }

//   Widget _buildNetworkCard({
//     required BuildContext context,
//     required IconData icon,
//     required String title,
//     required String value,
//     bool isActive = true,
//     bool hasGoldenIcon = false,
//     bool showLocationButton = false,
//     VoidCallback? onLocationAction,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: const Color(0xFF2C2C2E), // Dark charcoal like in the image
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.2),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Icon and Action Button Row
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFD4A574), // Golden accent
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   icon,
//                   color: const Color(
//                     0xFF2C2C2E,
//                   ), // Dark icon on golden background
//                   size: 20,
//                 ),
//               ),
//               const Spacer(),
//               if (showLocationButton && onLocationAction != null)
//                 GestureDetector(
//                   onTap: onLocationAction,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFD4A574),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: const Text(
//                       'Enable',
//                       style: TextStyle(
//                         color: Color(0xFF2C2C2E),
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),

//           const Spacer(),

//           // Title
//           Text(
//             title,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               letterSpacing: -0.2,
//             ),
//           ),

//           const SizedBox(height: 4),

//           // Value
//           Text(
//             value,
//             style: TextStyle(
//               color: isActive
//                   ? Colors.white.withValues(alpha: 0.8)
//                   : Colors.white.withValues(alpha: 0.5),
//               fontSize: 13,
//               fontWeight: FontWeight.w400,
//               letterSpacing: 0.1,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatValue(String value) {
//     if (value == 'N/A' || value.isEmpty) {
//       return 'Not available';
//     }
//     // Truncate long values for better display
//     if (value.length > 15) {
//       return '${value.substring(0, 12)}...';
//     }
//     return value;
//   }

//   String _formatWifiName(NetworkViewModel vm) {
//     if (vm.locationStatus != LocationStatus.available) {
//       return vm.getLocationMessage();
//     }
//     return _formatValue(vm.networkInfo?.wifiName ?? 'N/A');
//   }
// }
