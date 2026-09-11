import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/models/utilities_model/traceroute_hop.dart';
import 'package:ip_tools/service/share_service/share_service.dart';
import 'package:ip_tools/service/traceroute_service/traceroute_service.dart';

class TracerouteScreen extends StatefulWidget {
  final String? initialHost;
  const TracerouteScreen({super.key, this.initialHost});

  @override
  State<TracerouteScreen> createState() => _TracerouteScreenState();
}

class _TracerouteScreenState extends State<TracerouteScreen> {
  final TracerouteService _tracerouteService = TracerouteService();
  final ShareService _shareService = ShareService();
  final TextEditingController _hostController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTracing = false;
  final int _maxHops = 30;
  bool _groupTimeouts = true;
  final Set<String> _expandedGroups = {};
  TracerouteCancellationToken? _cancellationToken;
  StreamSubscription<TracerouteHop>? _traceSubscription;

  final List<TracerouteHop> _hops = [];

  @override
  void initState() {
    super.initState();
    _hostController.text = widget.initialHost ?? 'google.com';
  }

  @override
  void dispose() {
    _stopTrace();
    _hostController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int get _respondingCount => _hops.where((h) => h.isSuccess).length;
  int get _timeoutCount => _hops.where((h) => h.isTimeout).length;
  bool get _destinationReached => _hops.any((h) => h.isDestination);

  void _startTrace() {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      SnackbarUtils.showWarning(context, 'Please enter a valid IP or domain');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isTracing = true;
      _hops.clear();
      _expandedGroups.clear();
    });

    _cancellationToken = TracerouteCancellationToken();

    final stream = _tracerouteService.startTraceroute(
      host: host,
      maxHops: _maxHops,
      token: _cancellationToken,
    );

