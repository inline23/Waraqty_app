import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated Waraqty splash screen.
///
/// Usage:
/// MaterialApp(
///   home: SplashScreen(nextScreen: const HomeScreen()),
/// )
///
/// Put your transparent logo at: assets/images/waraqty_logo.png
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(milliseconds: 2600),
  });

  final Widget nextScreen;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _entryController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _navigationTimer;

  static const Color _purple = Color(0xFF8B3DFF);
  static const Color _blue = Color(0xFF20C8FF);

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    _entryController.forward();

    _navigationTimer = Timer(widget.duration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _glowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowController, _entryController]),
          builder: (context, _) {
            final pulse = 0.78 + (_glowController.value * 0.22);
            final glowRadius = 105.0 + (_glowController.value * 35.0);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Soft blue / purple ambient light behind the logo.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.12),
                        radius: 0.82,
                        colors: [
                          _purple.withValues(alpha: 0.13 * pulse),
                          _blue.withValues(alpha: 0.055 * pulse),
                          Colors.black,
                        ],
                        stops: const [0, 0.42, 1],
                      ),
                    ),
                  ),
                ),
                // Animated halo.
                Transform.scale(
                  scale: 0.94 + (_glowController.value * 0.12),
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.20 * pulse),
                          blurRadius: glowRadius,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: _purple.withValues(alpha: 0.25 * pulse),
                          blurRadius: glowRadius * 1.25,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/waraqty_logo.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.auto_awesome,
                            size: 120,
                            color: _purple,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'ورقتي',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: _purple,
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (_, __) {
                            return Container(
                              width: 58,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _purple,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _purple.withValues(alpha: 0.65),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
