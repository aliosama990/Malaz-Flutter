import 'package:flutter/material.dart';
import 'package:malaz_app/constants/app_colors.dart';
import 'package:malaz_app/constants/app_images.dart';
import 'package:malaz_app/helpers/shared_prefs.dart';
import 'package:malaz_app/providers/auth_provider.dart';
import 'package:malaz_app/services/api_service.dart';
import 'package:malaz_app/screens/login_screen.dart';
import 'package:malaz_app/screens/home_screen.dart';
import 'package:malaz_app/screens/onboarding_screen_1.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumSplashDuration = Duration(seconds: 3);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _statusMessage;
  bool _canRetry = false;
  bool _isCheckingSession = false;

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
    if (_isCheckingSession) {
      return;
    }

    setState(() {
      _isCheckingSession = true;
      _statusMessage = null;
      _canRetry = false;
    });

    final splashDelay = Future<void>.delayed(_minimumSplashDuration);

    try {
      final hasRegistered = SharedPrefs.hasRegistered;
      final isLoggedIn = SharedPrefs.isLoggedIn;

      Widget nextScreen;

      if (!hasRegistered) {
        nextScreen = const OnboardingScreen1();
      } else if (!isLoggedIn) {
        nextScreen = const LoginScreen();
      } else {
        if (!mounted) {
          return;
        }

        final authProvider = context.read<AuthProvider>();
        final isTokenValid = await authProvider.validateStoredToken();

        if (!isTokenValid) {
          nextScreen = const LoginScreen();
        } else {
          nextScreen = const HomeScreen();
        }
      }

      await splashDelay;

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } on ApiException catch (error) {
      await splashDelay;

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = error.errorMessages.isNotEmpty
            ? error.errorMessages.join('\n')
            : error.message;
        _canRetry = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
      }
    }
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
                if (_statusMessage == null)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.splashLoader,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.registerTitle,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_canRetry)
                          ElevatedButton(
                            onPressed:
                                _isCheckingSession ? null : _checkAndNavigate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.registerTitle,
                            ),
                            child: const Text('إعادة المحاولة'),
                          ),
                      ],
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
