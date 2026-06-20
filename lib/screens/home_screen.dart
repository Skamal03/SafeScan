import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/device_service.dart';
import '../services/app_service.dart';
import 'features_screen.dart';
import 'wifi_screen.dart';
import 'ssl_screen.dart';
import 'breach_screen.dart';
import 'permissions_screen.dart';
import 'device_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'chatbot_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeTab(),
    const FeaturesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        child: const Icon(Icons.smart_toy_outlined),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.terminal),
            activeIcon: Icon(Icons.terminal),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            activeIcon: Icon(Icons.grid_view),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree),
            activeIcon: Icon(Icons.account_tree),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _isLoading = true;
  int _overallScore = 0;
  int _appCount = 0;
  int _threats = 0;
  String _model = '...';
  Map<String, int> _scores = {};

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    setState(() => _isLoading = true);
    try {
      final deviceAudit = await DeviceService.getFullDeviceAudit();
      final apps = await AppService.getInstalledAppsAudit();
      final networkInfo = NetworkInfo();
      String? wifiName = await networkInfo.getWifiName();
      
      int deviceScore = 100;
      if (deviceAudit['isRooted']) deviceScore -= 40;
      if (deviceAudit['isDevMode']) deviceScore -= 20;

      int userAppsCount = apps.where((a) => !a['isSystem']).length;
      int appScore = (100 - (userAppsCount * 2)).clamp(0, 100);

      int networkScore = 100;
      if (wifiName != null && (wifiName.toLowerCase().contains('free') || wifiName.toLowerCase().contains('public'))) {
        networkScore = 70;
      }

      setState(() {
        _model = deviceAudit['model'];
        _appCount = apps.length;
        _threats = userAppsCount;
        _scores = {
          'DEVICE': deviceScore,
          'APPS': appScore,
          'NETWORK': networkScore,
        };
        _overallScore = _scores.values.reduce((a, b) => a + b) ~/ _scores.length;
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
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('SafeScan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadRealData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device: $_model',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                    ),
                    const Text(
                      'Status: Protected',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security Status',
                        style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Overall Integrity: ${_overallScore > 80 ? "Safe" : "At Risk"}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReportScreen()),
                        ),
                        child: const Text('View Full Report', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
                SecurityStatusBox(score: _overallScore),
              ],
            ),

            const SizedBox(height: 24),

            const SectionHeader(title: 'Security Levels'),
            GlowContainer(
              child: Column(
                children: _scores.entries.map((entry) {
                  final color = entry.value >= 80 ? AppTheme.success : (entry.value >= 60 ? AppTheme.warning : AppTheme.danger);
                  final int blocks = (entry.value / 10).round();
                  final String blockString = '█' * blocks + '░' * (10 - blocks);
                  
                  // Simplify entry keys
                  String label = entry.key;
                  if (label == 'DEVICE') label = 'Device';
                  if (label == 'APPS') label = 'Apps';
                  if (label == 'NETWORK') label = 'Network';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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
              ),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Security Tools'),
            FeatureCard(
              title: 'Wi-Fi Security',
              subtitle: 'Scan your network for threats',
              icon: Icons.wifi,
              iconColor: AppTheme.primary,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WiFiScreen())),
            ),
            FeatureCard(
              title: 'Website Safety',
              subtitle: 'Check if a website is secure',
              icon: Icons.https,
              iconColor: AppTheme.accent,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SSLScreen())),
            ),
            FeatureCard(
              title: 'Data Leaks',
              subtitle: 'Check if your data was leaked',
              icon: Icons.vpn_key,
              iconColor: AppTheme.warning,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BreachScreen())),
            ),
            FeatureCard(
              title: 'App Permissions',
              subtitle: 'Monitor what apps can access',
              icon: Icons.apps,
              iconColor: Colors.purpleAccent,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermissionsScreen())),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Stats'),
            Row(
              children: [
                Expanded(child: _buildStatCard('Apps', '$_appCount', Icons.apps, AppTheme.primary)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Risks', '$_threats', Icons.bug_report, AppTheme.danger)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('System', 'OK', Icons.shield, AppTheme.success)),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppTheme.primary, width: 1))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(border: Border.all(color: AppTheme.primary)),
                      child: const Icon(Icons.person, color: AppTheme.primary, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const Text('Secure Identity', style: TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
                  ],
                ),
              ),
              const Divider(),
              _drawerItem(context, Icons.terminal, 'Overview', () {
                Navigator.pop(context);
                // Already on Home
              }),
              _drawerItem(context, Icons.radar, 'Run Full Scan', () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportScreen()));
              }),
              _drawerItem(context, Icons.history, 'Scan History', () {
                Navigator.pop(context);
                // History is managed in Data Management within Profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History can be viewed in Profile > Data Management')),
                );
              }),
              _drawerItem(context, Icons.settings, 'Settings', () {
                Navigator.pop(context);
                // Settings are in Profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings are available in the Account tab')),
                );
              }),
              const Spacer(),
              const Divider(),
              _drawerItem(context, Icons.logout, 'Logout', () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
                  );
                }
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 18),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
