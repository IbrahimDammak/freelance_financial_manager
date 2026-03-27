import 'package:flutter/material.dart';

import '../theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    this.borderColor,
    this.backgroundTint,
    this.subtitle,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color? borderColor;
  final Color? backgroundTint;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final background = backgroundTint ?? kBgCard;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: kCardDecoration(
          borderColor: borderColor, background: background, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: kStyleLabel),
          const SizedBox(height: 8),
          Text(
            value,
            style: kStyleHeadingSm.copyWith(
              color: valueColor,
              fontFamily: kStyleBody.fontFamily,
              fontSize: 20,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: kStyleCaption),
          ],
        ],
      ),
    );
  }
}
