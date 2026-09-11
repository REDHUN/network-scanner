import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/models/utilities_model/ping_result.dart';
import 'package:ip_tools/service/ping_service/ping_service.dart';
import 'package:ip_tools/service/share_service/share_service.dart';

class PingScreen extends StatefulWidget {
  final String? initialHost;
  const PingScreen({super.key, this.initialHost});

  @override
  State<PingScreen> createState() => _PingScreenState();
}

class _PingScreenState extends State<PingScreen> {
  final PingService _pingService = PingService();
  final ShareService _shareService = ShareService();
  final TextEditingController _hostController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isPinging = false;
  PingMode _pingMode = PingMode.icmp;
  int _packetCount = 0; // 0 = continuous
  int _timeoutMs = 1500;
  int _intervalMs = 1000;
  int _tcpPort = 80;

  PingCancellationToken? _cancellationToken;
  StreamSubscription<PingPacket>? _pingSubscription;

  final List<PingPacket> _packets = [];
  PingSummary? _summary;

  @override
  void initState() {
    super.initState();
    _hostController.text = widget.initialHost ?? '1.1.1.1';
  }

  @override
  void dispose() {
    _stopPing();
    _hostController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPing() {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      SnackbarUtils.showWarning(context, 'Please enter a valid IP or domain');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isPinging = true;
      _packets.clear();
      _summary = null;
    });

    _cancellationToken = PingCancellationToken();

    final stream = _pingService.startPing(
      host: host,
      count: _packetCount,
      timeoutMs: _timeoutMs,
      intervalMs: _intervalMs,
      mode: _pingMode,
      tcpPort: _tcpPort,
      token: _cancellationToken,
    );

