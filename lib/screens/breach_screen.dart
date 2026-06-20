import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/breach_service.dart';

class BreachScreen extends StatefulWidget {
  const BreachScreen({super.key});

  @override
  State<BreachScreen> createState() => _BreachScreenState();
}

class _BreachScreenState extends State<BreachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isChecking = false;
  Map<String, dynamic>? _result;
  String _error = '';
  int _searchType = 0; // 0 for Email, 1 for Password

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isChecking = true;
        _result = null;
        _error = '';
      });
      try {
        final emailResult = await BreachService.checkEmailBreach(_controller.text);
        final passwordResult = await BreachService.checkPasswordBreach(_controller.text);
        
        setState(() {
          _result = _searchType == 0 ? emailResult : passwordResult;
          _isChecking = false;
        });
      } catch (e) {
        setState(() {
          _isChecking = false;
          _error = 'Search failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final breached = _result != null && _result!['breached'] == true;
    final color = breached ? AppTheme.danger : AppTheme.success;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Data Leak Check')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: AppTheme.primary)),
              child: Row(
                children: [
                  _toggleButton('Email', 0),
                  _toggleButton('Password', 1),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const GlowContainer(
              child: Text(
                'Your data remains private during the search', 
                style: TextStyle(color: AppTheme.accent, fontSize: 11)
              )
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _controller,
                    style: const TextStyle(color: AppTheme.primary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _searchType == 0 ? 'user@example.com' : 'Your password',
                      prefixIcon: Icon(_searchType == 0 ? Icons.email : Icons.vpn_key, size: 18),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ScanButton(
                    label: _isChecking ? 'Searching...' : 'Start Search',
                    icon: Icons.search,
                    isLoading: _isChecking,
                    onPressed: _runSearch,
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
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(border: Border.all(color: color)),
                child: Column(
                  children: [
                    Text(
                      breached ? 'Critical Exposure Detected!' : 'No Leaks Found', 
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    if (breached) ...[
                      const SizedBox(height: 12),
                      Text('${_result!['count']}', style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
                      Text('Leaks found [${_result!['type']}]', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
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

  Widget _toggleButton(String label, int type) {
    bool active = _searchType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() { _searchType = type; _result = null; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: active ? AppTheme.primary : Colors.transparent,
          child: Center(
            child: Text(
              label, 
              style: TextStyle(
                color: active ? AppTheme.background : AppTheme.primary, 
                fontWeight: FontWeight.bold, 
                fontSize: 11
              )
            ),
          ),
        ),
      ),
    );
  }
}
