import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/helpers/shared_prefs.dart';
import 'package:malaz_app/screens/home_screen.dart';
import 'package:malaz_app/screens/login_screen.dart';
import 'package:malaz_app/screens/onboarding_screen_2.dart';
import 'package:malaz_app/widgets/onboarding_progress_button.dart';
import '../constants/app_strings.dart';
import '../constants/app_images.dart';

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1>
    with TickerProviderStateMixin {
  static const Color _backgroundTop = Color(0xFFFFFFFF);
  static const Color _backgroundBottom = Color(0xFFF6F8FC);
  static const Color _skipColor = Color(0xFF6A6898);
  static const Color _titleColor = Color(0xFF355C80);
  static const Color _descriptionColor = Color(0xFF2474BA);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _arrowController;
  late Animation<Offset> _arrowSlideAnimation;

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

    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _arrowSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.15, 0),
    ).animate(
      CurvedAnimation(
        parent: _arrowController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfLoggedIn();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _redirectIfLoggedIn() {
    if (!mounted || !SharedPrefs.isLoggedIn) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    final scale = widthScale < heightScale ? widthScale : heightScale;
    final isCompact = screenSize.height < 780;
    double scaled(double value) => value * scale;

    final imageHeight = scaled(isCompact ? 238.0 : 270.0);
    final titleFontSize = scaled(isCompact ? 27.0 : 29.0);
    final descriptionFontSize = scaled(isCompact ? 15.5 : 17.0);
    final skipFontSize = scaled(isCompact ? 20.0 : 22.0);
    final buttonSize = scaled(56.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _backgroundTop,
              _backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              scaled(24),
              scaled(8),
              scaled(24),
              scaled(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        AppStrings.skip,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: skipFontSize,
                          fontWeight: FontWeight.w600,
                          color: _skipColor,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Transform.translate(
                            offset: Offset(0, scaled(isCompact ? 0 : -8)),
                            child: SizedBox(
                              width: double.infinity,
                              height: imageHeight,
                              child: Image.asset(
                                AppImages.onboarding1,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: scaled(isCompact ? 36 : 50)),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: scaled(330)),
                              child: Text(
                                AppStrings.onboarding1Title,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: _titleColor,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: scaled(isCompact ? 16 : 20)),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: scaled(335)),
                              child: Text(
                                AppStrings.onboarding1Desc,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: descriptionFontSize,
                                  color: _descriptionColor,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen2(),
                        ),
                      );
                    },
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _arrowSlideAnimation,
                        child: OnboardingBackButton(
                          size: buttonSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
