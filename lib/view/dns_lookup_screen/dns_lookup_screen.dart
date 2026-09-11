import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ip_tools/common/utils/snackbar_utils.dart';
import 'package:ip_tools/models/utilities_model/dns_record.dart';
import 'package:ip_tools/service/dns_service/dns_service.dart';
import 'package:ip_tools/service/share_service/share_service.dart';

class DnsLookupScreen extends StatefulWidget {
  final String? initialDomain;
  const DnsLookupScreen({super.key, this.initialDomain});

  @override
  State<DnsLookupScreen> createState() => _DnsLookupScreenState();
}

class _DnsLookupScreenState extends State<DnsLookupScreen> {
  final DnsService _dnsService = DnsService();
  final ShareService _shareService = ShareService();
  final TextEditingController _domainController = TextEditingController();

  String _selectedType = 'A';
  DnsResolverType _selectedResolver = DnsResolverType.cloudflare;
  bool _isLoading = false;
  DnsQueryResult? _lastResult;

  final List<String> _recordTypes = ['A', 'AAAA', 'MX', 'TXT', 'NS', 'CNAME', 'SOA', 'PTR'];

  @override
  void initState() {
    super.initState();
    _domainController.text = widget.initialDomain ?? 'google.com';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _performLookup();
      }
    });
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _performLookup() async {
    final input = _domainController.text.trim();
    if (input.isEmpty) {
      if (mounted) {
        SnackbarUtils.showWarning(context, 'Please enter a valid domain or IP address');
      }
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _dnsService.query(
        input,
        type: _selectedType,
        resolver: _selectedResolver,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastResult = DnsQueryResult(
          status: DnsQueryStatus.error,
          domain: input,
          recordType: _selectedType,
          resolver: _selectedResolver,
          statusMessage: 'Lookup failed: $e',
        );
      });
      SnackbarUtils.showError(context, 'DNS lookup failed: ${e.toString()}');
    }
  }

  Future<void> _shareDnsReport() async {
    final result = _lastResult;
    if (result == null || (result.records.isEmpty && !result.isSuccess)) {
      SnackbarUtils.showWarning(context, 'No DNS records to share');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('=== DNS Lookup Report ===');
    buffer.writeln('Target: ${result.domain}');
    buffer.writeln('Record Type: ${result.recordType}');
    buffer.writeln('Resolver: ${result.resolver.label} (${result.resolver.address})');
    buffer.writeln('Status: ${result.statusMessage}');
    buffer.writeln('Total Records: ${result.records.length}\n');

    for (final r in result.records) {
      if (r.type == 'SOA' && r.soaData != null) {
        final s = r.soaData!;
        buffer.writeln('[SOA Zone Information]');
        buffer.writeln('Primary NS:     ${s.primaryNs}');
        buffer.writeln('Admin Mailbox:  ${s.adminMailbox}');
        buffer.writeln('Serial:         ${s.serial}');
        buffer.writeln('Refresh:        ${s.refresh}');
        buffer.writeln('Retry:          ${s.retry}');
        buffer.writeln('Expire:         ${s.expire}');
        buffer.writeln('Minimum TTL:    ${s.minimumTtl}');
        buffer.writeln('Record TTL:     ${r.ttl ?? "N/A"}s\n');
      } else if (r.type == 'MX' && r.mxData != null) {
        final m = r.mxData!;
        buffer.writeln('[MX] Priority: ${m.priority} -> ${m.mailServer} (TTL: ${r.ttl ?? "N/A"}s)');
      } else {
        buffer.writeln('[${r.type}] ${r.value} (TTL: ${r.ttl ?? "N/A"}s)');
      }
    }

    await _shareService.shareText(
      buffer.toString(),
      subject: 'DNS Lookup - ${result.domain}',
    );
  }

  void _showResolverSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Select DNS Resolver',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose the DNS provider to resolve queries and test geo-propagation.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                ...DnsResolverType.values.map((res) {
                  final isSelected = _selectedResolver == res;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getResolverIcon(res),
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        res.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Text(
                        res.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0075FF), size: 22)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (_selectedResolver != res) {
                          setState(() => _selectedResolver = res);
                          _performLookup();
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getResolverIcon(DnsResolverType resolver) {
    switch (resolver) {
      case DnsResolverType.cloudflare:
        return Icons.cloud_done_rounded;
      case DnsResolverType.google:
        return Icons.search_rounded;
      case DnsResolverType.quad9:
        return Icons.security_rounded;
      case DnsResolverType.systemDefault:
        return Icons.devices_rounded;
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
          'DNS Lookup',
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
            onPressed: _shareDnsReport,
            tooltip: 'Share Records',
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Header Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input and Search Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        ),
                        child: TextField(
                          controller: _domainController,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _performLookup(),
                          decoration: InputDecoration(
                            hintText: _selectedType == 'PTR' ? 'e.g. 8.8.8.8' : 'e.g. google.com',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            prefixIcon: const Icon(Icons.dns_rounded, color: Color(0xFF0075FF), size: 20),
                            suffixIcon: _domainController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () => setState(() => _domainController.clear()),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _performLookup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0075FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.search_rounded, size: 18),
                          SizedBox(width: 4),
                          Text('Lookup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Resolver Selection Pill & Record Type Scroll
                Row(
                  children: [
                    // Resolver Selector Button
                    InkWell(
                      onTap: _showResolverSelector,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getResolverIcon(_selectedResolver), size: 14, color: const Color(0xFF0075FF)),
                            const SizedBox(width: 5),
                            Text(
                              _selectedResolver.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Record Type Chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _recordTypes.map((type) {
                            final isSelected = _selectedType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selectedType = type);
                                  _performLookup();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFFEFF6FF),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0075FF)),
              minHeight: 3,
            ),

          // Results Section
          Expanded(
            child: _buildResultsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (_isLoading) {
      return const SizedBox();
    }

    final result = _lastResult;
    if (result == null) {
      return _buildInitialState();
    }

    // 1. Missing Record / Empty Answer (NOERROR + 0 Answers)
    if (result.isNoRecords) {
      return _buildNoRecordsState(result);
    }

    // 2. Domain doesn't exist (NXDOMAIN)
    if (result.isNxDomain) {
      return _buildNxDomainState(result);
    }

    // 3. Error / SERVFAIL / Timeout / Validation
    if (result.isError) {
      return _buildErrorState(result);
    }

    // 4. Success with records
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'DNS RECORDS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NOERROR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${result.records.length} Found • ${result.resolver.label}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0075FF),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: result.records.length,
            itemBuilder: (context, index) {
              final record = result.records[index];
              if (record.type == 'SOA') {
                return _buildSoaCard(record);
              } else if (record.type == 'MX') {
                return _buildMxCard(record);
              }
              return _buildStandardCard(record);
            },
          ),
        ),
      ],
    );
  }

  /// Structured SOA Record Card displaying individual labeled fields
  Widget _buildSoaCard(DnsRecord record) {
    final soa = record.soaData;
    if (soa == null) {
      return _buildStandardCard(record);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SOA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Start of Authority Zone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (record.ttl != null)
                  Text(
                    'TTL: ${record.ttl}s',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),

          // Labeled Field Breakdown
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildSoaFieldRow(
                  label: 'Primary NS',
                  value: soa.primaryNs,
                  isHighlighted: true,
                  icon: Icons.dns_outlined,
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 16),
                _buildSoaFieldRow(
                  label: 'Admin Mailbox',
                  value: soa.adminMailbox,
                  icon: Icons.mail_outline_rounded,
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 16),
                _buildSoaFieldRow(
                  label: 'Serial Number',
                  value: soa.serial,
                  icon: Icons.confirmation_number_outlined,
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSoaMiniMetric('Refresh', soa.refresh, const Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSoaMiniMetric('Retry', soa.retry, const Color(0xFFD97706)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSoaMiniMetric('Expire', soa.expire, const Color(0xFFDC2626)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSoaMiniMetric('Min TTL', soa.minimumTtl, const Color(0xFF059669)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Raw String Accordion Copy
          InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: record.value));
              if (mounted) {
                SnackbarUtils.showCopySuccess(context, 'Full SOA Record');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0075FF)),
                  SizedBox(width: 6),
                  Text(
                    'Copy raw SOA record line',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0075FF),
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

  Widget _buildSoaFieldRow({
    required String label,
    required String value,
    required IconData icon,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
              color: isHighlighted ? const Color(0xFF0F172A) : const Color(0xFF334155),
              fontFamily: 'monospace',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFCBD5E1)),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (mounted) {
              SnackbarUtils.showCopySuccess(context, label);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSoaMiniMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Structured MX Record Card showing Priority badge and Mail Server host
  Widget _buildMxCard(DnsRecord record) {
    final mx = record.mxData;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // MX Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
            ),
            child: const Text(
              'MX',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Priority badge
          if (mx != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pri ${mx.priority}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0075FF),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Mail Server Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  mx?.mailServer ?? record.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    fontFamily: 'monospace',
                  ),
                ),
                if (record.ttl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'TTL: ${record.ttl}s',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF94A3B8)),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: mx?.mailServer ?? record.value));
              if (mounted) {
                SnackbarUtils.showCopySuccess(context, 'Mail Server');
              }
            },
          ),
        ],
      ),
    );
  }

  /// Standard Record Card for A, AAAA, TXT, NS, CNAME, PTR
  Widget _buildStandardCard(DnsRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
            ),
            child: Text(
              record.type,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0075FF),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  record.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    fontFamily: 'monospace',
                  ),
                ),
                if (record.ttl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'TTL: ${record.ttl}s',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF94A3B8)),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: record.value));
              if (mounted) {
                SnackbarUtils.showCopySuccess(context, record.type);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Neutral Informative State for NOERROR with 0 records
  Widget _buildNoRecordsState(DnsQueryResult result) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF64748B),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${result.recordType} Records Found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The domain "${result.domain}" does not have any ${result.recordType} records published on ${result.resolver.label}. (Status: NOERROR)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Warning State for NXDOMAIN
  Widget _buildNxDomainState(DnsQueryResult result) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.domain_disabled_rounded,
                color: Color(0xFFD97706),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Domain Does Not Exist',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Status: NXDOMAIN. No DNS zone exists for "${result.domain}". Check the spelling and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state (SERVFAIL / Timeout / Network Offline)
  Widget _buildErrorState(DnsQueryResult result) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.status == DnsQueryStatus.timeout ? 'Resolver Timed Out' : 'DNS Query Failed',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _performLookup,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Query'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0075FF),
                side: const BorderSide(color: Color(0xFF0075FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
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
              Icons.dns_rounded,
              color: Color(0xFF0075FF),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'DNS Lookup Tool',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter any domain or IP and select a record type.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
