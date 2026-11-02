# Changelog

## 1.0.0

* Initial release of `flutter_network_scanner`.
* Native multi-threaded subnet discovery on Android (Kotlin) and iOS (Swift).
* Added iOS 12+ native discovery, ping, and TCP port scanning using Network.framework.
* Support for UPnP/SSDP device descriptor discovery (friendly name, manufacturer, model).
* NetBIOS name queries over UDP 137.
* Fast TCP connect scan on common service ports.
* Reverse DNS hostname resolution.
* Opportunistic ARP MAC cache reading (with graceful fallback on Android 10+).
* On-demand host ping latency measurement and custom multi-port TCP scanner.
* Improved iOS host discovery: TCP refused/reset responses now count as reachable hosts, Apple/AirPlay service ports are probed, and the first Local Network permission prompt gets time to resolve.
* Improved Android SSDP discovery for Amazon Echo/Alexa, Fire TV, and other UPnP/DIAL devices by binding to the active Wi-Fi interface, sending repeated targeted multicast searches, and retaining responders when their description endpoint is unavailable.
* Improved Android host discovery for silent devices by refreshing the ARP/neighbour table after UDP/TCP probes and recognizing Amazon hardware by MAC prefix.
* Fixed Android false positives by requiring an open service, successful reachability response, SSDP response, or a current `REACHABLE` Wi-Fi neighbour entry; stale ARP entries and generic TCP connection failures are no longer reported as online devices.
* Improved Android discovery of iPhone/iPad and Alexa devices using Bonjour/DNS-SD Apple service discovery and a non-blocking SSDP response collection pass.
* Fixed Apple reverse-DNS values containing MAC/IPv6 text being shown as device names.
* Sample Android Wi-Fi neighbors during the sweep so quiet devices seen as `REACHABLE` early in the scan are not lost when their entry becomes `STALE` before the TCP sweep finishes. Transitional and stale states are not treated as online.
* Use a pre-scan Wi-Fi neighbor snapshot to distinguish newly observed peers from old cached entries, and browse additional standard mDNS service types during Android discovery. Inspired by the multi-protocol scan strategy of usamaiqb/network-scanner (GPL-3.0); independently implemented here without copying its source.
* Look up PTR names for confirmed Android hosts against the active Wi-Fi gateway's DNS server, and prioritize Spotify Connect mDNS service discovery. DNS records never create online device entries on their own.
