# flutter_network_scanner: Comprehensive Developer Guide & Documentation

`flutter_network_scanner` is a high-performance local network scanner and device discovery plugin for Flutter. It enables Flutter applications to discover active devices on local subnets, resolve device hostnames and manufacturers across multiple network discovery protocols, measure ping latency, and perform targeted TCP port scans.

---

## Table of Contents

1. [Architecture & Discovery Pipeline](#architecture--discovery-pipeline)
2. [Installation & Platform Configuration](#installation--platform-configuration)
3. [Android 10+ Privacy & MAC Address Handling](#android-10-privacy--mac-address-handling)
4. [API Reference](#api-reference)
   - [FlutterNetworkScanner](#flutternetworkscanner)
   - [DiscoveredDevice](#discovereddevice)
   - [NetworkInfoModel](#networkinfomodel)
5. [Code Recipes & Examples](#code-recipes--examples)
   - [Recipe 1: Simple Subnet Sweep](#recipe-1-simple-subnet-sweep)
   - [Recipe 2: Fetch Current Wi-Fi Details](#recipe-2-fetch-current-wi-fi-details)
   - [Recipe 3: Continuous Ping & Latency Check](#recipe-3-continuous-ping--latency-check)
   - [Recipe 4: Deep Port Scanning on a Target Host](#recipe-4-deep-port-scanning-on-a-target-host)
   - [Recipe 5: Production Flutter UI Integration](#recipe-5-production-flutter-ui-integration)
6. [Known Port-to-Service Mappings](#known-port-to-service-mappings)
7. [Troubleshooting & FAQs](#troubleshooting--faqs)

---

## Architecture & Discovery Pipeline

`flutter_network_scanner` uses a hybrid native execution model. Intensive network sweeps run concurrently across a native background thread pool (64 worker threads), executing multiple discovery protocols in parallel before aggregating the results back to the Flutter runtime.

```
                     ┌───────────────────────────────┐
                     │     Flutter Application       │
                     │  FlutterNetworkScanner (Dart) │
                     └──────────────┬────────────────┘
                                    │ MethodChannel
                                    ▼
                     ┌───────────────────────────────┐
                     │   Native Kotlin Core Plugin   │
                     │ (FlutterNetworkScannerPlugin) │
                     └──────────────┬────────────────┘
                                    │
    ┌───────────────────────────────┼───────────────────────────────┐
    ▼                               ▼                               ▼
┌──────────────┐            ┌──────────────┐            ┌──────────────┐
│ Subnet Sweep │            │  UPnP / SSDP │            │ NetBIOS Name │
│ Concurrent   │            │  Multicast   │            │ UDP 137      │
│ TCP Probing  │            │  (UDP 1900)  │            │ Probe        │
└───────┬──────┘            └───────┬──────┘            └───────┬──────┘
        │                           │                           │
        ▼                           ▼                           ▼
┌──────────────┐            ┌──────────────┐            ┌──────────────┐
│ HTTP Banner  │            │ Reverse DNS  │            │ Opportunistic│
│ Title Grab   │            │ PTR Lookup   │            │ ARP Cache    │
└───────┴──────┘            └───────┴──────┘            └───────┴──────┘
                                    │
                                    ▼
                     ┌───────────────────────────────┐
                     │ Device Aggregation & Inference│
                     │  • Hostname & Model Name      │
                     │  • Manufacturer / Vendor      │
                     │  • Device Type Classification │
                     └───────────────────────────────┘
```

---

## Installation & Platform Configuration

### 1. Add Dependency

In your application's `pubspec.yaml`:

```yaml
dependencies:
  flutter_network_scanner: ^1.0.0
```

### 2. Android Configuration

Add the required permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Essential Network Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />

    <!-- Required for Wi-Fi SSID, Gateway, and Subnet on Android 8.1+ -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

</manifest>
```

---

## Android 10+ Privacy & MAC Address Handling

Starting in **Android 10 (API Level 29)**, Google introduced strict privacy restrictions:
* Access to the kernel ARP table (`/proc/net/arp`) is blocked for all third-party, non-root applications.
* Direct hardware MAC addresses for network interfaces are randomized or masked (`02:00:00:00:00:00`).

### How `flutter_network_scanner` Resolves Device Identity
Rather than relying on restricted MAC addresses, `flutter_network_scanner` queries multiple discovery protocols:

1. **UPnP / SSDP (UDP 1900)**: Asks devices for their XML descriptors, obtaining `<friendlyName>`, `<manufacturer>`, and `<modelName>`.
2. **NetBIOS Name Query (UDP 137)**: Reads Windows PC and Samba/NAS network names.
3. **HTTP / Web Title Extraction**: Connects to ports 80, 8080, and 8008 to parse `<title>` tags (e.g. *TP-Link Router*, *Synology DiskStation*).
4. **Reverse DNS**: Resolves canonical PTR hostnames.

---

## API Reference

### `FlutterNetworkScanner`

The main static interface for interacting with the plugin.

#### `scanNetwork({int timeoutMs = 250}) -> Future<List<DiscoveredDevice>>`
Scans the current active `/24` subnet across 64 native background threads.
* **Parameters**:
  * `timeoutMs` *(int, default: 250)*: Timeout per TCP socket connect probe.
* **Returns**: A list of `DiscoveredDevice` objects sorted numerically by IP.

#### `getNetworkInfo() -> Future<NetworkInfoModel?>`
Retrieves connection metadata for the currently active network interface.
* **Returns**: `NetworkInfoModel` containing local IP, subnet mask, gateway, SSID, and interface name.

#### `pingHost(String ip, {int timeoutMs = 500}) -> Future<int>`
Measures round-trip latency to a target host in milliseconds.
* **Parameters**:
  * `ip` *(String)*: Target IPv4 address.
  * `timeoutMs` *(int, default: 500)*: Maximum time to wait.
* **Returns**: Latency in milliseconds (`-1` if unreachable).

#### `scanPorts(String ip, {List<int>? ports, int timeoutMs = 300}) -> Future<List<int>>`
Runs a multi-threaded TCP port scan against a specific host.
* **Parameters**:
  * `ip` *(String)*: Target host IP.
  * `ports` *(List<int>?, default: [80, 443, 22, 21, 8080, 445, 53, 3389, 8008, 9100])*: Ports to test.
  * `timeoutMs` *(int, default: 300)*: Connect timeout per port.
* **Returns**: A sorted list of open port numbers.

---

### `DiscoveredDevice`

| Property | Type | Description |
| :--- | :--- | :--- |
| `ip` | `String` | Discovered IPv4 address. |
| `hostname` | `String?` | Resolved hostname, UPnP friendly name, or NetBIOS name. |
| `openPorts` | `List<int>` | Ports confirmed open during scan. |
| `mac` | `String?` | Hardware MAC address (if accessible on device OS). |
| `vendor` | `String?` | Device manufacturer or vendor name. |
| `pingMs` | `int` | Round-trip latency in milliseconds. |
| `deviceType` | `String` | Inferred category (`router`, `mobile`, `pc`, `server`, `printer`, `smart_tv`, `generic`). |
| `isCurrentDevice`| `bool` | True if this host represents the scanning device itself. |
| `isGateway` | `bool` | True if this host matches the default gateway / router IP. |
| `displayName` | `String` (getter) | Returns `hostname`, or fallback category title. |

---

### `NetworkInfoModel`

| Property | Type | Description |
| :--- | :--- | :--- |
| `ip` | `String` | This device's local IPv4 address (e.g. `192.168.1.100`). |
| `subnet` | `String` | Subnet mask (e.g. `255.255.255.0`). |
| `gateway` | `String?` | Default gateway / router IP (e.g. `192.168.1.1`). |
| `ssid` | `String?` | Connected Wi-Fi SSID name. |
| `ifaceName` | `String?` | Active network interface name (e.g. `wlan0`). |

---

## Code Recipes & Examples

### Recipe 1: Simple Subnet Sweep

```dart
import 'package:flutter_network_scanner/flutter_network_scanner.dart';

Future<void> runSubnetSweep() async {
  try {
    print('Starting subnet discovery...');
    final devices = await FlutterNetworkScanner.scanNetwork(timeoutMs: 200);

    print('Discovered ${devices.length} devices:');
    for (final device in devices) {
      print('[${device.ip}] ${device.displayName} - '
            'Vendor: ${device.vendor ?? "Unknown"} - '
            'Ping: ${device.pingMs}ms - '
            'Ports: ${device.openPorts}');
    }
  } catch (e) {
    print('Discovery failed: $e');
  }
}
```

---

### Recipe 2: Fetch Current Wi-Fi Details

```dart
import 'package:flutter_network_scanner/flutter_network_scanner.dart';

Future<void> displayNetworkInfo() async {
  final info = await FlutterNetworkScanner.getNetworkInfo();
  if (info != null) {
    print('SSID: ${info.ssid}');
    print('Local IP: ${info.ip}');
    print('Gateway: ${info.gateway}');
    print('Subnet Mask: ${info.subnet}');
    print('Interface: ${info.ifaceName}');
  }
}
```

---

### Recipe 3: Continuous Ping & Latency Check

```dart
import 'package:flutter_network_scanner/flutter_network_scanner.dart';

Future<void> monitorHostPing(String ip) async {
  for (int i = 0; i < 5; i++) {
    final latency = await FlutterNetworkScanner.pingHost(ip, timeoutMs: 500);
    if (latency >= 0) {
      print('Reply from $ip: time=${latency}ms');
    } else {
      print('Request timed out for $ip');
    }
    await Future.delayed(const Duration(seconds: 1));
  }
}
```

---

### Recipe 4: Deep Port Scanning on a Target Host

```dart
import 'package:flutter_network_scanner/flutter_network_scanner.dart';

Future<void> scanCommonServices(String ip) async {
  const targetPorts = [
    21, 22, 23, 25, 53, 80, 110, 139, 143, 443, 445,
    3306, 3389, 5432, 8008, 8080, 8443, 9100
  ];

  final open = await FlutterNetworkScanner.scanPorts(
    ip,
    ports: targetPorts,
    timeoutMs: 350,
  );

  print('Open ports on $ip:');
  for (final port in open) {
    final serviceName = DiscoveredDevice.getPortServiceName(port);
    print(' -> Port $port ($serviceName)');
  }
}
```

---

### Recipe 5: Production Flutter UI Integration

```dart
import 'package:flutter/material.dart';
import 'package:flutter_network_scanner/flutter_network_scanner.dart';

class QuickScannerWidget extends StatefulWidget {
  const QuickScannerWidget({super.key});

  @override
  State<QuickScannerWidget> createState() => _QuickScannerWidgetState();
}

class _QuickScannerWidgetState extends State<QuickScannerWidget> {
  bool _loading = false;
  List<DiscoveredDevice> _devices = [];

  Future<void> _scan() async {
    setState(() => _loading = true);
    try {
      final results = await FlutterNetworkScanner.scanNetwork();
      setState(() => _devices = results);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Devices')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  leading: Icon(
                    device.isGateway ? Icons.router : Icons.devices,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(device.displayName),
                  subtitle: Text('${device.ip} • ${device.vendor ?? "Generic"}'),
                  trailing: Text('${device.pingMs} ms'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _scan,
        child: const Icon(Icons.search),
      ),
    );
  }
}
```

---

## Known Port-to-Service Mappings

`DiscoveredDevice.getPortServiceName(int port)` converts common TCP ports to their service names:

| Port | Service | Description |
| :--- | :--- | :--- |
| `21` | FTP | File Transfer Protocol |
| `22` | SSH | Secure Shell / Linux Server |
| `53` | DNS | Domain Name System |
| `80` | HTTP | Web Server / Router Admin Interface |
| `139` / `445` | SMB | Windows Share / NetBIOS / NAS |
| `443` | HTTPS | Secure Web Server |
| `3389` | RDP | Windows Remote Desktop |
| `5000` | UPnP / AirPlay | Media Streaming / Apple AirPlay |
| `8008` / `8009` | Chromecast | Google Cast Audio / Video |
| `8080` / `8443` | HTTP-Alt | Alternate Web Server / Proxy |
| `9100` | Printer | RAW Print / JetDirect |
| `62078` | Apple Sync | iPhone / iPad / Mac Wi-Fi Sync |

---

## Troubleshooting & FAQs

#### Q: Why is the MAC address null on some Android devices?
**A:** On Android 10 (API 29) and above, Google restricts direct access to `/proc/net/arp` and kernel routing tables for all non-root apps. The plugin uses UPnP/SSDP, NetBIOS, and HTTP banner title extraction to identify device names and manufacturers when the MAC is protected.

#### Q: How can I obtain Wi-Fi SSID and Gateway on Android?
**A:** Android requires location permissions (`ACCESS_FINE_LOCATION`) and location services to be enabled before the OS returns Wi-Fi details (SSID/Gateway). Request permission via `permission_handler` before calling `getNetworkInfo()`.

#### Q: How fast is the subnet sweep?
**A:** The subnet sweep runs 254 host probes concurrently across 64 worker threads. With a default socket timeout of `220ms - 250ms`, full `/24` subnet discovery completes in under 2 to 3 seconds.
