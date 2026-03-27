import 'package:flutter/material.dart';

import '../theme.dart';

class CustomProgressBar extends StatelessWidget {
  const CustomProgressBar({super.key, required this.value, this.height = 6});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    final progressColor = safeValue > 0.9
        ? kRed
        : safeValue > 0.7
            ? kYellow
            : kLime;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: kBgCardAlt,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: safeValue),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (context, val, _) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: val,
              child: Container(color: progressColor),
            );
          },
        ),
      ),
    );
  }
}
