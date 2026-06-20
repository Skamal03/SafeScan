import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/device_service.dart';
import '../services/app_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  int _overallScore = 0;
  int _appCount = 0;
  Map<String, int> _scores = {};
  List<String> _logs = [];

  List<Map<String, dynamic>> _detailedThreats = [];
  Map<String, dynamic>? _deviceAudit;
  final _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _generateRealReport();
  }

  Future<void> _generateRealReport() async {
    setState(() {
      _isLoading = true;
      _logs = [
        'Starting security check...',
        'Checking system health...',
      ];
      _detailedThreats = [];
    });
    
    try {
      // 1. Run Real Device Audit
      _addLog('Checking device status...');
      final deviceAudit = await DeviceService.getFullDeviceAudit();
      _deviceAudit = deviceAudit;
      int deviceScore = 100;
      
      if (deviceAudit['isRooted']) {
        deviceScore -= 40;
        _addLog('Alert: Device is rooted');
        _detailedThreats.add({
          'title': 'Device Rooted',
          'detail': 'Your device has root access enabled, which allows apps to bypass standard security restrictions.',
          'severity': 'Critical',
        });
      }
      
      if (deviceAudit['isDevMode']) {
        deviceScore -= 20;
        _addLog('Warning: Developer mode is on');
        _detailedThreats.add({
          'title': 'Developer Mode Active',
          'detail': 'Developer options are enabled. This increases the attack surface of your device via USB debugging.',
          'severity': 'Warning',
        });
      }

      // 2. Run Real App Audit
      _addLog('Scanning installed apps...');
      final apps = await AppService.getInstalledAppsAudit();
      
      // Filter for non-system apps as "potential risks" to show details
      final suspiciousApps = apps.where((a) => !a['isSystem']).toList();
      int highRiskApps = suspiciousApps.length;
      int appScore = 100 - (highRiskApps * 2); // Dynamic scoring based on user app count
      if (appScore < 0) appScore = 0;
      
      for (var app in suspiciousApps.take(5)) { // Show top 5 for brevity
        _detailedThreats.add({
          'title': 'Third-Party App: ${app['name']}',
          'detail': 'Package: ${app['package']}. Monitor permissions for this app.',
          'severity': 'Low',
        });
      }

      // 3. Real Network Info
      _addLog('Analyzing network interfaces...');
      String? wifiName = await _networkInfo.getWifiName();
      int networkScore = 100;
      if (wifiName == null) {
        _addLog('Network: Mobile Data or No Connection');
      } else {
        _addLog('Network: Connected to $wifiName');
        // Simple logic: public/open networks are lower score (simulated check)
        if (wifiName.toLowerCase().contains('free') || wifiName.toLowerCase().contains('public')) {
          networkScore -= 30;
          _detailedThreats.add({
            'title': 'Public Wi-Fi Detected',
            'detail': 'You are connected to an open or public network. Data may be unencrypted.',
            'severity': 'Warning',
          });
        }
      }

      // 4. Data Privacy Score (based on number of risks)
      int privacyScore = (100 - (_detailedThreats.length * 5)).clamp(50, 100);
      
      _addLog('Finalizing report...');

       setState(() {
         _appCount = apps.length;
         _scores = {
           'Device Integrity': deviceScore,
           'App Safety': appScore,
           'Network Security': networkScore,
           'Data Privacy': privacyScore,
         };
         _overallScore = _scores.values.reduce((a, b) => a + b) ~/ _scores.length;
         _isLoading = false;
         _logs.add('Scan complete');
       });
    } catch (e) {
      _addLog('Error during scan: $e');
      setState(() => _isLoading = false);
    }
  }

  void _addLog(String msg) {
    setState(() {
      _logs.add(msg);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Scanning...')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _logs.map((log) => Text(
                    log,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontFamily: 'monospace'),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Security Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlowContainer(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Integrity Summary',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${DateTime.now().toString().substring(0, 16)}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                      SecurityStatusBox(score: _overallScore, size: 70),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('$_appCount', 'Apps', AppTheme.primary),
                      _buildMiniStat('${_detailedThreats.where((t) => t['severity'] == 'Low').length}', 'Risks', AppTheme.primary),
                      _buildMiniStat('${_detailedThreats.where((t) => t['severity'] == 'Warning').length}', 'Warnings', AppTheme.warning),
                      _buildMiniStat('${_detailedThreats.where((t) => t['severity'] == 'Critical').length}', 'Critical', AppTheme.danger),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SectionHeader(title: 'Analysis Results'),
            ..._scores.entries.map((entry) {
              final color = entry.value >= 80 ? AppTheme.success : (entry.value >= 60 ? AppTheme.warning : AppTheme.danger);
              final int blocks = (entry.value / 10).round();
              final String blockString = '█' * blocks + '░' * (10 - blocks);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text(blockString, style: TextStyle(color: color, fontSize: 10, letterSpacing: 1)),
                        const SizedBox(width: 8),
                        Text('${entry.value}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Detailed Logs'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.textSecondary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _logs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontFamily: 'monospace'),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Detected Issues'),
            if (_detailedThreats.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No major security issues detected', style: TextStyle(color: AppTheme.success, fontSize: 12))),
              )
            else
              ..._detailedThreats.map((threat) {
                final color = threat['severity'] == 'Critical' ? AppTheme.danger : (threat['severity'] == 'Warning' ? AppTheme.warning : AppTheme.primary);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(left: BorderSide(color: color, width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(threat['title'], style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color)),
                            child: Text(threat['severity'].toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(threat['detail'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Recommended Steps'),
            GlowContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRec('01', 'Use a VPN', 'Secure your internet connection from eavesdropping on public networks.'),
                  const Divider(),
                  _deviceAudit?.containsKey('isDevMode') == true && _deviceAudit!['isDevMode']
                    ? _buildRec('02', 'Disable Developer Mode', 'Go to Settings > System > Developer Options and turn it off.')
                    : _buildRec('02', 'Keep OS Updated', 'Ensure you have the latest security patches from your manufacturer.'),
                  const Divider(),
                  _buildRec('03', 'Review App Permissions', 'Check which apps have access to your location, camera, and microphone.'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ScanButton(
              label: 'Copy Report to Clipboard', 
              onPressed: () {
                final buffer = StringBuffer();
                buffer.writeln('SafeScan Security Report');
                buffer.writeln('Date: ${DateTime.now()}');
                buffer.writeln('Overall Score: $_overallScore%');
                buffer.writeln('\n--- DETECTED ISSUES ---');
                for (var t in _detailedThreats) {
                  buffer.writeln('[${t['severity']}] ${t['title']}: ${t['detail']}');
                }
                Clipboard.setData(ClipboardData(text: buffer.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report copied to clipboard')),
                );
              }, 
              icon: Icons.copy,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9)),
      ],
    );
  }

  Widget _buildRec(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('[$number]', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
