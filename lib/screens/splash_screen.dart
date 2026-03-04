import 'package:flutter/material.dart';
import 'package:malaz_app/constants/app_colors.dart';
import 'package:malaz_app/constants/app_images.dart';
import 'package:malaz_app/helpers/shared_prefs.dart';
import 'package:malaz_app/screens/login_screen.dart';
import 'package:malaz_app/screens/home_screen.dart';
import 'package:malaz_app/screens/onboarding_screen_1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
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

    _controller.forward();

    _checkAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigate() async {
    await SharedPrefs.init();
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    bool hasRegistered = SharedPrefs.hasRegistered;
    bool isLoggedIn = SharedPrefs.isLoggedIn;

    Widget nextScreen;

    if (!hasRegistered) {
      nextScreen = const OnboardingScreen1();
    } else if (isLoggedIn) {
      nextScreen = const HomeScreen();
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppImages.logo,
                  width: 350,
                  height: 350,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.splashLoader),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
