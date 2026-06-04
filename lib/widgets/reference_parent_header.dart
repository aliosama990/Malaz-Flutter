import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'initial_avatar.dart';

class ReferenceParentHeader extends StatelessWidget {
  const ReferenceParentHeader({
    super.key,
    required this.userName,
    required this.subtitle,
    this.parentGender,
    this.showBell = false,
    this.bellBadgeCount = 0,
    this.onBellTap,
    this.showBackButton = false,
    this.onBackTap,
  });

  final String userName;
  final String subtitle;
  final String? parentGender;
  final bool showBell;
  final int bellBadgeCount;
  final VoidCallback? onBellTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final normalizedGender = parentGender?.trim().toLowerCase();
    final greetingRole =
        normalizedGender == 'female' || normalizedGender == 'أنثى'
            ? 'أستاذة'
            : 'أستاذ';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        height: topPadding + scaled(141),
        decoration: BoxDecoration(
          color: const Color(0xFF7568BE),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(scaled(36)),
            bottomRight: Radius.circular(scaled(36)),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x332B235E),
              blurRadius: scaled(18),
              offset: Offset(0, scaled(9)),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: scaled(-72),
              top: topPadding - scaled(88),
              child: _HeaderCircle(size: scaled(188), opacity: 0.08),
            ),
            Positioned(
              left: scaled(16),
              top: topPadding + scaled(60),
              child: _HeaderCircle(size: scaled(86), opacity: 0.07),
            ),
            Positioned(
              right: scaled(-26),
              top: topPadding - scaled(82),
              child: _HeaderCircle(size: scaled(178), opacity: 0.08),
            ),
            Positioned(
              right: scaled(28),
              top: topPadding + scaled(45),
              child: InitialAvatar(
                label: userName,
                radius: scaled(31),
                backgroundColor: const Color(0xFF9FD7FF),
                foregroundColor: const Color(0xFF224D67),
                role: AvatarRole.parent,
                parentGender: parentGender,
              ),
            ),
            if (showBackButton)
              Positioned(
                right: scaled(18),
                top: topPadding + scaled(8),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    width: scaled(36),
                    height: scaled(36),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: scaled(24),
                      color: const Color(0xFF224D67),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: scaled(108),
              left: scaled(28),
              top: topPadding + scaled(62),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'أهلاً $greetingRole $userName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(26),
                        height: 1.06,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: scaled(10)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(13.5),
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showBell)
              Positioned(
                left: scaled(23),
                top: topPadding + scaled(8),
                child: GestureDetector(
                  onTap: onBellTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: scaled(52),
                        height: scaled(52),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: scaled(31),
                          color: const Color(0xFF1B2B68),
                        ),
                      ),
                      if (bellBadgeCount > 0)
                        Positioned(
                          top: scaled(-5),
                          right: scaled(1),
                          child: Container(
                            width: scaled(18),
                            height: scaled(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE93434),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF7568BE),
                                width: scaled(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCircle extends StatelessWidget {
  const _HeaderCircle({
    required this.size,
    required this.opacity,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
