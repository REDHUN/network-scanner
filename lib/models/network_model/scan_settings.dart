class ScanSettings {
  final int firstHost;
  final int lastHost;
  final int pingTimeout;

  const ScanSettings({
    this.firstHost = 1,
    this.lastHost = 254,
    this.pingTimeout = 1,
  });

  Map<String, dynamic> toJson() => {
    'firstHost': firstHost,
    'lastHost': lastHost,
    'pingTimeout': pingTimeout,
  };

  factory ScanSettings.fromJson(Map<String, dynamic> json) {
    return ScanSettings(
      firstHost: json['firstHost'] ?? 1,
      lastHost: json['lastHost'] ?? 254,
      pingTimeout: json['pingTimeout'] ?? 1,
    );
  }
}
