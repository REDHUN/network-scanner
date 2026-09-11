import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tools/models/utilities_model/dns_record.dart';
import 'package:ip_tools/service/dns_service/dns_service.dart';

void main() {
  group('DNS Models & Parsing Tests', () {
    test('SOA record parser handles standard RFC 1035 format', () {
      const raw = 'ns1.google.com. dns-admin.google.com. 977807449 900 900 1800 60';
      final soa = SoaRecordData.parse(raw);

      expect(soa, isNotNull);
      expect(soa!.primaryNs, 'ns1.google.com.');
      expect(soa.adminMailbox, 'dns-admin.google.com.');
      expect(soa.serial, '977807449');
      expect(soa.refresh, '900s');
      expect(soa.retry, '900s');
      expect(soa.expire, '1800s');
      expect(soa.minimumTtl, '60s');
    });

    test('SOA record parser handles partial/malformed strings safely', () {
      const raw = 'ns1.example.com admin.example.com 12345';
      final soa = SoaRecordData.parse(raw);

      expect(soa, isNotNull);
      expect(soa!.primaryNs, 'ns1.example.com');
      expect(soa.adminMailbox, 'admin.example.com');
      expect(soa.serial, '12345');
    });

    test('MX record parser handles priority and mail server', () {
      const raw = '10 smtp.google.com.';
      final mx = MxRecordData.parse(raw);

      expect(mx, isNotNull);
      expect(mx!.priority, 10);
      expect(mx.mailServer, 'smtp.google.com.');
    });

    test('DnsRecord.fromJson parses JSON correctly and strips TXT quotes', () {
      final jsonTxt = {
        'name': 'google.com.',
        'type': 16,
        'TTL': 300,
        'data': '"v=spf1 include:_spf.google.com ~all"',
      };
      final record = DnsRecord.fromJson(jsonTxt);

      expect(record.name, 'google.com.');
      expect(record.type, 'TXT');
      expect(record.ttl, 300);
      expect(record.value, 'v=spf1 include:_spf.google.com ~all');
    });

    test('DnsRecord resolves all supported DNS types correctly', () {
      expect(DnsRecord.typeStringToNumber('A'), 1);
      expect(DnsRecord.typeStringToNumber('NS'), 2);
      expect(DnsRecord.typeStringToNumber('CNAME'), 5);
      expect(DnsRecord.typeStringToNumber('SOA'), 6);
      expect(DnsRecord.typeStringToNumber('PTR'), 12);
      expect(DnsRecord.typeStringToNumber('MX'), 15);
      expect(DnsRecord.typeStringToNumber('TXT'), 16);
      expect(DnsRecord.typeStringToNumber('AAAA'), 28);
    });
  });

  group('DnsService Validation Tests', () {
    final service = DnsService();

    test('Returns validationError for empty or whitespace query', () async {
      final result = await service.query('   ', type: 'A');
      expect(result.status, DnsQueryStatus.validationError);
      expect(result.records, isEmpty);
    });
  });
}
