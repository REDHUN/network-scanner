class WolPacketResult {
  final bool isSuccess;
  final String macAddress;
  final String formattedMac;
  final String broadcastIp;
  final int port;
  final DateTime timestamp;
  final String? errorMessage;

  const WolPacketResult({
    required this.isSuccess,
    required this.macAddress,
    required this.formattedMac,
    required this.broadcastIp,
    required this.port,
    required this.timestamp,
    this.errorMessage,
  });
}
