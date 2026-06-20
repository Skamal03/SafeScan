class WifiReport {
  final String ssid;
  final String bssid;
  final int score;
  final String status;
  final List<String> threats;
  final String? ip;
  final String? gateway;
  final String? frequency;
  final String? encryption;
  final int? signal;

  WifiReport({
    required this.ssid,
    required this.bssid,
    required this.score,
    required this.status,
    required this.threats,
    this.ip,
    this.gateway,
    this.frequency,
    this.encryption,
    this.signal,
  });

  factory WifiReport.fromJson(Map<String, dynamic> json) {
    return WifiReport(
      ssid: json['ssid'] ?? 'Unknown',
      bssid: json['bssid'] ?? '00:00:00:00:00:00',
      score: json['score'] ?? 0,
      status: json['status'] ?? 'danger',
      threats: List<String>.from(json['threats'] ?? []),
      ip: json['ip'],
      gateway: json['gateway'],
      frequency: json['frequency'],
      encryption: json['encryption'],
      signal: json['signal'],
    );
  }
}
