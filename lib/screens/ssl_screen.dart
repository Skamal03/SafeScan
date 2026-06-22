import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/ssl_service.dart';
import '../services/database_service.dart';

class SSLScreen extends StatefulWidget {
  const SSLScreen({super.key});

  @override
  State<SSLScreen> createState() => _SSLScreenState();
}

class _SSLScreenState extends State<SSLScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isChecking = false;
  Map<String, dynamic>? _result;
  String _error = '';

  void _checkSSL() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isChecking = true;
        _result = null;
        _error = '';
      });
      try {
        final result = await SslService.verifyCertificate(_urlController.text);
        
        final isSafe = result['isValid'] == true;

        // Save to History (Don't await, let it run in background)
        DatabaseService().saveReport(
          type: 'SSL Certificate Check',
          status: isSafe ? 'SAFE' : 'CRITICAL',
          summary: "SSL check for ${result['host']}: ${isSafe ? 'Secure' : 'Unsafe'}.",
          details: result,
        ).catchError((e) => print("Firestore Error: $e"));

        setState(() {
          _result = result;
          _isChecking = false;
        });
      } catch (e) {
        print("SSL Screen Error: $e");
        setState(() {
          _isChecking = false;
          _error = 'Unable to reach website. Check your internet or URL.';
          if (e.toString().contains('INVALID_HOST')) _error = 'Please enter a valid URL.';
          if (e.toString().contains('HOST_NOT_FOUND')) _error = 'Website not found. Check spelling.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _result != null && _result!['isValid'] == true;
    final color = isValid ? AppTheme.success : AppTheme.danger;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Website Security Check')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const GlowContainer(child: Text('Enter a website URL to check its security', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _urlController,
                    style: const TextStyle(color: AppTheme.primary, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'example.com'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ScanButton(
                    label: _isChecking ? 'Checking security...' : 'Check Security',
                    icon: Icons.vpn_lock,
                    isLoading: _isChecking,
                    onPressed: _checkSSL,
                  ),
                ],
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: color)),
                child: Column(
                  children: [
                    Text(isValid ? 'Status: Secure' : 'Status: Not Secure', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    InfoTile(label: 'Website', value: _result!['host'], icon: Icons.link),
                    const Divider(),
                    InfoTile(label: 'Security Provider', value: _result!['issuer'].split(',')[0].replaceAll('CN=', ''), icon: Icons.verified_user),
                    const Divider(),
                    InfoTile(label: 'Expires On', value: _result!['expiry'], icon: Icons.calendar_today, valueColor: color),
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
}
