# Changelog

## 1.0.0

* Initial release of `flutter_network_scanner`.
* Native multi-threaded `/24` subnet discovery on Android via Kotlin.
* Support for UPnP/SSDP device descriptor discovery (friendly name, manufacturer, model).
* NetBIOS name queries over UDP 137.
* Fast TCP connect scan on common service ports.
* Reverse DNS hostname resolution.
* Opportunistic ARP MAC cache reading (with graceful fallback on Android 10+).
* On-demand host ping latency measurement and custom multi-port TCP scanner.