    _pingSubscription = stream.listen(
      (packet) {
        if (!mounted) return;
        setState(() {
          _packets.insert(0, packet);
          _summary = PingSummary.fromPackets(
            host: host,
            ip: packet.ip,
            packets: _packets,
          );
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isPinging = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _isPinging = false;
        });
        SnackbarUtils.showError(context, 'Ping error: ${e.toString()}');
      },
    );
  }

  void _stopPing() {
    _cancellationToken?.cancel();
    _pingSubscription?.cancel();
    if (mounted && _isPinging) {
      setState(() {
        _isPinging = false;
      });
    }
  }

  Future<void> _sharePingReport() async {
    if (_packets.isEmpty) {
      SnackbarUtils.showWarning(context, 'No ping data to share');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('=== Ping Report ===');
    buffer.writeln('Target: ${_hostController.text.trim()}');
    buffer.writeln('Protocol: ${_pingMode == PingMode.icmp ? "ICMP" : "TCP (Port $_tcpPort)"}');
    buffer.writeln('Timeout: ${_timeoutMs}ms | Interval: ${_intervalMs}ms');
    buffer.writeln('Count Limit: ${_packetCount == 0 ? "Continuous" : "$_packetCount packets"}');
    buffer.writeln('Packets Sent: ${_summary?.totalSent ?? _packets.length}');
    buffer.writeln('Packets Received: ${_summary?.totalReceived ?? 0}');
    buffer.writeln('Packet Loss: ${(_summary?.packetLossPercentage ?? 0).toStringAsFixed(1)}%');
    buffer.writeln('Min Latency: ${(_summary?.minTimeMs ?? 0).toStringAsFixed(1)} ms');
    buffer.writeln('Avg Latency: ${(_summary?.avgTimeMs ?? 0).toStringAsFixed(1)} ms');
    buffer.writeln('Max Latency: ${(_summary?.maxTimeMs ?? 0).toStringAsFixed(1)} ms');
    buffer.writeln('Jitter: ${(_summary?.jitterMs ?? 0).toStringAsFixed(1)} ms');
    buffer.writeln('\n--- Packet Log ---');
    for (final p in _packets.reversed) {
      if (p.isSuccess) {
        buffer.writeln('#${p.sequence}: ${p.timeMs?.toStringAsFixed(1)} ms (TTL: ${p.ttl ?? "N/A"})');
      } else {
        buffer.writeln('#${p.sequence}: ${p.errorMessage ?? "Timed out"}');
      }
    }

    await _shareService.shareText(
      buffer.toString(),
      subject: 'Ping Report - ${_hostController.text.trim()}',
    );
  }

  Future<void> _showCustomNumberDialog({
    required String title,
    required String hintText,
    required String initialValue,
    required String suffix,
    required void Function(int value) onSaved,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              suffixText: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                onSaved(val);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0075FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Set', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
          'Ping & Latency',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF0075FF)),
            onPressed: _sharePingReport,
            tooltip: 'Share Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Target Input & Settings Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _hostController,
                          enabled: !_isPinging,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter hostname or IP...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: const Icon(
                              Icons.public_rounded,
                              color: Color(0xFF0075FF),
                              size: 20,
                            ),
                            suffixIcon: _hostController.text.isNotEmpty && !_isPinging
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () => setState(() => _hostController.clear()),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Start / Stop Pill Button
                    ElevatedButton(
                      onPressed: _isPinging ? _stopPing : _startPing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPinging ? const Color(0xFFEF4444) : const Color(0xFF0075FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPinging ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isPinging ? 'Stop' : 'Ping',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Settings Bar (Count, Timeout, Interval, Mode)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Count Dropdown Pill
                      _buildCountMenu(),
                      const SizedBox(width: 8),

                      // Timeout Dropdown Pill
                      _buildTimeoutMenu(),
                      const SizedBox(width: 8),

                      // Interval Dropdown Pill
                      _buildIntervalMenu(),
                      const SizedBox(width: 8),

                      // Mode Dropdown Pill
                      _buildModeMenu(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Target Presets Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip('Cloudflare (1.1.1.1)', '1.1.1.1'),
                      const SizedBox(width: 6),
                      _buildPresetChip('Google (8.8.8.8)', '8.8.8.8'),
                      const SizedBox(width: 6),
                      _buildPresetChip('OpenDNS (208.67.222.222)', '208.67.222.222'),
                      const SizedBox(width: 6),
                      _buildPresetChip('google.com', 'google.com'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Live Latency Stats Cards
          _buildStatsDashboard(),

          // Latency Visualizer Sparkline / Bar Chart
          if (_packets.isNotEmpty) _buildLatencyVisualizer(),

          // Packet Response Log Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PACKET STREAM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                if (_packets.isNotEmpty)
                  Text(
                    _packetCount > 0
                        ? '${_packets.length}/$_packetCount packets'
                        : '${_packets.length} packets',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0075FF),
                    ),
                  ),
              ],
            ),
          ),

          // Packet Stream List
          Expanded(
            child: _packets.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: _packets.length,
                    itemBuilder: (context, index) {
                      final packet = _packets[index];
                      return _buildPacketCard(packet);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountMenu() {
    final countLabel = _packetCount == 0 ? 'Count: ∞' : 'Count: $_packetCount';
    return PopupMenuButton<int>(
      enabled: !_isPinging,
      onSelected: (val) {
        if (val == -1) {
          _showCustomNumberDialog(
            title: 'Custom Packet Count',
            hintText: 'e.g. 50',
            initialValue: '50',
            suffix: 'packets',
            onSaved: (val) => setState(() => _packetCount = val),
          );
        } else {
          setState(() => _packetCount = val);
        }
      },
      offset: const Offset(0, 36),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.repeat_rounded, size: 14, color: Color(0xFF0075FF)),
            const SizedBox(width: 4),
            Text(
              countLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0075FF),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF0075FF)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupItem(0, 'Continuous (∞)', _packetCount == 0),
        _buildPopupItem(4, '4 Packets (Quick)', _packetCount == 4),
        _buildPopupItem(10, '10 Packets', _packetCount == 10),
        _buildPopupItem(20, '20 Packets', _packetCount == 20),
        _buildPopupItem(50, '50 Packets', _packetCount == 50),
        _buildPopupItem(-1, 'Custom Count...', _packetCount != 0 && _packetCount != 4 && _packetCount != 10 && _packetCount != 20 && _packetCount != 50),
      ],
    );
  }

  Widget _buildTimeoutMenu() {
    final timeoutLabel = _timeoutMs >= 1000 ? 'Timeout: ${(_timeoutMs / 1000).toStringAsFixed(1)}s' : 'Timeout: ${_timeoutMs}ms';
    return PopupMenuButton<int>(
      enabled: !_isPinging,
      onSelected: (val) {
        if (val == -1) {
          _showCustomNumberDialog(
            title: 'Custom Timeout (ms)',
            hintText: 'e.g. 2500',
            initialValue: '2500',
            suffix: 'ms',
            onSaved: (val) => setState(() => _timeoutMs = val),
          );
        } else {
          setState(() => _timeoutMs = val);
        }
      },
      offset: const Offset(0, 36),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF475569)),
            const SizedBox(width: 4),
            Text(
              timeoutLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF475569)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupItem(1000, '1000 ms (1.0s)', _timeoutMs == 1000),
        _buildPopupItem(1500, '1500 ms (1.5s - Default)', _timeoutMs == 1500),
        _buildPopupItem(2000, '2000 ms (2.0s)', _timeoutMs == 2000),
        _buildPopupItem(3000, '3000 ms (3.0s)', _timeoutMs == 3000),
        _buildPopupItem(5000, '5000 ms (5.0s)', _timeoutMs == 5000),
        _buildPopupItem(-1, 'Custom Timeout...', _timeoutMs != 1000 && _timeoutMs != 1500 && _timeoutMs != 2000 && _timeoutMs != 3000 && _timeoutMs != 5000),
      ],
    );
  }

  Widget _buildIntervalMenu() {
    final intervalLabel = 'Interval: ${_intervalMs >= 1000 ? "${(_intervalMs / 1000).toStringAsFixed(1)}s" : "${_intervalMs}ms"}';
    return PopupMenuButton<int>(
      enabled: !_isPinging,
      onSelected: (val) => setState(() => _intervalMs = val),
      offset: const Offset(0, 36),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF475569)),
            const SizedBox(width: 4),
            Text(
              intervalLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF475569)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupItem(500, '500 ms (Fast)', _intervalMs == 500),
        _buildPopupItem(1000, '1000 ms (1.0s - Normal)', _intervalMs == 1000),
        _buildPopupItem(2000, '2000 ms (2.0s - Relaxed)', _intervalMs == 2000),
      ],
    );
  }

  Widget _buildModeMenu() {
    final modeLabel = _pingMode == PingMode.icmp ? 'Mode: ICMP' : 'Mode: TCP:$_tcpPort';
    return PopupMenuButton<String>(
      enabled: !_isPinging,
      onSelected: (val) {
        if (val == 'icmp') {
          setState(() => _pingMode = PingMode.icmp);
        } else if (val == 'tcp_custom') {
          _showCustomNumberDialog(
            title: 'Custom TCP Port',
            hintText: 'e.g. 443',
            initialValue: '$_tcpPort',
            suffix: 'port',
            onSaved: (port) {
              setState(() {
                _pingMode = PingMode.tcp;
                _tcpPort = port;
              });
            },
          );
        } else if (val.startsWith('tcp:')) {
          final port = int.tryParse(val.split(':')[1]) ?? 80;
          setState(() {
            _pingMode = PingMode.tcp;
            _tcpPort = port;
          });
        }
      },
      offset: const Offset(0, 36),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_outlined, size: 14, color: Color(0xFF475569)),
            const SizedBox(width: 4),
            Text(
              modeLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF475569)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupItem('icmp', 'ICMP (Standard Ping)', _pingMode == PingMode.icmp),
        _buildPopupItem('tcp:80', 'TCP Connect : 80 (HTTP)', _pingMode == PingMode.tcp && _tcpPort == 80),
        _buildPopupItem('tcp:443', 'TCP Connect : 443 (HTTPS)', _pingMode == PingMode.tcp && _tcpPort == 443),
        _buildPopupItem('tcp:53', 'TCP Connect : 53 (DNS)', _pingMode == PingMode.tcp && _tcpPort == 53),
        _buildPopupItem('tcp_custom', 'Custom TCP Port...', _pingMode == PingMode.tcp && _tcpPort != 80 && _tcpPort != 443 && _tcpPort != 53),
      ],
    );
  }

  PopupMenuItem<T> _buildPopupItem<T>(T value, String title, bool isSelected) {
    return PopupMenuItem<T>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0075FF) : const Color(0xFF0F172A),
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF0075FF)),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String host) {
    final isSelected = _hostController.text.trim() == host;
    return InkWell(
      onTap: _isPinging
          ? null
          : () {
              setState(() {
                _hostController.text = host;
              });
            },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0075FF) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsDashboard() {
    final summary = _summary;
    final min = summary?.minTimeMs.toStringAsFixed(1) ?? '--';
    final avg = summary?.avgTimeMs.toStringAsFixed(1) ?? '--';
    final max = summary?.maxTimeMs.toStringAsFixed(1) ?? '--';
    final jitter = summary?.jitterMs.toStringAsFixed(1) ?? '--';
    final loss = summary != null ? '${summary.packetLossPercentage.toStringAsFixed(0)}%' : '0%';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Min', '$min ms', const Color(0xFF10B981)),
          _buildDivider(),
          _buildStatItem('Avg', '$avg ms', const Color(0xFF0075FF)),
          _buildDivider(),
          _buildStatItem('Max', '$max ms', const Color(0xFFF59E0B)),
          _buildDivider(),
          _buildStatItem('Jitter', '$jitter ms', const Color(0xFF8B5CF6)),
          _buildDivider(),
          _buildStatItem(
            'Loss',
            loss,
            (summary?.packetLossPercentage ?? 0) > 0
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLatencyVisualizer() {
    final recentPackets = _packets.take(24).toList().reversed.toList();
    final maxLatency = recentPackets.fold<double>(
      50.0,
      (max, p) => (p.timeMs ?? 0) > max ? p.timeMs! : max,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'LATENCY GRAPH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Recent Packets (ms)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recentPackets.map((p) {
                final time = p.timeMs ?? 0;
                final heightFactor = (time / maxLatency).clamp(0.1, 1.0);
                Color barColor;
                if (!p.isSuccess) {
                  barColor = const Color(0xFFEF4444);
                } else if (time < 50) {
                  barColor = const Color(0xFF10B981);
                } else if (time < 150) {
                  barColor = const Color(0xFFF59E0B);
                } else {
                  barColor = const Color(0xFFEF4444);
                }

                return Expanded(
                  child: Tooltip(
                    message: p.isSuccess ? '${time.toStringAsFixed(1)} ms' : 'Lost',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      height: 44 * heightFactor,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacketCard(PingPacket packet) {
    final isSuccess = packet.isSuccess;
    Color statusColor;
    if (!isSuccess) {
      statusColor = const Color(0xFFEF4444);
    } else if ((packet.timeMs ?? 0) < 50) {
      statusColor = const Color(0xFF10B981);
    } else if ((packet.timeMs ?? 0) < 150) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuccess ? const Color(0xFFF1F5F9) : const Color(0xFFFEE2E2),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '#${packet.sequence}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuccess
                      ? '${packet.timeMs?.toStringAsFixed(1)} ms'
                      : packet.errorMessage ?? 'Request timed out',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSuccess ? const Color(0xFF0F172A) : const Color(0xFFEF4444),
                  ),
                ),
                if (packet.ip != null)
                  Text(
                    'IP: ${packet.ip}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          if (packet.ttl != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'TTL: ${packet.ttl}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.speed_rounded,
              color: Color(0xFF0075FF),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to Ping',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter a hostname or IP address and tap "Ping"\nto measure latency, jitter, and packet loss.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
