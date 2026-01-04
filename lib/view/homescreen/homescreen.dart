import 'package:flutter/material.dart';
import 'package:netra/view/devices_screen/devices_screen.dart';

import 'widgets/network_info_widget/network_info_widget.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                    child: const Icon(
                      Icons.home,
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
                          'Network Utility',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.headlineLarge?.color,
                          ),
                        ),
                        Text(
                          'Monitor your network status',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Network Info Widget
              const NetworkInfoWidget(),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),

              // Listen for scan completion and navigate to Devices screen
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return DevicesScreen();
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'Start Network Scan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // if (scannerVM.state == ScanState.done) {
              //     return Container(
              //       padding: const EdgeInsets.all(16),
              //       decoration: BoxDecoration(
              //         color: Theme.of(context).cardColor,
              //         borderRadius: BorderRadius.circular(12),
              //         border: Border.all(
              //           color: const Color(0xFF10B981).withValues(alpha: 0.2),
              //           width: 1,
              //         ),
              //       ),
              //       child: Row(
              //         children: [
              //           const Icon(
              //             Icons.check_circle,
              //             color: Color(0xFF10B981),
              //             size: 20,
              //           ),
              //           const SizedBox(width: 12),
              //           Expanded(
              //             child: Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 Text(
              //                   'Scan completed!',
              //                   style: TextStyle(
              //                     fontSize: 14,
              //                     fontWeight: FontWeight.w600,
              //                     color: Theme.of(
              //                       context,
              //                     ).textTheme.bodyLarge?.color,
              //                   ),
              //                 ),
              //                 Text(
              //                   '${scannerVM.devices.length} devices discovered',
              //                   style: TextStyle(
              //                     fontSize: 12,
              //                     color: Theme.of(context)
              //                         .textTheme
              //                         .bodyMedium
              //                         ?.color
              //                         ?.withValues(alpha: 0.7),
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         ],
              //       ),
              //     );
              //   }

              // Additional Info Cards
              const SizedBox(height: 24),
              // Expanded(
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: _buildInfoCard(
              //           context,
              //           'Security',
              //           'Network Protected',
              //           Icons.security,
              //           const Color(0xFF10B981),
              //         ),
              //       ),
              //       const SizedBox(width: 16),
              //       Expanded(
              //         child: _buildInfoCard(
              //           context,
              //           'Speed',
              //           'High Performance',
              //           Icons.speed,
              //           const Color(0xFF06B6D4),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
