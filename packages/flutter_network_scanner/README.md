# flutter_network_scanner

A high-performance local network scanner and device discovery plugin for Flutter. Discover all active devices on your local Wi-Fi subnet with hostnames, open service ports, UPnP/SSDP metadata, and ping latency.

[![pub package](https://img.shields.io/pub/v/flutter_network_scanner.svg)](https://pub.dev/packages/flutter_network_scanner)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

---

## Features

* ⚡ **High-Speed Subnet Sweeping**: Concurrently probes the active IPv4 subnet using its advertised prefix, with a safety bound for unusually large networks.
* 🔍 **Multi-Protocol Host Resolution on Android**:
  * **UPnP / SSDP (UDP 1900)**: Extracts `<friendlyName>`, `<manufacturer>`, `<modelName>`, and device types from Smart TVs, Media Servers, and Printers.
  * **NetBIOS (UDP 137)**: Queries Windows and Samba/NAS machine names.
  * **Reverse DNS PTR**: Canonical host resolution for routers, servers, and desktops.
  * **HTTP / HTTPS Banner Grabbing**: Reads `<title>` and `Server:` headers on open web ports.
* 🔌 **TCP Port Scanner**: Scans open ports (`80`, `443`, `22`, `445`, `8080`, `8008`, `62078`, `9100`, etc.) and maps them to known network services.
* 📶 **Network Interface Details**: Local IPv4, gateway IP, subnet mask, active interface name, and Wi-Fi SSID.
* ⚡ **Ping Latency**: Measure round-trip ping time in milliseconds to any IP.

---

## Installation

Add `flutter_network_scanner` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_network_scanner: ^1.0.0
```

---

## Platform Permissions

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required for network discovery and sockets -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
    
    <!-- Required to read Wi-Fi SSID and Gateway on Android -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
</manifest>
```

> **Note on MAC Addresses (Android 10+)**: Starting in Android 10 (API 29), Google restricts access to `/proc/net/arp` and kernel routing tables for all non-root apps. `flutter_network_scanner` gracefully reads MAC addresses opportunistically when available, and uses UPnP, SSDP, mDNS, and NetBIOS to identify device names and manufacturers when MAC is protected.

### iOS

The package supports iOS 12.0 and later using Apple's Network framework and BSD interface APIs. Add the local-network usage description to the host app's `Info.plist` (the iOS local-network prompt is shown by the system when discovery first runs):

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs access to the local network to discover and scan devices.</string>
```

The iOS implementation reports the same MethodChannel result keys as Android and performs TCP-based discovery. Hardware MAC addresses, Wi-Fi SSID, hostnames, and the default gateway may be unavailable because iOS restricts those values; they are returned as `null` when the system does not expose them. Android provides the additional UPnP/SSDP, NetBIOS, and HTTP metadata pipeline.

---

## Usage Example

### 1. Scan Local Subnet

```dart
import 'package:flutter_network_scanner/flutter_network_scanner.dart';

Future<void> scanLocalNetwork() async {
  try {
    final List<DiscoveredDevice> devices = await FlutterNetworkScanner.scanNetwork(
      timeoutMs: 250,
    );

    for (final device in devices) {
      print('IP: ${device.ip}');
      print('Name: ${device.displayName}');
      print('Vendor: ${device.vendor}');
      print('Open Ports: ${device.openPorts}');
      print('Ping: ${device.pingMs} ms');
      print('---');
    }
  } catch (e) {
    print('Scan failed: $e');
  }
}
```

### 2. Get Current Network Interface Info

```dart
final NetworkInfoModel? info = await FlutterNetworkScanner.getNetworkInfo();

if (info != null) {
  print('Local IP: ${info.ip}');
  print('Gateway: ${info.gateway}');
  print('Subnet Mask: ${info.subnet}');
  print('SSID: ${info.ssid}');
}
```

### 3. Ping a Specific Host

```dart
final int latencyMs = await FlutterNetworkScanner.pingHost('192.168.1.1');
print('Latency: $latencyMs ms');
```

### 4. Custom Multi-Port Scan

```dart
final List<int> openPorts = await FlutterNetworkScanner.scanPorts(
  '192.168.1.50',
  ports: [22, 80, 443, 3306, 8080, 9100],
  timeoutMs: 300,
);
print('Open ports on target: $openPorts');
```

---

## API Reference

### `FlutterNetworkScanner`

| Method | Return Type | Description |
| :--- | :--- | :--- |
| `scanNetwork({int timeoutMs = 250})` | `Future<List<DiscoveredDevice>>` | Concurrently scans the active IPv4 subnet range. Subnets larger than the native safety limit are rejected. |
| `getNetworkInfo()` | `Future<NetworkInfoModel?>` | Fetches local IP, subnet, gateway, SSID, and interface. |
| `pingHost(String ip, {int timeoutMs = 500})` | `Future<int>` | Measures ping latency in ms (-1 if unreachable). |
| `scanPorts(String ip, {List<int>? ports, int timeoutMs = 300})` | `Future<List<int>>` | Scans target TCP ports. |

---

## License

MIT License. See [LICENSE](LICENSE) for details.
