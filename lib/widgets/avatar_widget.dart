import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils.dart';

class ClientAvatar extends StatelessWidget {
  const ClientAvatar(
      {super.key, required this.name, this.size = 48, this.radius = 14});

  final String name;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = avatarColorFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      alignment: Alignment.center,
      child: Text(
        initialsFrom(name),
        style:
            kStyleBodyBold.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
