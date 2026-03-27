import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

enum DeadlineUrgency { normal, warning, urgent, overdue }

String fmtCurrency(double amount, String currency) {
  const symbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'NGN': '₦',
    'TND': 'DT',
    'CAD': 'CA\$',
  };

  if (currency == 'TND') {
    final formatted = NumberFormat('#,##0.###', 'en_US').format(amount);
    return '$formatted ${symbols['TND']}';
  }

  final symbol = symbols[currency] ?? currency;
  return NumberFormat.currency(symbol: symbol, decimalDigits: 0).format(amount);
}

String fmtDuration(int totalMins) {
  final h = totalMins ~/ 60;
  final m = totalMins % 60;
  if (totalMins == 0) return '0h';
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}

int daysLeft(String deadline) {
  final d = DateFormat('yyyy-MM-dd').parse(deadline);
  final today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  return d.difference(today).inDays;
}

int progressPct(double logged, double estimated) {
  if (estimated <= 0) return 0;
  return (logged / estimated * 100).round().clamp(0, 100);
}

String todayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String initialsFrom(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

DeadlineUrgency urgencyFor(String deadline) {
  final d = daysLeft(deadline);
  if (d < 0) return DeadlineUrgency.overdue;
  if (d < 5) return DeadlineUrgency.urgent;
  if (d < 10) return DeadlineUrgency.warning;
  return DeadlineUrgency.normal;
}

Color urgencyColor(DeadlineUrgency u) => switch (u) {
      DeadlineUrgency.overdue => kRed,
      DeadlineUrgency.urgent => kOrange,
      DeadlineUrgency.warning => kYellow,
      DeadlineUrgency.normal => kTextMuted,
    };

Color? urgencyStripColor(DeadlineUrgency u) => switch (u) {
      DeadlineUrgency.overdue => kRed,
      DeadlineUrgency.urgent => kOrange,
      _ => null,
    };

Color urgencyBorderColor(DeadlineUrgency u) => switch (u) {
      DeadlineUrgency.overdue => kRed.withOpacity(0.19),
      DeadlineUrgency.urgent => kOrange.withOpacity(0.15),
      _ => kBorder,
    };

Future<void> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  Color confirmColor = kRed,
  VoidCallback? onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: kBgCard,
        title: Text(
          title,
          style: kStyleHeadingSm.copyWith(fontSize: 18),
        ),
        content: Text(
          message,
          style: kStyleBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: kStyleBody.copyWith(color: kTextMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: kWhite,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
