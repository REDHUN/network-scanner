import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';

class MdnsService {
  Future<Map<String, String>> discoverHostnames() async {
    final client = MDnsClient();
    final Map<String, String> results = {};

    await client.start();

    await for (final PtrResourceRecord ptr
    in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_services._dns-sd._udp'))) {
      await for (final SrvResourceRecord srv
      in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName))) {
        results[srv.target] = srv.target;
      }
    }

    client.stop();
    return results;
  }
}
