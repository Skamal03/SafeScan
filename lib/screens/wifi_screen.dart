import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/wifi_model.dart';
import '../services/wifi_service.dart';
import '../services/database_service.dart';

class WiFiScreen extends StatefulWidget {
  const WiFiScreen({super.key});

  @override
  State<WiFiScreen> createState() => _WiFiScreenState();
}

class _WiFiScreenState extends State<WiFiScreen> {
  bool _isScanning = false;
  bool _isAnalyzing = false;
  String? _analyzingBssid; 
  List<WiFiAccessPoint> _accessPoints = [];
  WifiReport? _report;
  String _errorMessage = '';

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _accessPoints = [];
      _report = null;
      _errorMessage = '';
    });

    try {
      final canScan = await _handlePermissions();
      if (!canScan) {
        setState(() => _isScanning = false);
        return;
      }

      final results = await WifiService.scanNearbyNetworks();
      
      setState(() {
        _accessPoints = results;
        _isScanning = false;
      });
      
      if (results.isEmpty) {
        setState(() => _errorMessage = 'No networks found nearby. Ensure Wi-Fi is on.');
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _analyzeNetwork(WiFiAccessPoint ap) async {
    setState(() {
      _isAnalyzing = true;
      _analyzingBssid = ap.bssid;
      _report = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    final report = WifiService.analyzeNetwork(ap);

    // Save to History (Don't await, let it run in background)
    DatabaseService().saveReport(
      type: 'Wi-Fi Security Scan',
      status: report.status == 'secure' ? 'SAFE' : (report.status == 'warning' ? 'WARNING' : 'CRITICAL'),
      summary: "Network ${report.ssid} is ${report.status == 'secure' ? 'safe' : 'risky'}.",
      details: {
        'ssid': report.ssid,
        'bssid': report.bssid,
        'encryption': report.encryption,
        'score': report.score,
        'threats': report.threats,
      },
    ).catchError((e) => print("Firestore Error: $e"));

    setState(() {
      _report = report;
      _isAnalyzing = false;
      _analyzingBssid = null;
    });
    
    _scrollToReport();
  }

  Future<bool> _handlePermissions() async {
    final granted = await WifiService.requestLocationPermission();
    if (!granted) {
      setState(() => _errorMessage = 'Location permission is required to scan for Wi-Fi');
      return false;
    }
    bool isLocationOn = await WifiService.isGpsEnabled();
    if (!isLocationOn) {
      setState(() => _errorMessage = 'Please enable GPS/Location in settings');
      return false;
    }
    return true;
  }

  final ScrollController _scrollController = ScrollController();
  void _scrollToReport() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSecure = _report?.status == 'secure';
    final color = isSecure ? AppTheme.success : (_report?.status == 'warning' ? AppTheme.warning : AppTheme.danger);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Wi-Fi Security Scan')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Column(
                children: [
                  Icon(Icons.radar, size: 48, color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Scanning real-time network integrity', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ScanButton(
              label: _isScanning ? 'Scanning...' : 'Scan Nearby Networks',
              icon: Icons.wifi_find,
              isLoading: _isScanning,
              onPressed: _startScan,
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
            if (_accessPoints.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: 'Nearby Networks'),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _accessPoints.length,
                itemBuilder: (context, index) {
                  final ap = _accessPoints[index];
                  final bool isSelected = _analyzingBssid == ap.bssid || _report?.bssid == ap.bssid;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.05) : AppTheme.surface,
                      border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => _analyzeNetwork(ap),
                      leading: Icon(Icons.wifi, color: ap.level > -60 ? AppTheme.success : AppTheme.warning, size: 20),
                      title: Text(ap.ssid.isEmpty ? '[Hidden]' : ap.ssid, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text('MAC: ${ap.bssid} | ${ap.frequency}MHz', style: const TextStyle(fontSize: 9)),
                      trailing: _isAnalyzing && _analyzingBssid == ap.bssid
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.security, color: AppTheme.primary, size: 18),
                    ),
                  );
                },
              ),
            ],
            if (_report != null) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: 'Security Report'),
              GlowContainer(
                glowColor: color,
                child: Column(
                  children: [
                    InfoTile(label: 'Network', value: _report!.ssid, icon: Icons.wifi),
                    const Divider(),
                    InfoTile(label: 'Encryption', value: _report!.encryption!, icon: Icons.lock_outline),
                    const Divider(),
                    InfoTile(label: 'Safety Score', value: '${_report!.score}%', icon: Icons.analytics, valueColor: color),
                    const Divider(),
                    InfoTile(label: 'Status', value: _report!.status.toUpperCase(), icon: Icons.shield, valueColor: color),
                  ],
                ),
              ),
              if (_report!.threats.isNotEmpty) ...[
                const SizedBox(height: 16),
                Column(
                  children: _report!.threats.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), border: Border.all(color: AppTheme.danger.withOpacity(0.3))),
                    child: Row(children: [const Icon(Icons.warning, color: AppTheme.danger, size: 14), const SizedBox(width: 12), Expanded(child: Text(t, style: const TextStyle(color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.bold)))]),
                  )).toList(),
                ),
              ],
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
