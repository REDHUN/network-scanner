import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/models/utilities_model/wol_result.dart';
import 'package:ip_tools/service/wol_service/wol_service.dart';

class WolScreen extends StatefulWidget {
  final String? initialMac;
  final String? deviceName;
  const WolScreen({super.key, this.initialMac, this.deviceName});

  @override
  State<WolScreen> createState() => _WolScreenState();
}

class _WolScreenState extends State<WolScreen> with SingleTickerProviderStateMixin {
  final WolService _wolService = WolService();
  final TextEditingController _macController = TextEditingController();
  final TextEditingController _ipController = TextEditingController(text: '255.255.255.255');
  final TextEditingController _portController = TextEditingController(text: '9');

  bool _isSending = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<WolPacketResult> _history = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialMac != null) {
      _macController.text = widget.initialMac!;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _macController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendWolPacket() async {
    final mac = _macController.text.trim();
    if (mac.isEmpty) {
      SnackbarUtils.showWarning(context, 'Please enter a target MAC address');
      return;
    }

    if (!_wolService.isValidMac(mac)) {
      SnackbarUtils.showError(
        context,
        'Invalid MAC format. Use 12 hexadecimal characters (e.g. AA:BB:CC:DD:EE:FF)',
      );
      return;
    }

    final broadcastIp = _ipController.text.trim().isEmpty ? '255.255.255.255' : _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9;

    setState(() => _isSending = true);
    _pulseController.repeat(reverse: true);

    try {
      final result = await _wolService.sendMagicPacket(
        macAddress: mac,
        broadcastIp: broadcastIp,
        port: port,
      );

      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _history.insert(0, result);
      });
      _pulseController.stop();
      _pulseController.reset();

      if (result.isSuccess) {
        SnackbarUtils.showSuccess(
          context,
          'Magic Packet successfully sent to ${result.formattedMac}',
        );
      } else {
        SnackbarUtils.showError(
          context,
          'Failed: ${result.errorMessage ?? "Unknown network error"}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _pulseController.stop();
      _pulseController.reset();
      SnackbarUtils.showError(context, 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wake-on-LAN (WoL)',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.deviceName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.devices_rounded, color: Color(0xFF0075FF), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Target Device: ${widget.deviceName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0075FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Input Form Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TARGET MAC ADDRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: TextField(
                      controller: _macController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 00:1A:2B:3C:4D:5E',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                        prefixIcon: const Icon(
                          Icons.fingerprint_rounded,
                          color: Color(0xFF0075FF),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste_rounded, size: 18, color: Color(0xFF0075FF)),
                          tooltip: 'Paste MAC',
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              setState(() => _macController.text = data!.text!);
                            }
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Broadcast IP & Port Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BROADCAST IP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                              ),
                              child: TextField(
                                controller: _ipController,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  hintText: '255.255.255.255',
                                  prefixIcon: Icon(Icons.podcasts_rounded, size: 18, color: Color(0xFF64748B)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PORT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                              ),
                              child: TextField(
                                controller: _portController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  hintText: '9',
                                  prefixIcon: Icon(Icons.tag_rounded, size: 18, color: Color(0xFF64748B)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Send WoL Action Button
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendWolPacket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0075FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSending ? Icons.sync : Icons.power_settings_new_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSending ? 'Broadcasting Magic Packet...' : 'Wake Up Device',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
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
            const SizedBox(height: 20),

            // WoL Guide Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'How Wake-on-LAN Works',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF166534),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'WoL sends a special "Magic Packet" containing the target device\'s MAC address repeated 16 times. Ensure Wake-on-LAN is enabled in the target device\'s BIOS/UEFI and network card power settings.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF15803D),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Packet Broadcast History
            if (_history.isNotEmpty) ...[
              const Text(
                'SENT PACKETS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: item.isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.formattedMac,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Sent to ${item.broadcastIp}:${item.port}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}:${item.timestamp.second.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
