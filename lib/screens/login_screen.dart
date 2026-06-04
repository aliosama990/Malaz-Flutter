import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_images.dart';
import '../helpers/shared_prefs.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static const Color _screenBackground = Color(0xFFF7F8FF);
  static const Color _fieldBorderColor = Color(0xFFC9C9C9);
  static const Color _fieldHintColor = Color(0xFF8D8D8D);
  static const Color _buttonColor = Color(0xFF6B699E);
  static const Color _mutedTextColor = Color(0xFFA8A8A8);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfLoggedIn();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'حدث خطأ أثناء تسجيل الدخول',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final selectedEmail = await authProvider.pickGoogleAccountEmail();

    if (!mounted) {
      return;
    }

    if (selectedEmail != null && selectedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = selectedEmail;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم اختيار حساب Google. أكمل كلمة المرور ثم سجل الدخول.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (authProvider.errorMessage == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authProvider.errorMessage!,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: scaled(22.0)),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: scaled(14)),
                            SlideTransition(
                              position: _logoSlideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Center(
                                  child: Image.asset(
                                    AppImages.logo,
                                    height: scaled(84),
                                    width: scaled(84),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: scaled(50)),
                            SlideTransition(
                              position: _logoSlideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Text(
                                  'أهلاً بك!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontSize: scaled(36),
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.registerTitle,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: scaled(62)),
                            _buildLabeledTextField(
                              label: 'البريد الإلكتروني',
                              controller: _emailController,
                              hint: 'Basmala@gmail.com',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'البريد الإلكتروني مطلوب';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'البريد الإلكتروني غير صحيح';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: scaled(18)),
                            _buildLabeledTextField(
                              label: 'كلمة المرور',
                              controller: _passwordController,
                              hint: '********************',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              obscureText: _isPasswordObscured,
                              onTogglePasswordVisibility: () {
                                setState(() {
                                  _isPasswordObscured = !_isPasswordObscured;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'كلمة المرور مطلوبة';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: scaled(14)),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'استرجاع كلمة المرور - قريباً',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.cairo(),
                                          ),
                                          backgroundColor: AppColors.primary,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'هل نسيت كلمة المرور؟',
                                      style: GoogleFonts.cairo(
                                        fontSize: scaled(14.5),
                                        color: _mutedTextColor,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: _mutedTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: scaled(34)),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Center(
                                  child: SizedBox(
                                    width: scaled(200),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _buttonColor,
                                        borderRadius:
                                            BorderRadius.circular(scaled(28)),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(scaled(28)),
                                          onTap: authProvider.isLoading
                                              ? null
                                              : _handleLogin,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: scaled(12),
                                            ),
                                            child: Center(
                                              child: authProvider.isLoading
                                                  ? SizedBox(
                                                      height: scaled(24),
                                                      width: scaled(24),
                                                      child:
                                                          const CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                    )
                                                  : Text(
                                                      'تسجيل الدخول',
                                                      style: GoogleFonts.cairo(
                                                        fontSize: scaled(18),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: scaled(40)),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1.4,
                                        color: _fieldBorderColor,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: scaled(18),
                                      ),
                                      child: Text(
                                        'أو من خلال',
                                        style: GoogleFonts.cairo(
                                          fontSize: scaled(14),
                                          color: _fieldHintColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1.4,
                                        color: _fieldBorderColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: scaled(20)),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(scaled(18)),
                                    border: Border.all(
                                      color: _fieldBorderColor,
                                      width: scaled(1.2),
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(scaled(18)),
                                      onTap: authProvider.isLoading
                                          ? null
                                          : _handleGoogleSignIn,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: scaled(10),
                                          horizontal: scaled(18),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: scaled(42),
                                              height: scaled(42),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.06),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Image.asset(
                                                  AppImages.googleLogo,
                                                  width: scaled(26),
                                                  height: scaled(26),
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Icon(
                                                      Icons.g_mobiledata,
                                                      size: scaled(28),
                                                      color: const Color(
                                                        0xFF4285F4,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: scaled(14)),
                                            Text(
                                              'جوجل بلاي',
                                              style: GoogleFonts.cairo(
                                                fontSize: scaled(15),
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF4F4F4F),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(height: scaled(28)),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    text: TextSpan(
                                      style: GoogleFonts.cairo(
                                        fontSize: scaled(15),
                                        color: const Color(0xFF6B6B6B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: [
                                        const TextSpan(text: 'ليس لديك حساب؟ '),
                                        TextSpan(
                                          text: 'تسجيل',
                                          style: GoogleFonts.cairo(
                                            fontSize: scaled(15),
                                            color: AppColors.registerTitle,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: scaled(24)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePasswordVisibility,
    String? Function(String?)? validator,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(right: scaled(4), bottom: scaled(5)),
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: scaled(16),
                  fontWeight: FontWeight.w700,
                  color: AppColors.registerTitle,
                ),
              ),
            ),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: isPassword && obscureText,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: scaled(14.5),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4C4C4C),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.cairo(
                  fontSize: scaled(14.5),
                  color: _fieldHintColor,
                  fontWeight: FontWeight.w500,
                ),
                suffixIconConstraints: BoxConstraints(
                  minWidth: scaled(52),
                  minHeight: scaled(52),
                ),
                suffixIcon: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: scaled(18),
                    start: scaled(8),
                  ),
                  child: Icon(
                    icon,
                    color: _fieldHintColor,
                    size: scaled(26),
                  ),
                ),
                prefixIconConstraints: isPassword
                    ? BoxConstraints(
                        minWidth: scaled(52),
                        minHeight: scaled(52),
                      )
                    : null,
                prefixIcon: isPassword
                    ? IconButton(
                        padding: EdgeInsetsDirectional.only(
                          start: scaled(18),
                          end: scaled(8),
                        ),
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _fieldHintColor,
                          size: scaled(24),
                        ),
                        onPressed: onTogglePasswordVisibility,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: scaled(20),
                  vertical: scaled(12),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaled(20)),
                  borderSide: BorderSide(
                    color: _fieldBorderColor,
                    width: scaled(1.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaled(20)),
                  borderSide: BorderSide(
                    color: _fieldBorderColor,
                    width: scaled(1.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaled(20)),
                  borderSide: BorderSide(
                    color: AppColors.registerTitle,
                    width: scaled(1.4),
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaled(20)),
                  borderSide: BorderSide(
                    color: Colors.red,
                    width: scaled(1.2),
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaled(20)),
                  borderSide: BorderSide(
                    color: Colors.red,
                    width: scaled(1.2),
                  ),
                ),
              ),
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }
}
