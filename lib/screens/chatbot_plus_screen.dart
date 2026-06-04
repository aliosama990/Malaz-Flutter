import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_strings.dart';

class ChatbotPlusScreen extends StatefulWidget {
  const ChatbotPlusScreen({super.key});

  @override
  State<ChatbotPlusScreen> createState() => _ChatbotPlusScreenState();
}

class _ChatbotPlusScreenState extends State<ChatbotPlusScreen>
    with SingleTickerProviderStateMixin {
  static const Color _pageBackground = Color(0xFF686A9F);
  static const Color _buttonColor = Color(0xFF285A78);
  static const Color _titleTextColor = Color(0xFF285273);
  static const Color _borderColor = Color(0xFFD7D8EF);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // بدء الأنيميشن
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = _screenScale(context);
              double scaled(double value) => value * scale;
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Column(
                    children: [
                      SizedBox(height: height * 0.158),
                      Container(
                        width: width * 0.49,
                        height: scaled(58),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(scaled(30)),
                        ),
                        child: Text(
                          AppStrings.upgradeToPlusButton,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: _titleTextColor,
                            fontSize: scaled(20),
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.077),
                      Container(
                        width: width * 0.675,
                        height: height * 0.357,
                        padding: EdgeInsets.symmetric(
                          horizontal: scaled(20),
                          vertical: scaled(24),
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _borderColor,
                            width: scaled(2),
                          ),
                          borderRadius: BorderRadius.circular(scaled(38)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFeatureItem(AppStrings.feature1),
                            _buildFeatureItem(AppStrings.feature2),
                            _buildFeatureItem(AppStrings.feature3),
                            _buildFeatureItem(AppStrings.feature4),
                            _buildFeatureItem(AppStrings.feature5),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.073),
                      SizedBox(
                        width: width * 0.30,
                        height: scaled(52),
                        child: ElevatedButton(
                          onPressed: () {
                            debugPrint('Subscribe Now');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(scaled(20)),
                              side: BorderSide(
                                color: Colors.white,
                                width: scaled(1.6),
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppStrings.upgradeButton,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: scaled(22),
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: scaled(16),
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }
}
