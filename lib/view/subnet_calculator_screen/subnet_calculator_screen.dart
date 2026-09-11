import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';

class SubnetCalculatorScreen extends StatefulWidget {
  final String? initialIp;
  const SubnetCalculatorScreen({super.key, this.initialIp});

  @override
  State<SubnetCalculatorScreen> createState() => _SubnetCalculatorScreenState();
}

class _SubnetCalculatorScreenState extends State<SubnetCalculatorScreen> {
  final TextEditingController _ipController = TextEditingController();
  int _cidr = 24;

  @override
  void initState() {
    super.initState();
    _ipController.text = widget.initialIp ?? '192.168.1.1';
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  // IP to 32-bit int
  int? _ipToInt(String ip) {
    try {
      final parts = ip.trim().split('.');
      if (parts.length != 4) return null;
      int res = 0;
      for (final p in parts) {
        final val = int.tryParse(p);
        if (val == null || val < 0 || val > 255) return null;
        res = (res << 8) | val;
      }
      return res;
    } catch (_) {
      return null;
    }
  }

  // 32-bit int to IP string
  String _intToIp(int val) {
    return '${(val >> 24) & 0xFF}.${(val >> 16) & 0xFF}.${(val >> 8) & 0xFF}.${val & 0xFF}';
  }

  // Subnet mask from CIDR
  int _cidrToMask(int cidr) {
    if (cidr == 0) return 0;
    return (-1 << (32 - cidr)) & 0xFFFFFFFF;
  }

  String _toBinaryString(int val) {
    final b1 = ((val >> 24) & 0xFF).toRadixString(2).padLeft(8, '0');
    final b2 = ((val >> 16) & 0xFF).toRadixString(2).padLeft(8, '0');
    final b3 = ((val >> 8) & 0xFF).toRadixString(2).padLeft(8, '0');
    final b4 = (val & 0xFF).toRadixString(2).padLeft(8, '0');
    return '$b1.$b2.$b3.$b4';
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  String _getIpTypeDescription(int ipInt) {
    final first = (ipInt >> 24) & 0xFF;
    final second = (ipInt >> 16) & 0xFF;

    String primaryType;
    if (first == 127) {
      primaryType = 'Loopback (RFC 1122)';
    } else if (first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168)) {
      primaryType = 'Private (RFC 1918)';
    } else if (first == 169 && second == 254) {
      primaryType = 'Link-Local (RFC 3927)';
    } else if (first == 100 && second >= 64 && second <= 127) {
      primaryType = 'Carrier-Grade NAT (RFC 6598)';
    } else if (first >= 224 && first <= 239) {
      primaryType = 'Multicast (RFC 5771)';
    } else if (first >= 240) {
      primaryType = 'Reserved (RFC 1112)';
    } else {
      primaryType = 'Public Internet';
    }

    String legacyClass;
    if (first >= 1 && first <= 126) {
      legacyClass = 'Class A';
    } else if (first >= 128 && first <= 191) {
      legacyClass = 'Class B';
    } else if (first >= 192 && first <= 223) {
      legacyClass = 'Class C';
    } else if (first >= 224 && first <= 239) {
      legacyClass = 'Class D';
    } else {
      legacyClass = 'Class E';
    }

    return '$primaryType • $legacyClass';
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      SnackbarUtils.showCopySuccess(context, label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ipInt = _ipToInt(_ipController.text);
    final isValid = ipInt != null;

    int mask = 0;
    int wildcard = 0;
    int networkInt = 0;
    int broadcastInt = 0;
    int firstHostInt = 0;
    int lastHostInt = 0;
    int totalHosts = 0;
    int usableHosts = 0;

    if (isValid) {
      mask = _cidrToMask(_cidr);
      wildcard = ~mask & 0xFFFFFFFF;
      networkInt = ipInt & mask;
      broadcastInt = networkInt | wildcard;
      totalHosts = pow(2, 32 - _cidr).toInt();
      if (_cidr <= 30) {
        firstHostInt = networkInt + 1;
        lastHostInt = broadcastInt - 1;
        usableHosts = totalHosts - 2;
      } else if (_cidr == 31) {
        firstHostInt = networkInt;
        lastHostInt = broadcastInt;
        usableHosts = 2;
      } else {
        firstHostInt = networkInt;
        lastHostInt = networkInt;
        usableHosts = 1;
      }
    }

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
          'Subnet Calculator',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input Card
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
                      'IP ADDRESS',
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
                        controller: _ipController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 192.168.1.1',
                          prefixIcon: Icon(Icons.lan_rounded, color: Color(0xFF0075FF), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // CIDR Prefix Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SUBNET MASK (CIDR)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '/$_cidr  (${_intToIp(_cidrToMask(_cidr))})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0075FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF0075FF),
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        thumbColor: const Color(0xFF0075FF),
                        overlayColor: const Color(0xFF0075FF).withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: _cidr.toDouble(),
                        min: 1,
                        max: 32,
                        divisions: 31,
                        label: '/$_cidr',
                        onChanged: (val) => setState(() => _cidr = val.round()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Calculation Results
              if (isValid) ...[
                const Text(
                  'CALCULATED PARAMETERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
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
                    children: [
                      _buildResultRow('Network Address', _intToIp(networkInt), icon: Icons.hub_rounded),
                      _buildDivider(),
                      _buildResultRow('Broadcast Address', _intToIp(broadcastInt), icon: Icons.podcasts_rounded),
                      _buildDivider(),
                      _buildResultRow('Subnet Mask', _intToIp(mask), icon: Icons.tune_rounded),
                      _buildDivider(),
                      _buildResultRow('Wildcard Mask', _intToIp(wildcard), icon: Icons.auto_fix_high_rounded),
                      _buildDivider(),
                      _buildResultRow(
                        'Usable Host Range',
                        '${_intToIp(firstHostInt)} – ${_intToIp(lastHostInt)}',
                        icon: Icons.swap_horiz_rounded,
                        allowWrap: true,
                      ),
                      _buildDivider(),
                      _buildResultRow('Usable Hosts', _formatNumber(usableHosts), icon: Icons.devices_rounded),
                      _buildDivider(),
                      _buildResultRow('Total Addresses', _formatNumber(totalHosts), icon: Icons.numbers_rounded),
                      _buildDivider(),
                      _buildResultRow(
                        'IP Type',
                        _getIpTypeDescription(ipInt),
                        icon: Icons.shield_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Binary Representation Card
                const Text(
                  'BINARY REPRESENTATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
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
                      _buildBinaryItem(
                        'IP Address',
                        _toBinaryString(ipInt),
                        accentColor: const Color(0xFF0075FF),
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                      const SizedBox(height: 12),
                      _buildBinaryItem(
                        'Subnet Mask',
                        _toBinaryString(mask),
                        accentColor: const Color(0xFF8B5CF6),
                        bgColor: const Color(0xFFF5F3FF),
                      ),
                      const SizedBox(height: 12),
                      _buildBinaryItem(
                        'Network ID',
                        _toBinaryString(networkInt),
                        accentColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFECFDF5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please enter a valid IPv4 address (e.g. 192.168.1.1)',
                          style: TextStyle(
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value, {
    required IconData icon,
    bool allowWrap = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: allowWrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0075FF)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: allowWrap ? 12 : 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                height: 1.25,
              ),
              softWrap: allowWrap,
              overflow: allowWrap ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _copyText(value, label),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy_rounded, size: 15, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
  }

  Widget _buildBinaryItem(
    String label,
    String binary, {
    required Color accentColor,
    required Color bgColor,
  }) {
    final octets = binary.split('.');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              InkWell(
                onTap: () => _copyText(binary, label),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 13, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: octets.asMap().entries.map((entry) {
                final idx = entry.key;
                final octet = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        octet,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (idx < octets.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          '•',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
