import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/app_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isScanning = false;
  List<Map<String, dynamic>> _apps = [];
  String _filter = 'ALL';

  void _scanApps() async {
    setState(() => _isScanning = true);
    try {
      final apps = await AppService.getInstalledAppsAudit();
      setState(() {
        _apps = apps;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'ALL' 
        ? _apps 
        : _apps.where((a) => _filter == 'SYSTEM' ? a['isSystem'] : !a['isSystem']).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('App Permissions Audit')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ScanButton(
              label: _isScanning ? 'Scanning Apps...' : 'Scan Installed Apps',
              icon: Icons.apps,
              isLoading: _isScanning,
              onPressed: _scanApps,
            ),
          ),
          if (_apps.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _chip('All'),
                  const SizedBox(width: 8),
                  _chip('User'),
                  const SizedBox(width: 8),
                  _chip('System'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  final isCrit = app['risk'] == 'medium';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(left: BorderSide(color: isCrit ? AppTheme.warning : AppTheme.success, width: 2)),
                    ),
                    child: ListTile(
                      onTap: () => _showAppDetails(app),
                      title: Text(app['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(app['package'], style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                      trailing: StatusBadge(status: app['risk'], label: app['risk']),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAppDetails(Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(app['name'], style: const TextStyle(color: AppTheme.primary, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Package', app['package']),
              _detailRow('Version', app['version']),
              _detailRow('Status', app['isSystem'] ? 'System App' : 'User Installed'),
              const Divider(height: 24),
              const Text('Security Analysis:', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Text(app['riskReason'], style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
              const SizedBox(height: 16),
              const Text('Access & Permissions:', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              ...(app['permissions'] as List<String>).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $p', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    bool active = _filter.toUpperCase() == label.toUpperCase();
    return InkWell(
      onTap: () => setState(() => _filter = label.toUpperCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          border: Border.all(color: AppTheme.primary),
        ),
        child: Text(label, style: TextStyle(color: active ? AppTheme.background : AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
