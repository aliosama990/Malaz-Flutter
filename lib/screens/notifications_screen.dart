import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/child_mode.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/reference_parent_header.dart';
import 'chatbot_screen.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'safezone_screen.dart';
import 'setting_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.child,
  });

  final ChildModel child;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  static const Color _pageBackground = Color(0xFFB8B8B8);
  static const Color _navPurple = Color(0xFF6D69A9);
  static const Color _textBlue = Color(0xFF183B58);
  static const Color _greenDot = Color(0xFF18E853);
  static const Color _yellowDot = Color(0xFFD8C700);
  static const Color _redAccent = Color(0xFFFF4E5F);

  late final AnimationController _fadeController;
  late final AnimationController _headerController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;

  String get _selectedChildName {
    final childName = widget.child.name.trim();
    return childName.isEmpty ? 'طفلك' : childName;
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOutCubic,
      ),
    );

    _headerController.forward();
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationsProvider = context.read<NotificationsProvider>();
      notificationsProvider.ensureDummyDataForChild(_selectedChildName);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _openSettings() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SettingScreen()),
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case MainBottomNav.homeIndex:
        _goHome();
        return;
      case MainBottomNav.mapIndex:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SafeZonesScreen(child: widget.child),
          ),
        );
        return;
      case MainBottomNav.reportsIndex:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReportsScreen(child: widget.child),
          ),
        );
        return;
      case MainBottomNav.chatIndex:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatbotScreen(child: widget.child),
          ),
        );
        return;
      case MainBottomNav.settingsIndex:
        _openSettings();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _pageBackground,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer2<AuthProvider, NotificationsProvider>(
            builder: (context, authProvider, notificationsProvider, _) {
              final rawUserName = authProvider.user?.name.trim();
              final userName = rawUserName == null || rawUserName.isEmpty
                  ? 'ولي الأمر'
                  : rawUserName;
              final parentGender = authProvider.user?.parentGender;
              final emergencyNotifications =
                  notificationsProvider.emergencyNotifications;
              final dailyNotifications =
                  notificationsProvider.dailyNotifications;

              return Column(
                children: [
                  SlideTransition(
                    position: _headerSlideAnimation,
                    child: ReferenceParentHeader(
                      userName: userName,
                      subtitle: 'يوم سعيد لك ولأطفالك، نحن نراقبهم بكل حب',
                      parentGender: parentGender,
                      showBell: true,
                      bellBadgeCount: notificationsProvider.unreadCount,
                    ),
                  ),
                  SizedBox(height: scaled(16)),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: notificationsProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: _navPurple,
                              ),
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                scaled(12),
                                0,
                                scaled(12),
                                scaled(16),
                              ),
                              child: Column(
                                children: [
                                  _buildAlertsCard(
                                    title: 'تنبيهات الطوارئ',
                                    notifications: emergencyNotifications,
                                  ),
                                  SizedBox(height: scaled(22)),
                                  _buildAlertsCard(
                                    title: 'التنبيهات اليوميه',
                                    notifications: dailyNotifications,
                                    leadingIcon: Icons.calendar_month_outlined,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SafeArea(
                      top: false,
                      child: MainBottomNav(
                        currentIndex: MainBottomNav.reportsIndex,
                        onTap: _onBottomNavTap,
                        sizeScale: scale,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsCard({
    required String title,
    required List<NotificationModel> notifications,
    IconData? leadingIcon,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        scaled(18),
        scaled(7),
        scaled(17),
        scaled(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaled(18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x23000000),
            blurRadius: scaled(14),
            offset: Offset(0, scaled(7)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: scaled(26),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    textDirection: TextDirection.rtl,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF222222),
                        size: scaled(25),
                      ),
                      SizedBox(width: scaled(4)),
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: scaled(18),
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: _textBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (leadingIcon != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      leadingIcon,
                      color: _navPurple,
                      size: scaled(25),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: scaled(8)),
          _buildTimeline(notifications),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<NotificationModel> notifications) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    if (notifications.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: scaled(12)),
        child: Text(
          'لا توجد تنبيهات حالياً',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: scaled(13),
            fontWeight: FontWeight.w700,
            color: _textBlue.withValues(alpha: 0.72),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          top: scaled(10),
          bottom: scaled(12),
          right: scaled(3),
          child: Container(
            width: scaled(1.6),
            color: _textBlue,
          ),
        ),
        Column(
          children: List.generate(
            notifications.length,
            (index) {
              final notification = notifications[index];
              final isLast = index == notifications.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : scaled(13)),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: scaled(20),
                      height: scaled(29),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: scaled(6)),
                          child: Container(
                            width: scaled(10),
                            height: scaled(10),
                            decoration: BoxDecoration(
                              color: _dotColor(notification.iconColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: scaled(5)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _notificationTextForSelectedChild(
                              notification.text,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              fontSize: scaled(13),
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              color: _textBlue,
                            ),
                          ),
                          SizedBox(height: scaled(2)),
                          Text(
                            notification.time,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              fontSize: scaled(11.8),
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              color: _textBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _notificationTextForSelectedChild(String text) {
    final childName = _selectedChildName;
    final replacements = <String, String>{
      'لسلمي': 'لـ $childName',
      'لسلمى': 'لـ $childName',
      'لأحمد': 'لـ $childName',
      'لاحمد': 'لـ $childName',
      'لـ Donia': 'لـ $childName',
      'لـ donia': 'لـ $childName',
      'سلمي': childName,
      'سلمى': childName,
      'أحمد': childName,
      'احمد': childName,
      'Donia': childName,
      'donia': childName,
    };

    var resolvedText = text;
    for (final entry in replacements.entries) {
      resolvedText = resolvedText.replaceAll(entry.key, entry.value);
    }

    return resolvedText;
  }

  Color _dotColor(String colorName) {
    switch (colorName.trim().toLowerCase()) {
      case 'green':
        return _greenDot;
      case 'red':
        return _redAccent;
      case 'orange':
      case 'yellow':
      default:
        return _yellowDot;
    }
  }
}
