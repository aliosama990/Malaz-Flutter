import 'package:flutter/material.dart';

import '../constants/app_images.dart';

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
    this.parentGender,
    this.childGender,
    this.fallbackIcon,
  });

  final String label;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final AvatarRole role;
  final String? parentGender;
  final int? childGender;
  final IconData? fallbackIcon;

  String get _assetPath {
    if (role == AvatarRole.parent) {
      final normalizedGender = parentGender?.trim().toLowerCase();
      if (normalizedGender == 'male' || normalizedGender == 'ذكر') {
        return AppImages.parentMaleAvatar;
      }

      return AppImages.parentFemaleAvatar;
    }

    if (childGender == 1) {
      return AppImages.childGirlAvatar;
    }

    return AppImages.childBoyAvatar;
  }

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
    final diameter = radius * 2;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: ClipOval(
        child: Image.asset(
          _assetPath,
          width: diameter,
          height: diameter,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return ColoredBox(
              color: backgroundColor,
              child: Center(
                child: Icon(
                  _iconData,
                  color: foregroundColor,
                  size: radius * 1.15,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