    _traceSubscription = stream.listen(
      (hop) {
        if (!mounted) return;
        setState(() {
          _hops.add(hop);
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isTracing = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _isTracing = false;
        });
        SnackbarUtils.showError(context, 'Traceroute error: ${e.toString()}');
      },
    );
  }

  void _stopTrace() {
    _cancellationToken?.cancel();
    _traceSubscription?.cancel();
    if (mounted && _isTracing) {
      setState(() {
        _isTracing = false;
      });
    }
  }

  Future<void> _shareTracerouteReport() async {
    if (_hops.isEmpty) {
      SnackbarUtils.showWarning(context, 'No traceroute data to share');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('=== Traceroute Route Report ===');
    buffer.writeln('Target: ${_hostController.text.trim()}');
    buffer.writeln('Summary: $_respondingCount Responding · $_timeoutCount No Response (Total: ${_hops.length} Hops)');
    if (_destinationReached) {
      buffer.writeln('Status: Destination Reached 🎯');
    }
    buffer.writeln('\n--- Hop Path ---');
    for (final h in _hops) {
      if (h.isTimeout) {
        buffer.writeln('Hop #${h.hopNumber}: Request timed out (* * *) - No response from hop');
      } else {
        final host = h.hostname != null ? ' (${h.hostname})' : '';
        final lat = h.avgLatencyMs != null ? '${h.avgLatencyMs} ms' : '-';
        buffer.writeln('Hop #${h.hopNumber}: ${h.ip}$host [Probes: ${h.formattedProbes}] - Avg: $lat');
      }
    }

    await _shareService.shareText(
      buffer.toString(),
      subject: 'Traceroute Report - ${_hostController.text.trim()}',
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
          'Traceroute Visualizer',
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
            onPressed: _shareTracerouteReport,
            tooltip: 'Share Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Target Input Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          enabled: !_isTracing,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter domain or IP...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: const Icon(
                              Icons.alt_route_rounded,
                              color: Color(0xFF0075FF),
                              size: 20,
                            ),
                            suffixIcon: _hostController.text.isNotEmpty && !_isTracing
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
                    ElevatedButton(
                      onPressed: _isTracing ? _stopTrace : _startTrace,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracing ? const Color(0xFFEF4444) : const Color(0xFF0075FF),
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
                            _isTracing ? Icons.stop_rounded : Icons.navigation_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isTracing ? 'Stop' : 'Trace',
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
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip('google.com', 'google.com'),
                      const SizedBox(width: 6),
                      _buildPresetChip('Cloudflare (1.1.1.1)', '1.1.1.1'),
                      const SizedBox(width: 6),
                      _buildPresetChip('github.com', 'github.com'),
                      const SizedBox(width: 6),
                      _buildPresetChip('8.8.8.8', '8.8.8.8'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress Indicator
          if (_isTracing)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFFEFF6FF),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0075FF)),
              minHeight: 3,
            ),

          // Route Status & Summary Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'ROUTE PATH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (_destinationReached) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Destination Reached',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_hops.isNotEmpty) ...[
                  if (_isTracing)
                    Text(
                      'Tracing · ${_hops.length}/$_maxHops',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0075FF),
                      ),
                    )
                  else
                    Text(
                      '$_respondingCount Responding · $_timeoutCount No Response',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Consecutive Grouping Option Pill
          if (_hops.isNotEmpty && _timeoutCount > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _groupTimeouts = !_groupTimeouts;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _groupTimeouts ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 16,
                            color: _groupTimeouts ? const Color(0xFF0075FF) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Collapse consecutive timeouts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Hop Timeline List
          Expanded(
            child: _hops.isEmpty
                ? _buildEmptyState()
                : _buildHopListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHopListView() {
    if (!_groupTimeouts) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _hops.length,
        itemBuilder: (context, index) {
          final hop = _hops[index];
          final isLast = index == _hops.length - 1;
          return _buildTimelineHopNode(hop, isLast: isLast);
        },
      );
    }

    // Group consecutive timeouts for clean presentation
    final items = _groupHops(_hops);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        if (item is _SingleHopItem) {
          return _buildTimelineHopNode(item.hop, isLast: isLast);
        } else if (item is _GroupedTimeoutItem) {
          return _buildGroupedTimeoutNode(item, isLast: isLast);
        }
        return const SizedBox();
      },
    );
  }

  List<_HopListItem> _groupHops(List<TracerouteHop> rawHops) {
    final result = <_HopListItem>[];
    int i = 0;

    while (i < rawHops.length) {
      final hop = rawHops[i];
      if (!hop.isTimeout) {
        result.add(_SingleHopItem(hop));
        i++;
      } else {
        // Collect consecutive timeouts
        final timeoutHops = <TracerouteHop>[hop];
        int j = i + 1;
        while (j < rawHops.length && rawHops[j].isTimeout) {
          timeoutHops.add(rawHops[j]);
          j++;
        }

        if (timeoutHops.length > 1) {
          result.add(_GroupedTimeoutItem(timeoutHops));
        } else {
          result.add(_SingleHopItem(hop));
        }
        i = j;
      }
    }
    return result;
  }

  Widget _buildPresetChip(String label, String host) {
    final isSelected = _hostController.text.trim() == host;
    return InkWell(
      onTap: _isTracing
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

  /// Timeline node for a single hop (responding or single timeout)
  Widget _buildTimelineHopNode(TracerouteHop hop, {required bool isLast}) {
    final isTimeout = hop.isTimeout;
    final avg = hop.avgLatencyMs;
    Color latencyColor;
    if (isTimeout) {
      latencyColor = const Color(0xFF94A3B8);
    } else if ((avg ?? 0) < 50) {
      latencyColor = const Color(0xFF10B981);
    } else if ((avg ?? 0) < 150) {
      latencyColor = const Color(0xFFF59E0B);
    } else {
      latencyColor = const Color(0xFFEF4444);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Line & Node Icon
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isTimeout
                        ? const Color(0xFFF1F5F9)
                        : (hop.isDestination ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isTimeout
                          ? const Color(0xFFCBD5E1)
                          : (hop.isDestination ? const Color(0xFF16A34A) : const Color(0xFF0075FF)),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${hop.hopNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isTimeout
                            ? const Color(0xFF64748B)
                            : (hop.isDestination ? const Color(0xFF16A34A) : const Color(0xFF0075FF)),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Hop Details Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTimeout
                      ? const Color(0xFFF1F5F9)
                      : (hop.isDestination ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                  width: hop.isDestination ? 1.5 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    isTimeout ? 'Request timed out' : (hop.ip ?? '*'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isTimeout ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                                      fontFamily: isTimeout ? null : 'monospace',
                                    ),
                                  ),
                                ),
                                if (hop.isDestination)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Target',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (hop.hostname != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  hop.hostname!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0075FF),
                                  ),
                                ),
                              ),
                            if (isTimeout)
                              const Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'No response from this hop (filtered or rate-limited)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Latency Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: latencyColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTimeout ? Icons.timer_off_outlined : Icons.speed_rounded,
                              size: 12,
                              color: latencyColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isTimeout ? 'Timed out' : '${avg?.toStringAsFixed(1)} ms',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: latencyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Probes row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Probes: ${hop.formattedProbes}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (!isTimeout)
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF94A3B8)),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: hop.ip ?? ''));
                              if (context.mounted) {
                                SnackbarUtils.showCopySuccess(context, 'IP Address');
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Grouped node for consecutive timeouts (e.g., 8–17: 10 consecutive hops)
  Widget _buildGroupedTimeoutNode(_GroupedTimeoutItem group, {required bool isLast}) {
    final start = group.hops.first.hopNumber;
    final end = group.hops.last.hopNumber;
    final count = group.hops.length;
    final groupKey = '$start-$end';
    final isExpanded = _expandedGroups.contains(groupKey);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Line & Group Range Badge
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  width: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$start-$end',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Grouped Details Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedGroups.remove(groupKey);
                        } else {
                          _expandedGroups.add(groupKey);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hops $start–$end ($count consecutive)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Probes received no response (* * *)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  isExpanded ? 'Collapse' : 'Details',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: group.hops.map((h) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hop #${h.hopNumber}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const Text(
                                  '*   *   * (Timed out)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
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
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: Color(0xFF0075FF),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to Trace Route',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter a hostname or IP address to trace\nthe hop-by-hop network path and latency.',
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

abstract class _HopListItem {}

class _SingleHopItem extends _HopListItem {
  final TracerouteHop hop;
  _SingleHopItem(this.hop);
}

class _GroupedTimeoutItem extends _HopListItem {
  final List<TracerouteHop> hops;
  _GroupedTimeoutItem(this.hops);
}
