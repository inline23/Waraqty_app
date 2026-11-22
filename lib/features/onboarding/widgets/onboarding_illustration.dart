import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/onboarding_page_data.dart';

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.visual});

  final OnboardingVisual visual;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 268,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 228,
            height: 228,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lavender,
            ),
          ),
          switch (visual) {
            OnboardingVisual.exams => const _ExamVisual(),
            OnboardingVisual.questionBank => const _BankVisual(),
            OnboardingVisual.printReady => const _PrintVisual(),
          },
        ],
      ),
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({
    required this.width,
    required this.height,
    this.child,
  });

  final double width;
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({this.count = 4, this.color = const Color(0xFFE6DEF3)});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          Container(
            height: 7,
            margin: EdgeInsets.only(left: i.isEven ? 0 : 28),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          if (i != count - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, this.color = AppColors.primary});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

class _ExamVisual extends StatelessWidget {
  const _ExamVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.14,
          child: const _Paper(width: 148, height: 186),
        ),
        Transform.rotate(
          angle: 0.05,
          child: const _Paper(
            width: 156,
            height: 196,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Lines(count: 1, color: AppColors.primarySoft),
                SizedBox(height: 14),
                _Lines(count: 4),
              ],
            ),
          ),
        ),
        const Positioned(
          bottom: 18,
          left: 78,
          child: _Badge(icon: Icons.edit_rounded),
        ),
      ],
    );
  }
}

class _BankVisual extends StatelessWidget {
  const _BankVisual();

  @override
  Widget build(BuildContext context) {
    return const _Paper(
      width: 214,
      height: 196,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بنك الأسئلة',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          _BankRow(icon: Icons.checklist_rounded, color: Color(0xFF7047C6)),
          SizedBox(height: 8),
          _BankRow(icon: Icons.draw_outlined, color: Color(0xFF168A77)),
          SizedBox(height: 8),
          _BankRow(icon: Icons.short_text_rounded, color: Color(0xFFE69A30)),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintVisual extends StatelessWidget {
  const _PrintVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const _Paper(
          width: 156,
          height: 204,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Lines(count: 1, color: AppColors.primary),
              SizedBox(height: 12),
              _Lines(count: 5),
            ],
          ),
        ),
        Positioned(
          top: 36,
          right: 62,
          child: Transform.rotate(
            angle: math.pi / 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE69A30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'A4',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 16,
          left: 74,
          child: _Badge(
            icon: Icons.picture_as_pdf_rounded,
            color: Color(0xFF431599),
          ),
        ),
      ],
    );
  }
}
