import 'package:flutter/material.dart';

enum AvatarRole {
  parent,
  child,
}

class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.label,
    required this.radius,
    required this.backgroundColor,
    required this.foregroundColor,
    this.role = AvatarRole.parent,
    this.childGender,
    this.fallbackIcon,
  });

  final String label;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final AvatarRole role;
  final int? childGender;
  final IconData? fallbackIcon;

  IconData get _iconData {
    if (role == AvatarRole.parent) {
      return fallbackIcon ?? Icons.person_rounded;
    }

    if (childGender == 1) {
      return fallbackIcon ?? Icons.girl;
    }

    if (childGender == 0) {
      return fallbackIcon ?? Icons.boy;
    }

    return fallbackIcon ?? Icons.child_care;
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(
        _iconData,
        color: foregroundColor,
        size: radius * 1.15,
      ),
    );
  }
}
