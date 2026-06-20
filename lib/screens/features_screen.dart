import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'wifi_screen.dart';
import 'ssl_screen.dart';
import 'breach_screen.dart';
import 'permissions_screen.dart';
import 'device_screen.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'WIFI_DIAGNOSTICS',
        'description': 'ANALYZE_NETWORK_SECURITY_PROTOCOLS_AND_ENCRYPTION_TYPES.',
        'icon': Icons.wifi,
        'color': AppTheme.primary,
        'tag': 'NET',
        'screen': const WiFiScreen(),
      },
      {
        'title': 'SSL_VALIDATION',
        'description': 'VERIFY_X.509_CERTIFICATES_AND_ENCRYPTION_STRENGTH.',
        'icon': Icons.https,
        'color': AppTheme.accent,
        'tag': 'WEB',
        'screen': const SSLScreen(),
      },
      {
        'title': 'BREACH_DETECTION',
        'description': 'QUERY_EXTERNAL_DATABASES_FOR_CREDENTIAL_EXPOSURE.',
        'icon': Icons.vpn_key,
        'color': AppTheme.warning,
        'tag': 'DB',
        'screen': const BreachScreen(),
      },
      {
        'title': 'APP_AUDITOR',
        'description': 'SCAN_LOCAL_APPLICATIONS_FOR_SUSPICIOUS_PERMISSIONS.',
        'icon': Icons.apps_outlined,
        'color': Colors.purpleAccent,
        'tag': 'APP',
        'screen': const PermissionsScreen(),
      },
      {
        'title': 'DEVICE_INTEGRITY',
        'description': 'VERIFY_ROOT_ACCESS_OS_LEVELS_AND_HARDWARE_LOCKS.',
        'icon': Icons.phone_android,
        'color': AppTheme.success,
        'tag': 'HW',
        'screen': const DeviceScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('SYSTEM_MODULES'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.primary, width: 0.5)),
            ),
            child: Row(
              children: [
                _filterChip('ALL_MODULES', true),
                const SizedBox(width: 8),
                _filterChip('THREATS', false),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppTheme.primary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'SEARCH_REGISTRY...',
                prefixIcon: Icon(Icons.search, size: 18),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Features list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                final color = feature['color'] as Color;
                final icon = feature['icon'] as IconData;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature['title'] as String,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(border: Border.all(color: color)),
                              child: Text(
                                feature['tag'] as String,
                                style: TextStyle(color: color, fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          feature['description'] as String,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => feature['screen'] as Widget),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: color.withOpacity(0.3))),
                            color: color.withOpacity(0.05),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'INITIALIZE_SCAN',
                                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.terminal, color: color, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : Colors.transparent,
        border: Border.all(color: AppTheme.primary),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppTheme.background : AppTheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
