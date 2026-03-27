import 'package:flutter/material.dart';

import '../theme.dart';

class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key, required this.elapsedSeconds, this.style});

  final int elapsedSeconds;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final hours = (elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _part(hours),
        Text(':', style: style ?? kStyleTimer),
        _part(minutes),
        Text(':', style: style ?? kStyleTimer),
        _part(seconds),
      ],
    );
  }

  Widget _part(String text) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Text(
        text,
        key: ValueKey(text),
        style: style ?? kStyleTimer,
      ),
    );
  }
}
