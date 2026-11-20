import 'package:flutter/material.dart';

/// Shown for a moment at start-up, while the app looks for a saved login.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
