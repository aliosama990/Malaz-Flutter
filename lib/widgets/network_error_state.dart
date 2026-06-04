import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/user_error_messages.dart';

class NetworkErrorState extends StatelessWidget {
  const NetworkErrorState({
    super.key,
    this.title = UserErrorMessages.offlineTitle,
    this.description = UserErrorMessages.offlineDescription,
    required this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
    this.inline = false,
  });

  const NetworkErrorState.inline({
    super.key,
    required this.title,
    this.description = UserErrorMessages.inlineRetryDescription,
    required this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  }) : inline = true;

  static const Color _primaryPurple = Color(0xFF6D6AA9);
  static const Color _titleColor = Color(0xFF234B70);
  static const Color _bodyColor = Color(0xFF756FB3);

  final String title;
  final String description;
  final VoidCallback onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    final content = Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: scaled(inline ? 14 : 22),
          vertical: scaled(inline ? 14 : 24),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scaled(inline ? 18 : 26)),
          border: Border.all(
            color: const Color(0xFFE7E2FF),
            width: scaled(1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A8A82D0),
              blurRadius: scaled(inline ? 14 : 24),
              offset: Offset(0, scaled(inline ? 6 : 12)),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: scaled(inline ? 42 : 58),
                  height: scaled(inline ? 42 : 58),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EEFF),
                    borderRadius: BorderRadius.circular(
                      scaled(inline ? 14 : 18),
                    ),
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    color: _primaryPurple,
                    size: scaled(inline ? 24 : 32),
                  ),
                ),
                SizedBox(width: scaled(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          fontSize: scaled(inline ? 14.5 : 18),
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                        ),
                      ),
                      SizedBox(height: scaled(5)),
                      Text(
                        description,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          fontSize: scaled(inline ? 12.5 : 14),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: _bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: scaled(inline ? 12 : 18)),
            Row(
              children: [
                Expanded(
                  child: _NetworkActionButton(
                    label: 'إعادة المحاولة',
                    onTap: onRetry,
                    filled: true,
                    scale: scale,
                  ),
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  SizedBox(width: scaled(10)),
                  Expanded(
                    child: _NetworkActionButton(
                      label: secondaryLabel!,
                      onTap: onSecondary!,
                      filled: false,
                      scale: scale,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    if (inline) {
      return content;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(scaled(22)),
        child: content,
      ),
    );
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static const Color _primaryPurple = Color(0xFF6D6AA9);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final scale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    double scaled(double value) => value * scale;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: scaled(12),
          vertical: scaled(8),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(scaled(16)),
          border: Border.all(color: const Color(0xFFE2DBFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: _primaryPurple,
              size: scaled(17),
            ),
            SizedBox(width: scaled(8)),
            Text(
              'أنت غير متصل بالإنترنت',
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: scaled(12.5),
                fontWeight: FontWeight.w700,
                color: _primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkActionButton extends StatelessWidget {
  const _NetworkActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.scale,
  });

  static const Color _primaryPurple = Color(0xFF6D6AA9);

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final double scale;

  @override
  Widget build(BuildContext context) {
    double scaled(double value) => value * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(scaled(18)),
        child: Ink(
          height: scaled(40),
          decoration: BoxDecoration(
            color: filled ? _primaryPurple : Colors.white,
            borderRadius: BorderRadius.circular(scaled(18)),
            border: Border.all(color: _primaryPurple),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: scaled(13),
                fontWeight: FontWeight.w800,
                color: filled ? Colors.white : _primaryPurple,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
