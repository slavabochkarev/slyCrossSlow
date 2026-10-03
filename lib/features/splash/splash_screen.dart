import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/game_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;

  void _startTimer() {
    if (timer != null || widget.onFinished == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || timer != null) return;
      timer = Timer(const Duration(seconds: 2), () {
        if (mounted) widget.onFinished?.call();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GameColors.midnight,
    body: SizedBox.expand(
      child: Image.asset(
        'doc/load.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null) _startTimer();
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          _startTimer();
          return const Center(
            child: Text(
              'КроссСлов',
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.w900),
            ),
          );
        },
      ),
    ),
  );
}
