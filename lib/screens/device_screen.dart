import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/device_service.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _isScanning = false;
  Map<String, dynamic>? _auditData;

  void _runAudit() async {
    setState(() => _isScanning = true);
    try {
      final data = await DeviceService.getFullDeviceAudit();
      setState(() {
        _auditData = data;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate a real integrity score
    int score = 100;
    if (_auditData != null) {
      if (_auditData!['isRooted']) score -= 40;
      if (_auditData!['isDevMode']) score -= 20;
    }

    final color = score > 80 ? AppTheme.success : (score > 50 ? AppTheme.warning : AppTheme.danger);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Device Health Check')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const GlowContainer(
              child: Text(
                'Analyzing system security and hardware status',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ),
            const SizedBox(height: 20),
            ScanButton(
              label: _isScanning ? 'Checking device...' : 'Start Device Check',
              icon: Icons.developer_board,
              isLoading: _isScanning,
              onPressed: _runAudit,
            ),
            if (_auditData != null) ...[
              const SizedBox(height: 24),
              SecurityStatusBox(score: score, size: 80),
              const SizedBox(height: 24),
              const SectionHeader(title: 'System Details'),
              GlowContainer(
                glowColor: color,
                child: Column(
                  children: [
                    _auditTile('Model', _auditData!['model'], Icons.smartphone),
                    const Divider(),
                    _auditTile('OS Version', _auditData!['osVersion'], Icons.android),
                    const Divider(),
                    _auditTile('Security Patch', _auditData!['securityPatch'], Icons.update),
                    const Divider(),
                    _auditTile(
                      'Root Access', 
                      _auditData!['isRooted'] ? 'Detected' : 'Not Detected', 
                      Icons.gavel,
                      valColor: _auditData!['isRooted'] ? AppTheme.danger : AppTheme.success
                    ),
                    const Divider(),
                    _auditTile(
                      'Developer Mode', 
                      _auditData!['isDevMode'] ? 'Active' : 'Disabled', 
                      Icons.code,
                      valColor: _auditData!['isDevMode'] ? AppTheme.warning : AppTheme.success
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _auditTile(String label, String value, IconData icon, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
          Text(
            value,
            style: TextStyle(color: valColor ?? AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
