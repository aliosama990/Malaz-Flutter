import 'package:flutter/material.dart';

class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton({
    super.key,
    this.size = 80,
  });

  final double size;
  static const Color _outerBorderColor = Color(0xFFB8BDC8);
  static const Color _centerFillColor = Color(0xFF6A6898);
  static const Color _centerBorderColor = Color(0xFFE8EAF2);

  @override
  Widget build(BuildContext context) {
    final innerSize = size * 0.67;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _outerBorderColor,
            width: size * 0.0375,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.075),
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _centerFillColor,
              border: Border.all(
                color: _centerBorderColor,
                width: size * 0.025,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: size * 0.31,
            ),
          ),
        ),
      ),
    );
  }
}
