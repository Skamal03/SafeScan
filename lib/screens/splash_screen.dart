import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _textAnimation;
  
  final List<String> _bootLog = [
    'Initializing Core System...',
    'Loading Security Modules...',
    'Scanning Local Storage...',
    'Establishing Secure Proxy...',
    'System Ready'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _textAnimation = IntTween(begin: 0, end: _bootLog.length - 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Check if user is already logged in
        final user = FirebaseAuth.instance.currentUser;
        
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => 
              user != null ? const HomeScreen() : LoginScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 2),
              ),
              child: const Icon(
                Icons.terminal,
                size: 80,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'SAFESCAN',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 60),
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    Text(
                      '> ${_bootLog[_textAnimation.value]}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        backgroundColor: AppTheme.surface,
                        color: AppTheme.primary,
                        minHeight: 2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
