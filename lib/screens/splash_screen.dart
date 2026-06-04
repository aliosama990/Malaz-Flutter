import 'package:flutter/material.dart';
import 'package:malaz_app/constants/app_colors.dart';
import 'package:malaz_app/constants/app_images.dart';
import 'package:malaz_app/helpers/shared_prefs.dart';
import 'package:malaz_app/providers/auth_provider.dart';
import 'package:malaz_app/services/api_service.dart';
import 'package:malaz_app/utils/user_error_messages.dart';
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
  static const double _logoSize = 176;
  static const double _pillHeight = 32;
  static const double _pillHorizontalPadding = 18;
  static const double _pillFontSize = 12;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (SharedPrefs.isLoggedIn) {
        _checkAndNavigate();
      }
    });
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

  Future<void> _checkAndNavigate() async {
    if (_isCheckingSession) {
      return;
    }

    setState(() {
      _isCheckingSession = true;
      _statusMessage = null;
      _canRetry = false;
    });

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

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = UserErrorMessages.fromApiException(error);
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
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scaled(32)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppImages.logo,
                      width: scaled(_logoSize),
                      height: scaled(_logoSize),
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: scaled(18)),
                    if (_statusMessage == null)
                      _buildSplashAction(
                        label: 'ابدأ الآن',
                        onTap: _isCheckingSession ? null : _checkAndNavigate,
                      )
                    else
                      Column(
                        children: [
                          Text(
                            _statusMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.registerTitle,
                              fontSize: scaled(14),
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: scaled(16)),
                          if (_canRetry)
                            _buildSplashAction(
                              label: 'إعادة المحاولة',
                              onTap:
                                  _isCheckingSession ? null : _checkAndNavigate,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplashAction({
    required String label,
    VoidCallback? onTap,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: scaled(_pillHeight),
          padding: EdgeInsets.symmetric(
            horizontal: scaled(_pillHorizontalPadding),
          ),
          decoration: BoxDecoration(
            color: AppColors.splashButton,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.scaffoldBackground,
                fontSize: scaled(_pillFontSize),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
