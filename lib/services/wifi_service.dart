import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/wifi_model.dart';

class WifiService {
  // --- 1. SCANNING LOGIC ---
  static Future<List<WiFiAccessPoint>> scanNearbyNetworks() async {
    try {
      // Check if we can start scan (Hardware status)
      final canStartStatus = await WiFiScan.instance.canStartScan();
      if (canStartStatus != CanStartScan.yes) {
        if (canStartStatus == CanStartScan.failed) {
          throw Exception('HARDWARE_THROTTLED: PLEASE_WAIT_A_MINUTE');
        } else {
          throw Exception('WIFI_NOT_SUPPORTED: $canStartStatus');
        }
      }

      // Request actual scan
      final isScanStarted = await WiFiScan.instance.startScan();
      if (!isScanStarted) throw Exception('SCAN_REQUEST_REJECTED');

      // Wait for hardware to populate results
      await Future.delayed(const Duration(seconds: 1));
      return await WiFiScan.instance.getScannedResults();
    } catch (e) {
      print("Wi-Fi Scan Error: $e");
      rethrow;
    }
  }

  // --- 2. PERMISSION CHECK LOGIC ---
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> isGpsEnabled() async {
    return await Permission.location.serviceStatus.isEnabled;
  }

  // --- 3. SECURITY ANALYSIS ENGINE ---
  static WifiReport analyzeNetwork(WiFiAccessPoint ap) {
    int score = 100;
    List<String> threats = [];
    String status = "secure";

    final caps = ap.capabilities.toUpperCase();
    String encType = "OPEN";
    
    if (caps.contains("WPA3")) {
      encType = "WPA3 (SECURE)";
    } else if (caps.contains("WPA2")) {
      encType = "WPA2 (STANDARD)";
    } else if (caps.contains("WPA")) {
      encType = "WPA (LEGACY)";
    } else if (caps.contains("WEP")) {
      encType = "WEP (VULNERABLE)";
      score -= 40;
      threats.add("LEGACY_ENCRYPTION: WEP_IS_EASILY_CRACKED");
    } else {
      score -= 60;
      threats.add("OPEN_NETWORK: NO_ENCRYPTION_DETECTED");
    }

    final ssid = ap.ssid.toUpperCase();
    if (ssid.contains("FREE") || ssid.contains("PUBLIC") || ssid.contains("GUEST")) {
      score -= 15;
      threats.add("SUSPICIOUS_SSID: POTENTIAL_PHISHING_TRAP");
    }

    if (ap.level > -30) {
      score -= 10;
      threats.add("SIGNAL_ANOMALY: UNUSUALLY_STRONG_PROXIMITY");
    }

    if (score < 50) {
      status = "danger";
    } else if (score < 80) {
      status = "warning";
    }

    return WifiReport(
      ssid: ap.ssid.isEmpty ? "[HIDDEN]" : ap.ssid,
      bssid: ap.bssid,
      score: score,
      status: status,
      threats: threats,
      frequency: "${ap.frequency}MHz",
      encryption: encType,
      signal: ap.level,
    );
  }
}
