import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/wifi_model.dart';
import '../services/wifi_service.dart';

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

  // --- UI ACTIONS ---

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _accessPoints = [];
      _report = null;
      _errorMessage = '';
    });

    try {
      // 1. Delegate Permission & GPS Check to Service and UI
      final canScan = await _handlePermissions();
      if (!canScan) {
        setState(() => _isScanning = false);
        return;
      }

      // 2. Call Service to perform Hardware Scan
      final results = await WifiService.scanNearbyNetworks();
      
      setState(() {
        _accessPoints = results;
        _isScanning = false;
      });
      
      if (results.isEmpty) {
        setState(() => _errorMessage = 'No networks found nearby');
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

    // Simulate thinking time for user experience
    await Future.delayed(const Duration(milliseconds: 800));

    // Call Service for Security Analysis
    final report = WifiService.analyzeNetwork(ap);

    setState(() {
      _report = report;
      _isAnalyzing = false;
      _analyzingBssid = null;
    });
    
    _scrollToReport();
  }

  // --- PERMISSION HANDLERS (UI Component) ---

  Future<bool> _handlePermissions() async {
    // A. Check Location Permission via Service
    final granted = await WifiService.requestLocationPermission();
    if (!granted) {
      setState(() => _errorMessage = 'Location permission is required to scan for Wi-Fi');
      return false;
    }

    // B. Check GPS Status via Service
    bool isLocationOn = await WifiService.isGpsEnabled();
    while (!isLocationOn) {
      final result = await _showGpsDialog();
      if (result != true) return false;
      
      await Future.delayed(const Duration(seconds: 1));
      isLocationOn = await WifiService.isGpsEnabled();
    }
    return true;
  }

  Future<bool?> _showGpsDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Location Required', style: TextStyle(color: AppTheme.primary)),
        content: const Text('Please enable location services to scan for Wi-Fi networks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          OutlinedButton(
            onPressed: () { 
              openAppSettings(); 
              Navigator.pop(context, true); 
            }, 
            child: const Text('Settings'),
          ),
        ],
      ),
    );
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
                  Text('Scanning for nearby networks', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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
              Text(_errorMessage, style: const TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
            if (_accessPoints.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: 'Found Networks'),
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
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : AppTheme.surface,
                      border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => _analyzeNetwork(ap),
                      leading: Icon(Icons.wifi, color: ap.level > -60 ? AppTheme.success : AppTheme.warning, size: 20),
                      title: Text(ap.ssid.isEmpty ? '[Hidden Network]' : ap.ssid, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                    if (_report!.encryption != null) ...[
                      InfoTile(label: 'Security', value: _report!.encryption!, icon: Icons.lock_outline),
                      const Divider(),
                    ],
                    if (_report!.signal != null) ...[
                      InfoTile(label: 'Signal', value: '${_report!.signal} dBm', icon: Icons.signal_wifi_4_bar),
                      const Divider(),
                    ],
                    InfoTile(label: 'Safety Score', value: '${_report!.score}%', icon: Icons.analytics, valueColor: color),
                    const Divider(),
                    InfoTile(label: 'Status', value: _report!.status == 'secure' ? 'Safe' : (_report!.status == 'warning' ? 'At Risk' : 'Danger'), icon: Icons.shield, valueColor: color),
                  ],
                ),
              ),
              if (_report!.threats.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: 'Security Issues'),
                GlowContainer(
                  glowColor: AppTheme.danger,
                  child: Column(
                    children: _report!.threats.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [const Icon(Icons.warning, color: AppTheme.danger, size: 14), const SizedBox(width: 12), Expanded(child: Text(t, style: const TextStyle(color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.bold)))]),
                    )).toList(),
                  ),
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
