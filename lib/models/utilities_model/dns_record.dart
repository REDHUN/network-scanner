/// Represents structured data for an SOA (Start of Authority) DNS record.
class SoaRecordData {
  final String primaryNs;
  final String adminMailbox;
  final String serial;
  final String refresh;
  final String retry;
  final String expire;
  final String minimumTtl;

  const SoaRecordData({
    required this.primaryNs,
    required this.adminMailbox,
    required this.serial,
    required this.refresh,
    required this.retry,
    required this.expire,
    required this.minimumTtl,
  });

  /// Parses raw SOA record value (space-delimited tokens according to RFC 1035).
  /// Format: `<mname> <rname> <serial> <refresh> <retry> <expire> <minimum>`
  static SoaRecordData? parse(String rawValue) {
    if (rawValue.trim().isEmpty) return null;
    final tokens = rawValue.trim().split(RegExp(r'\s+'));
    if (tokens.length < 7) {
      return SoaRecordData(
        primaryNs: tokens.isNotEmpty ? tokens[0] : rawValue,
        adminMailbox: tokens.length > 1 ? tokens[1] : '-',
        serial: tokens.length > 2 ? tokens[2] : '-',
        refresh: tokens.length > 3 ? '${tokens[3]}s' : '-',
        retry: tokens.length > 4 ? '${tokens[4]}s' : '-',
        expire: tokens.length > 5 ? '${tokens[5]}s' : '-',
        minimumTtl: tokens.length > 6 ? '${tokens[6]}s' : '-',
      );
    }

    return SoaRecordData(
      primaryNs: tokens[0],
      adminMailbox: tokens[1],
      serial: tokens[2],
      refresh: '${tokens[3]}s',
      retry: '${tokens[4]}s',
      expire: '${tokens[5]}s',
      minimumTtl: '${tokens[6]}s',
    );
  }
}

/// Represents structured data for an MX (Mail Exchange) DNS record.
class MxRecordData {
  final int priority;
  final String mailServer;

  const MxRecordData({
    required this.priority,
    required this.mailServer,
  });

  /// Parses raw MX record value: `<priority> <mailServer>`
  static MxRecordData? parse(String rawValue) {
    if (rawValue.trim().isEmpty) return null;
    final parts = rawValue.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final prio = int.tryParse(parts[0]) ?? 0;
      final server = parts.sublist(1).join(' ');
      return MxRecordData(priority: prio, mailServer: server);
    }
    return MxRecordData(priority: 0, mailServer: rawValue.trim());
  }
}

/// Individual DNS record entry
class DnsRecord {
  final String name;
  final String type;
  final String value;
  final int? ttl;

  const DnsRecord({
    required this.name,
    required this.type,
    required this.value,
    this.ttl,
  });

  /// Parsed SOA data if this record is of type SOA
  SoaRecordData? get soaData => type == 'SOA' ? SoaRecordData.parse(value) : null;

  /// Parsed MX data if this record is of type MX
  MxRecordData? get mxData => type == 'MX' ? MxRecordData.parse(value) : null;

  factory DnsRecord.fromJson(Map<String, dynamic> json) {
    var rawData = json['data'] as String? ?? '';
    // Strip surrounding quotes if TXT record
    if (rawData.startsWith('"') && rawData.endsWith('"') && rawData.length >= 2) {
      rawData = rawData.substring(1, rawData.length - 1);
    }

    return DnsRecord(
      name: json['name'] as String? ?? '',
      type: _typeNumberToString(json['type'] as int? ?? 1),
      value: rawData,
      ttl: json['TTL'] as int?,
    );
  }

  static String _typeNumberToString(int type) {
    switch (type) {
      case 1:
        return 'A';
      case 2:
        return 'NS';
      case 5:
        return 'CNAME';
      case 6:
        return 'SOA';
      case 12:
        return 'PTR';
      case 15:
        return 'MX';
      case 16:
        return 'TXT';
      case 28:
        return 'AAAA';
      default:
        return 'TYPE_$type';
    }
  }

  static int typeStringToNumber(String type) {
    switch (type.toUpperCase()) {
      case 'A':
        return 1;
      case 'NS':
        return 2;
      case 'CNAME':
        return 5;
      case 'SOA':
        return 6;
      case 'PTR':
        return 12;
      case 'MX':
        return 15;
      case 'TXT':
        return 16;
      case 'AAAA':
        return 28;
      default:
        return 1;
    }
  }
}

/// DNS status result
enum DnsQueryStatus {
  success,
  noRecordsFound,
  nxDomain,
  servFail,
  timeout,
  validationError,
  error,
}

/// Available DNS resolvers for user selection
enum DnsResolverType {
  cloudflare('Cloudflare', '1.1.1.1', 'https://cloudflare-dns.com/dns-query'),
  google('Google', '8.8.8.8', 'https://dns.google/resolve'),
  quad9('Quad9', '9.9.9.9', 'https://dns.quad9.net/dns-query'),
  systemDefault('System Default', 'Native OS', '');

  final String label;
  final String address;
  final String dohUrl;

  const DnsResolverType(this.label, this.address, this.dohUrl);
}

/// Result envelope containing DNS status, resolver, and list of records.
class DnsQueryResult {
  final DnsQueryStatus status;
  final String domain;
  final String recordType;
  final DnsResolverType resolver;
  final List<DnsRecord> records;
  final String statusMessage;
  final int? rcode;

  const DnsQueryResult({
    required this.status,
    required this.domain,
    required this.recordType,
    required this.resolver,
    this.records = const [],
    required this.statusMessage,
    this.rcode,
  });

  bool get isSuccess => status == DnsQueryStatus.success && records.isNotEmpty;
  bool get isNoRecords => status == DnsQueryStatus.noRecordsFound;
  bool get isNxDomain => status == DnsQueryStatus.nxDomain;
  bool get isError => status == DnsQueryStatus.servFail || status == DnsQueryStatus.error || status == DnsQueryStatus.timeout || status == DnsQueryStatus.validationError;
}
