import 'package:flutter/material.dart';
import 'dart:async';

// TODO: Update this import to match the actual location of your chat screen
// import 'main_chat_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // الانتظار لمدة 3 ثوانٍ
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // استبدل PlaceholderScreen بشاشة الدردشة الأساسية الخاصة بك
          builder: (context) => const PlaceholderScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 150.0,
          height: 150.0,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// شاشة مؤقتة لتجنب الأخطاء البرمجية، قم بحذفها عند ربط شاشة الدردشة الحقيقية
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Main Chat Screen')));
}
