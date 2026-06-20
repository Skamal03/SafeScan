import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/safescan_service.dart';
import 'wifi_screen.dart';
import 'breach_screen.dart';
import 'device_screen.dart';
import 'ssl_screen.dart';
import 'report_screen.dart';
import 'permissions_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Hello! I am your AI Security Assistant. How can I help you protect your device today?',
      'time': '10:00 AM'
    },
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SafeScanService _service = SafeScanService();
  bool _isLoading = false;

  void _handleSend() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userQuery = _controller.text.trim();

    setState(() {
      _messages.add({'isUser': true, 'text': userQuery, 'time': 'Just now'});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    final result = await _service.queryIntent(userQuery);

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      _routeResult(result);
    } else {
      _fallbackHandler(userQuery);
    }

    _scrollToBottom();
  }

  void _routeResult(Map<String, dynamic> result) {
    final String intent = result['intent'] ?? '';
    final String action = result['action'] ?? '';
    final Map<String, dynamic> params = (result['parameters'] as Map<String, dynamic>?) ?? {};
    final String? responseText = result['response'];

    // ── Text-reply intents — just show the response field as a chat bubble ──
    if (action == 'show_text_response' || action == 'fallback' || action == 'open_drawer') {
      _addBotMessage(
        responseText ?? "I'm not sure how to help with that. Try asking about WiFi, SSL, breaches, or app permissions.",
      );
      return;
    }

    // ── Navigation intents — show message + navigate to screen ──
    switch (intent) {
      case 'wifi_check':
        _addBotMessage("Navigating to Wi-Fi Security Scan to check your network.");
        _navigateTo(const WiFiScreen());
        break;

      case 'ssl_check':
        final domain = params['domain'];
        final msg = domain != null
            ? "Checking SSL certificate for $domain."
            : "Opening SSL Certificate Checker.";
        _addBotMessage(msg);
        _navigateTo(const SSLScreen());
        break;

      case 'breach_lookup':
        final credential = params['credential'];
        final tab = params['tab'] ?? 'email';
        final msg = credential != null
            ? "Checking if $credential was exposed in a data breach."
            : "Opening Data Leak Checker.";
        _addBotMessage(msg);
        // Pass tab to BreachScreen if it supports it, otherwise just navigate
        _navigateTo(const BreachScreen());
        break;

      case 'device_check':
        _addBotMessage("Running a Device Health Check on your phone.");
        _navigateTo(const DeviceScreen());
        break;

      case 'permission_audit':
        _addBotMessage("Opening App Permissions Audit to review your installed apps.");
        _navigateTo(const PermissionsScreen());
        break;

      case 'report_action':
        _addBotMessage("Opening your Scan History. Tap the menu icon on the top left.");
        _navigateTo(const ReportScreen());
        break;

      default:
        _addBotMessage(
          responseText ?? "I'm not sure which tool to open for that. Try asking about WiFi, SSL, breaches, or app permissions.",
        );
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({'isUser': false, 'text': text, 'time': 'Just now'});
    });
  }

  void _navigateTo(Widget screen) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    });
  }

  void _fallbackHandler(String userQuery) {
    String response =
        "I'm having trouble reaching my AI backend right now. Try asking about Wi-Fi, data breaches, SSL certificates, or app permissions.";
    final query = userQuery.toLowerCase();

    if (query.contains('wifi') || query.contains('network')) {
      response = "Looks like a Wi-Fi question — try the Wi-Fi Security tool.";
    } else if (query.contains('breach') || query.contains('leak') || query.contains('password')) {
      response = "Check your credentials in the Data Leaks section.";
    } else if (query.contains('ssl') || query.contains('certificate') || query.contains('https')) {
      response = "Use the SSL Checker to verify a website's certificate.";
    } else if (query.contains('permission') || query.contains('app')) {
      response = "Review your app permissions in the Permissions Audit tool.";
    } else if (query.contains('device') || query.contains('phone') || query.contains('scan')) {
      response = "Run a full device health check from the Device screen.";
    }

    _addBotMessage(response);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary,
              radius: 14,
              child: Icon(Icons.smart_toy, size: 18, color: AppTheme.background),
            ),
            SizedBox(width: 12),
            Text('SAFESCAN_AI'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _LoadingBubble();
                }
                final msg = _messages[index];
                return _ChatBubble(
                  text: msg['text'],
                  isUser: msg['isUser'],
                  time: msg['time'],
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask about your security...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  fillColor: AppTheme.background,
                  filled: true,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: AppTheme.background, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String time;

  const _ChatBubble({required this.text, required this.isUser, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: Border.all(
            color: isUser ? AppTheme.primary.withOpacity(0.3) : AppTheme.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? AppTheme.primary : AppTheme.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ),
    );
  }
}
