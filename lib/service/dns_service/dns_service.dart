import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ip_tools/models/utilities_model/dns_record.dart';

class DnsService {
  /// Queries DNS records with the specified resolver and record type.
  Future<DnsQueryResult> query(
    String input, {
    String type = 'A',
    DnsResolverType resolver = DnsResolverType.cloudflare,
  }) async {
    final cleanInput = _cleanInput(input);
    if (cleanInput.isEmpty) {
      return DnsQueryResult(
        status: DnsQueryStatus.validationError,
        domain: input,
        recordType: type,
        resolver: resolver,
        statusMessage: 'Please enter a valid domain name or IP address',
      );
    }

    // Handle System Default Resolver
    if (resolver == DnsResolverType.systemDefault) {
      return _querySystemResolver(cleanInput, type);
    }

    // Query DoH Resolver
    return _queryDohResolver(cleanInput, type, resolver);
  }

  /// Backward-compatible query helper returning a simple list of records.
  Future<List<DnsRecord>> queryRecords(
    String domain, {
    String type = 'A',
    DnsResolverType resolver = DnsResolverType.cloudflare,
  }) async {
    final result = await query(domain, type: type, resolver: resolver);
    return result.records;
  }

  /// Queries DNS-over-HTTPS providers (Cloudflare, Google, Quad9).
  Future<DnsQueryResult> _queryDohResolver(
    String domain,
    String type,
    DnsResolverType resolver,
  ) async {
    String queryTarget = domain;

    // If querying PTR for an IP, convert to reverse DNS arpa format
    if (type.toUpperCase() == 'PTR') {
      final arpa = _formatArpaAddress(domain);
      if (arpa != null) {
        queryTarget = arpa;
      }
    }

    try {
      final Uri uri;
      if (resolver == DnsResolverType.google) {
        uri = Uri.parse('https://dns.google/resolve?name=$queryTarget&type=$type');
      } else {
        uri = Uri.parse('${resolver.dohUrl}?name=$queryTarget&type=$type');
      }

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/dns-json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final int rcode = data['Status'] as int? ?? 0;

        return _parseDohResponse(data, rcode, domain, type, resolver);
      } else {
        return DnsQueryResult(
          status: DnsQueryStatus.servFail,
          domain: domain,
          recordType: type,
          resolver: resolver,
          statusMessage: 'DNS server returned HTTP ${response.statusCode} (${resolver.label})',
        );
      }
    } on TimeoutException {
      return DnsQueryResult(
        status: DnsQueryStatus.timeout,
        domain: domain,
        recordType: type,
        resolver: resolver,
        statusMessage: 'Request to ${resolver.label} timed out. Check your internet connection.',
      );
    } on SocketException {
      return DnsQueryResult(
        status: DnsQueryStatus.timeout,
        domain: domain,
        recordType: type,
        resolver: resolver,
        statusMessage: 'Network unreachable or resolver unavailable.',
      );
    } catch (e) {
      return DnsQueryResult(
        status: DnsQueryStatus.error,
        domain: domain,
        recordType: type,
        resolver: resolver,
        statusMessage: 'DNS query error: $e',
      );
    }
  }

  /// Parses JSON response from DoH server according to RFC 8427 status codes.
  DnsQueryResult _parseDohResponse(
    Map<String, dynamic> data,
    int rcode,
    String domain,
    String type,
    DnsResolverType resolver,
  ) {
    switch (rcode) {
      case 0: // NOERROR
        final answer = data['Answer'] as List<dynamic>?;
        if (answer != null && answer.isNotEmpty) {
          final records = <DnsRecord>[];
          for (final item in answer) {
            if (item is Map<String, dynamic>) {
              records.add(DnsRecord.fromJson(item));
            }
          }
          if (records.isNotEmpty) {
            return DnsQueryResult(
              status: DnsQueryStatus.success,
              domain: domain,
              recordType: type,
              resolver: resolver,
              records: records,
              statusMessage: 'Successfully resolved ${records.length} record(s)',
              rcode: 0,
            );
          }
        }
        return DnsQueryResult(
          status: DnsQueryStatus.noRecordsFound,
          domain: domain,
          recordType: type,
          resolver: resolver,
          records: const [],
          statusMessage: 'No $type records found for this domain',
          rcode: 0,
        );

      case 2: // SERVFAIL
        return DnsQueryResult(
          status: DnsQueryStatus.servFail,
          domain: domain,
          recordType: type,
          resolver: resolver,
          statusMessage: 'DNS Server Failure (SERVFAIL)',
          rcode: 2,
        );

      case 3: // NXDOMAIN
        return DnsQueryResult(
          status: DnsQueryStatus.nxDomain,
          domain: domain,
          recordType: type,
          resolver: resolver,
          statusMessage: 'Domain does not exist (NXDOMAIN)',
          rcode: 3,
        );

      case 5: // REFUSED
        return DnsQueryResult(
          status: DnsQueryStatus.servFail,
          domain: domain,
          recordType: type,
          resolver: resolver,
          statusMessage: 'DNS Query Refused by Server (REFUSED)',
          rcode: 5,
        );

      default:
        return DnsQueryResult(
          status: DnsQueryStatus.error,
          domain: domain,
          recordType: type,
          resolver: resolver,
          statusMessage: 'DNS Error (RCODE: $rcode)',
          rcode: rcode,
        );
    }
  }

  /// Queries using the native OS resolver (`InternetAddress`).
  Future<DnsQueryResult> _querySystemResolver(String domain, String type) async {
    try {
      // PTR Reverse Lookup
      if (type.toUpperCase() == 'PTR') {
        try {
          final ipAddr = InternetAddress(domain);
          final host = await ipAddr.reverse();
          final record = DnsRecord(
            name: domain,
            type: 'PTR',
            value: host.host,
            ttl: 300,
          );
          return DnsQueryResult(
            status: DnsQueryStatus.success,
            domain: domain,
            recordType: type,
            resolver: DnsResolverType.systemDefault,
            records: [record],
            statusMessage: 'Resolved reverse PTR record',
            rcode: 0,
          );
        } catch (_) {
          return DnsQueryResult(
            status: DnsQueryStatus.noRecordsFound,
            domain: domain,
            recordType: type,
            resolver: DnsResolverType.systemDefault,
            statusMessage: 'No PTR reverse DNS record found for $domain',
          );
        }
      }

      // A / AAAA Lookup
      if (type == 'A' || type == 'AAAA') {
        final addresses = await InternetAddress.lookup(domain).timeout(const Duration(seconds: 4));
        final filtered = addresses.where((a) {
          if (type == 'A') return a.type == InternetAddressType.IPv4;
          if (type == 'AAAA') return a.type == InternetAddressType.IPv6;
          return true;
        }).toList();

        if (filtered.isNotEmpty) {
          final records = filtered
              .map(
                (a) => DnsRecord(
                  name: domain,
                  type: a.type == InternetAddressType.IPv4 ? 'A' : 'AAAA',
                  value: a.address,
                  ttl: 300,
                ),
              )
              .toList();

          return DnsQueryResult(
            status: DnsQueryStatus.success,
            domain: domain,
            recordType: type,
            resolver: DnsResolverType.systemDefault,
            records: records,
            statusMessage: 'Resolved ${records.length} record(s) via System DNS',
            rcode: 0,
          );
        }

        return DnsQueryResult(
          status: DnsQueryStatus.noRecordsFound,
          domain: domain,
          recordType: type,
          resolver: DnsResolverType.systemDefault,
          statusMessage: 'No $type records found for $domain',
          rcode: 0,
        );
      }

      // For other record types (MX, TXT, SOA, NS, CNAME) where native OS socket lacks direct API,
      // fallback smoothly to Cloudflare DoH to fulfill the user's inspection.
      return await _queryDohResolver(domain, type, DnsResolverType.cloudflare);
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 11001 || e.message.contains('Failed host lookup')) {
        return DnsQueryResult(
          status: DnsQueryStatus.nxDomain,
          domain: domain,
          recordType: type,
          resolver: DnsResolverType.systemDefault,
          statusMessage: 'Domain does not exist (NXDOMAIN)',
          rcode: 3,
        );
      }
      return DnsQueryResult(
        status: DnsQueryStatus.timeout,
        domain: domain,
        recordType: type,
        resolver: DnsResolverType.systemDefault,
        statusMessage: 'System DNS lookup failed: ${e.message}',
      );
    } catch (e) {
      return DnsQueryResult(
        status: DnsQueryStatus.error,
        domain: domain,
        recordType: type,
        resolver: DnsResolverType.systemDefault,
        statusMessage: 'System DNS error: $e',
      );
    }
  }

  /// Formats an IPv4 or IPv6 address into its standard reverse DNS `.arpa` zone format.
  String? _formatArpaAddress(String ip) {
    try {
      final addr = InternetAddress(ip);
      if (addr.type == InternetAddressType.IPv4) {
        final octets = ip.split('.');
        if (octets.length == 4) {
          return '${octets[3]}.${octets[2]}.${octets[1]}.${octets[0]}.in-addr.arpa';
        }
      } else if (addr.type == InternetAddressType.IPv6) {
        final clean = addr.rawAddress.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
        final reversedNibbles = clean.split('').reversed.join('.');
        return '$reversedNibbles.ip6.arpa';
      }
    } catch (_) {
      // If it's not an IP address, return domain as-is
    }
    return null;
  }

  /// Sanitizes input domain/IP.
  String _cleanInput(String input) {
    var cleaned = input.trim().toLowerCase();
    cleaned = cleaned.replaceAll(RegExp(r'^https?://'), '');
    cleaned = cleaned.split('/')[0];
    cleaned = cleaned.split(':')[0];
    return cleaned;
  }
}
