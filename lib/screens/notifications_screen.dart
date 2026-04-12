import 'package:flutter/material.dart';
import 'package:malaz_app/models/child_mode.dart';
import 'package:malaz_app/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/initial_avatar.dart';
import 'chatbot_screen.dart';
import 'safezone_screen.dart';
import 'child_details_screen.dart';
import 'setting_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final ChildModel child;
  const NotificationsScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 2;

  bool _isEmergencyExpanded = false;
  bool _isDailyExpanded = false;
  bool _isWeeklyExpanded = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _headerController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _headerSlideAnimation;

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

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationsProvider =
          Provider.of<NotificationsProvider>(context, listen: false);
      if (notificationsProvider.notifications.isEmpty) {
        notificationsProvider.loadDummyData();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE dd/M/yyyy');
    return formatter.format(now).toUpperCase();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 4: //
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChildDetailsScreen(child: widget.child),
          ),
        );
        break;

      case 3: //
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SafeZonesScreen(child: widget.child),
          ),
        );
        break;

      case 2: //
        break;

      case 1: //
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatbotScreen(child: widget.child),
          ),
        );
        break;

      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SettingScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<NotificationsProvider>(
          builder: (context, notificationsProvider, child) {
            return Column(
              children: [
                SlideTransition(
                  position: _headerSlideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildHeader(notificationsProvider),
                  ),
                ),
                if (notificationsProvider.isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF224D67),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: Column(
                            children: [
                              _buildNotificationSection(
                                title: AppStrings.emergencyNotifications,
                                isExpanded: _isEmergencyExpanded,
                                notifications: notificationsProvider
                                    .emergencyNotifications,
                                onToggle: () {
                                  setState(() {
                                    _isEmergencyExpanded =
                                        !_isEmergencyExpanded;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              _buildNotificationSection(
                                title: AppStrings.dailyNotifications,
                                dateLabel: _getCurrentDate(),
                                isExpanded: _isDailyExpanded,
                                notifications:
                                    notificationsProvider.dailyNotifications,
                                onToggle: () {
                                  setState(() {
                                    _isDailyExpanded = !_isDailyExpanded;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              _buildNotificationSection(
                                title: AppStrings.weeklyNotifications,
                                isExpanded: _isWeeklyExpanded,
                                notifications:
                                    notificationsProvider.weeklyNotifications,
                                onToggle: () {
                                  setState(() {
                                    _isWeeklyExpanded = !_isWeeklyExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBottomNavBar(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationsProvider notificationsProvider) {
    final userName = context.watch<AuthProvider>().user?.name ?? '';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          decoration: const BoxDecoration(
            color: AppColors.registerTitle,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تقارير ${widget.child.name}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                InitialAvatar(
                  label: userName,
                  radius: 22,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  role: AvatarRole.parent,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: -24,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xffE5E2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF224D67),
                  size: 26,
                ),
              ),
              if (notificationsProvider.unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection({
    required String title,
    String? dateLabel,
    required bool isExpanded,
    required List<NotificationModel> notifications,
    required VoidCallback onToggle,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (dateLabel != null)
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF224D67),
                      letterSpacing: 0.5,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF224D67),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF224D67),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'لا توجد تنبيهات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Color(0xFF224D67),
                    width: 3,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: notifications.map((notification) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildNotificationItem(
                        notification: notification,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildNotificationItem({
    required NotificationModel notification,
  }) {
    IconData iconData;
    switch (notification.icon) {
      case 'warning':
        iconData = Icons.warning;
        break;
      case 'check_circle':
        iconData = Icons.check_circle;
        break;
      case 'info':
        iconData = Icons.info;
        break;
      default:
        iconData = Icons.notifications;
    }

    Color iconColorValue;
    switch (notification.iconColor) {
      case 'orange':
        iconColorValue = Colors.orange;
        break;
      case 'green':
        iconColorValue = Colors.green;
        break;
      case 'red':
        iconColorValue = Colors.red;
        break;
      default:
        iconColorValue = Colors.grey;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              notification.time,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF224D67),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              iconData,
              size: 22,
              color: iconColorValue,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            notification.text,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF224D67),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.settings_outlined, 'label': 'الاعدادات'},
      {'icon': Icons.chat_bubble_outline, 'label': 'شات'},
      {'icon': Icons.bar_chart_outlined, 'label': 'التقارير'},
      {'icon': Icons.location_on_outlined, 'label': 'المكان'},
      {'icon': Icons.home_outlined, 'label': 'الرئيسية'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final isActive = _currentNavIndex == index;
            return GestureDetector(
              onTap: () => _onNavTap(index),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      navItems[index]['icon'],
                      color: isActive
                          ? AppColors.registerTitle
                          : AppColors.homeNavInactive,
                      size: 26,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      navItems[index]['label'],
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.registerTitle
                            : AppColors.homeNavInactive,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
