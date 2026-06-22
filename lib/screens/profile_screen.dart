import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/device_service.dart';
import '../services/app_service.dart';
import 'report_screen.dart';
import 'login_screen.dart';
import 'scan_history_screen.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _autoScanEnabled = false;
  bool _biometricEnabled = true;
  
  String _model = '...';
  int _appCount = 0;
  int _threats = 0;
  int _overallScore = 0;
  bool _isLoading = true;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      _userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

      final deviceAudit = await DeviceService.getFullDeviceAudit();
      final apps = await AppService.getInstalledAppsAudit();
      
      int userAppsCount = apps.where((a) => !a['isSystem']).length;
      int deviceScore = 100;
      if (deviceAudit['isRooted']) deviceScore -= 40;
      if (deviceAudit['isDevMode']) deviceScore -= 20;

      int appScore = (100 - (userAppsCount * 2)).clamp(0, 100);

      setState(() {
        _model = deviceAudit['model'];
        _appCount = apps.length;
        _threats = userAppsCount;
        _overallScore = (deviceScore + appScore) ~/ 2;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.primary, width: 0.5)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    child: const Icon(Icons.person, color: AppTheme.primary, size: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Device: $_model',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: AppTheme.success)),
                    child: const Text('Account Secured', style: TextStyle(color: AppTheme.success, fontSize: 10)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _statCard('$_appCount', 'Apps', AppTheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard('$_threats', 'Threats', AppTheme.danger)),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard('$_overallScore%', 'Safety', AppTheme.success)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Settings'),
                  GlowContainer(
                    child: Column(
                      children: [
                        _switchTile('Push Notifications', 'Real-time security alerts', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
                        const Divider(),
                        _switchTile('Auto-scan on Start', 'Scan device when app opens', _autoScanEnabled, (v) => setState(() => _autoScanEnabled = v)),
                        const Divider(),
                        _switchTile('Biometric Vault', 'Use fingerprint/face ID', _biometricEnabled, (v) => setState(() => _biometricEnabled = v)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Data Management'),
                  GlowContainer(
                    child: Column(
                      children: [
                        _menuTile('View Scan History', () {
                          Navigator.of(context).push(
                             MaterialPageRoute(builder: (_) => const ScanHistoryScreen()),
                           );
                        }),
                        const Divider(),
                        _menuTile('Purge Scan History', () {
                           showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              title: const Text('Purge History', style: TextStyle(color: AppTheme.danger)),
                              content: const Text('Are you sure you want to delete all security logs from Firestore?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                OutlinedButton(onPressed: () async {
                                  Navigator.pop(context);
                                  await DatabaseService().purgeHistory();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan history purged')));
                                  }
                                }, child: const Text('Delete', style: TextStyle(color: AppTheme.danger))),
                              ],
                            ),
                          );
                        }),
                        const Divider(),
                        _menuTile('System Diagnostics', () {
                           Navigator.of(context).push(
                             MaterialPageRoute(builder: (_) => const ReportScreen()),
                           );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.danger),
                        shape: const BeveledRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Logout', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
            const Icon(Icons.chevron_right, color: AppTheme.primary, size: 16),
          ],
        ),
      ),
    );
  }
}
