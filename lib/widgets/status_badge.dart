import 'package:flutter/material.dart';

import '../theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => kGreen,
      'completed' => kBlue,
      'paused' => kYellow,
      'cancelled' => kRed,
      _ => kTextMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            kStyleCaption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
