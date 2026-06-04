import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/child_mode.dart';
import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/initial_avatar.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/network_error_state.dart';
import '../widgets/reference_parent_header.dart';
import 'add_child_screen.dart';
import 'chatbot_screen.dart';
import 'child_details_screen.dart';
import 'notifications_screen.dart';
import 'recommendations_screen.dart';
import 'reports_screen.dart';
import 'safezone_screen.dart';
import 'setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _headerController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;

  bool _isChildSelectorOpen = false;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.15),
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
      final childProvider = context.read<ChildProvider>();

      childProvider.fetchMyChildren();
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

  ChildModel? _resolveSelectedChild(List<ChildModel> children) {
    if (children.isEmpty) {
      return null;
    }

    if (_selectedChildId == null) {
      return children.first;
    }

    for (final child in children) {
      if (child.id == _selectedChildId) {
        return child;
      }
    }

    return children.first;
  }

  void _selectChild(ChildModel child) {
    setState(() {
      _selectedChildId = child.id;
      _isChildSelectorOpen = false;
    });
  }

  Future<void> _openAddChildScreen() async {
    setState(() {
      _isChildSelectorOpen = false;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddChildScreen(canSkip: false),
      ),
    );

    if (!mounted) {
      return;
    }

    await context.read<ChildProvider>().fetchMyChildren();
  }

  void _showChildRequiredMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
      ),
    );
  }

  void _openChildDetails(ChildModel? selectedChild) {
    if (selectedChild == null) {
      _showChildRequiredMessage('أضف طفلاً أولاً لعرض بياناته');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildDetailsScreen(child: selectedChild),
      ),
    );
  }

  void _openChat(ChildModel? selectedChild, {bool replace = false}) {
    if (selectedChild == null) {
      _showChildRequiredMessage('أضف طفلاً أولاً لفتح المساعد الذكي');
      return;
    }

    final route = MaterialPageRoute(
      builder: (context) => ChatbotScreen(child: selectedChild),
    );
    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
    }
  }

  void _openSafeZones(ChildModel? selectedChild, {bool replace = false}) {
    if (selectedChild == null) {
      _showChildRequiredMessage('أضف طفلاً أولاً لعرض المناطق الآمنة');
      return;
    }

    final route = MaterialPageRoute(
      builder: (context) => SafeZonesScreen(child: selectedChild),
    );
    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
    }
  }

  void _openReports(ChildModel? selectedChild) {
    if (selectedChild == null) {
      _showChildRequiredMessage('أضف طفلاً أولاً لعرض التقارير');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsScreen(child: selectedChild),
      ),
    );
  }

  void _openNotifications(ChildModel? selectedChild) {
    if (selectedChild == null) {
      _showChildRequiredMessage('أضف طفلاً أولاً لعرض التنبيهات');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(child: selectedChild),
      ),
    );
  }

  void _openRecommendations(ChildModel? selectedChild) {
    if (selectedChild == null) {
      _showChildRequiredMessage('أضف طفلاً أولاً لعرض التوصيات');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationsScreen(child: selectedChild),
      ),
    );
  }

  void _onBottomNavTap(int index, ChildModel? selectedChild) {
    switch (index) {
      case MainBottomNav.homeIndex:
        return;
      case MainBottomNav.mapIndex:
        _openSafeZones(selectedChild, replace: true);
        return;
      case MainBottomNav.reportsIndex:
        _openReports(selectedChild);
        return;
      case MainBottomNav.chatIndex:
        _openChat(selectedChild, replace: true);
        return;
      case MainBottomNav.settingsIndex:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingScreen()),
        );
        return;
    }
  }

  List<PopupMenuEntry<String>> _buildChildMenuItems({
    required ChildProvider childProvider,
    required List<ChildModel> children,
    required ChildModel? selectedChild,
  }) {
    final selectableChildren = selectedChild == null
        ? children
        : children.where((child) => child.id != selectedChild.id).toList();

    if (childProvider.isLoading) {
      return <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'جارٍ تحميل الأطفال...',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5D5A86),
            ),
          ),
        ),
      ];
    }

    if (children.isEmpty) {
      return <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            childProvider.errorMessage ?? 'لا يوجد أطفال مضافون بعد',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5D5A86),
            ),
          ),
        ),
      ];
    }

    if (selectableChildren.isEmpty) {
      return <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'لا يوجد أطفال آخرون',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5D5A86),
            ),
          ),
        ),
      ];
    }

    return selectableChildren
        .map(
          (child) => PopupMenuItem<String>(
            value: child.id,
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF8E87CC),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          child.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF342C69),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InitialAvatar(
                        label: child.name,
                        radius: 15,
                        backgroundColor: const Color(0xFFB8D9FF),
                        foregroundColor: const Color(0xFF224D67),
                        role: AvatarRole.child,
                        childGender: child.gender,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: Consumer3<AuthProvider, ChildProvider, NotificationsProvider>(
        builder:
            (context, authProvider, childProvider, notificationsProvider, _) {
          final userName = authProvider.user?.name.trim();
          final resolvedUserName =
              userName == null || userName.isEmpty ? 'ولي الأمر' : userName;
          final parentGender = authProvider.user?.parentGender;
          final children = childProvider.children;
          final selectedChild = _resolveSelectedChild(children);
          final locationLabel = selectedChild == null
              ? 'الموقع غير متاح'
              : selectedChild.deviceId.trim().isEmpty
                  ? 'في انتظار ربط الجهاز'
                  : 'في انتظار الموقع';

          return Column(
            children: [
              SlideTransition(
                position: _headerSlideAnimation,
                child: _buildHeader(
                  userName: resolvedUserName,
                  parentGender: parentGender,
                  locationLabel: locationLabel,
                  unreadCount: notificationsProvider.unreadCount,
                  selectedChild: selectedChild,
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      scaled(14),
                      scaled(14),
                      scaled(14),
                      scaled(18),
                    ),
                    child: Column(
                      children: [
                        _buildTipCard(selectedChild),
                        SizedBox(height: scaled(16)),
                        _buildChildrenSection(
                          childProvider: childProvider,
                          children: children,
                          selectedChild: selectedChild,
                        ),
                        SizedBox(height: scaled(16)),
                        _HomeFeatureCard(
                          title: 'Chat NGT',
                          subtitle: 'كيف يمكننا مساعدتك اليوم؟',
                          iconBackgroundColor: const Color(0xFFEAE3FF),
                          iconColor: const Color(0xFF7B75B6),
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () => _openChat(selectedChild),
                          scale: scale,
                        ),
                        SizedBox(height: scaled(12)),
                        _HomeFeatureCard(
                          title: 'SafeZones',
                          subtitle: 'حدد المناطق الآمنة لطفلك',
                          iconBackgroundColor: const Color(0xFFDDF7F0),
                          iconColor: const Color(0xFF6D69A9),
                          icon: Icons.home_outlined,
                          onTap: () => _openSafeZones(selectedChild),
                          scale: scale,
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
                    currentIndex: MainBottomNav.homeIndex,
                    onTap: (index) => _onBottomNavTap(index, selectedChild),
                    sizeScale: scale,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required String userName,
    required String? parentGender,
    required String locationLabel,
    required int unreadCount,
    required ChildModel? selectedChild,
  }) {
    return ReferenceParentHeader(
      userName: userName,
      subtitle: locationLabel,
      parentGender: parentGender,
      showBell: true,
      bellBadgeCount: unreadCount,
      onBellTap: () => _openNotifications(selectedChild),
    );
  }

  Widget _buildTipCard(ChildModel? selectedChild) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    final tipTarget = selectedChild?.name.trim().isNotEmpty == true
        ? selectedChild!.name
        : 'طفلك';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(scaled(26)),
        onTap: () => _openRecommendations(selectedChild),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: scaled(18),
            vertical: scaled(18),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF972A9),
                Color(0xFFFF9B5F),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(scaled(26)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x33FF9B8A),
                blurRadius: scaled(24),
                offset: Offset(0, scaled(12)),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: scaled(-40),
                top: scaled(-36),
                child: Container(
                  width: scaled(96),
                  height: scaled(96),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white70,
                    size: scaled(20),
                  ),
                  SizedBox(width: scaled(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'نصيحة اليوم',
                          style: GoogleFonts.cairo(
                            fontSize: scaled(14),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: scaled(6)),
                        Text(
                          'لاحظنا زيادة في نشاط $tipTarget اليوم -\nاضغط لمعرفة المزيد',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontSize: scaled(13.5),
                            height: 1.45,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: scaled(12)),
                  Container(
                    width: scaled(46),
                    height: scaled(46),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: const Color(0xFFFFF2A8),
                      size: scaled(28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenSection({
    required ChildProvider childProvider,
    required List<ChildModel> children,
    required ChildModel? selectedChild,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        scaled(16),
        scaled(16),
        scaled(16),
        scaled(18),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaled(26)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1F8D82D4),
            blurRadius: scaled(28),
            offset: Offset(0, scaled(14)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PopupMenuButton<String>(
                enabled: !childProvider.isLoading,
                tooltip: '',
                color: Colors.white,
                elevation: 12,
                offset: const Offset(0, 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onOpened: () {
                  setState(() {
                    _isChildSelectorOpen = true;
                  });
                },
                onCanceled: () {
                  setState(() {
                    _isChildSelectorOpen = false;
                  });
                },
                onSelected: (value) {
                  for (final child in children) {
                    if (child.id == value) {
                      _selectChild(child);
                      return;
                    }
                  }
                },
                itemBuilder: (_) => _buildChildMenuItems(
                  childProvider: childProvider,
                  children: children,
                  selectedChild: selectedChild,
                ),
                child: Icon(
                  _isChildSelectorOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFA5A2D5),
                  size: scaled(24),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'أطفالي',
                    style: GoogleFonts.cairo(
                      fontSize: scaled(20),
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF342C69),
                    ),
                  ),
                  SizedBox(width: scaled(8)),
                  Icon(
                    Icons.groups_rounded,
                    color: const Color(0xFF375481),
                    size: scaled(30),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: scaled(5)),
          Text(
            'يمكنك الاطلاع على أطفالك من هنا',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: scaled(12),
              fontWeight: FontWeight.w500,
              color: const Color(0xFFAAA6CE),
            ),
          ),
          SizedBox(height: scaled(14)),
          if (childProvider.isLoading && children.isEmpty)
            _buildChildrenLoadingCard(scale)
          else if (childProvider.errorMessage != null && children.isEmpty)
            NetworkErrorState.inline(
              title: 'تعذر تحميل بيانات الطفل',
              onRetry: () {
                context.read<ChildProvider>().fetchMyChildren();
              },
            )
          else ...[
            if (childProvider.errorMessage != null) ...[
              const OfflineBanner(),
              SizedBox(height: scaled(12)),
            ],
            _buildSelectedChildCard(selectedChild),
          ],
          SizedBox(height: scaled(14)),
          GestureDetector(
            onTap: _openAddChildScreen,
            child: SizedBox(
              width: double.infinity,
              height: scaled(78),
              child: CustomPaint(
                painter: _DashedRoundedRectPainter(
                  color: const Color(0xFFA49BDD),
                  strokeWidth: scaled(2.4),
                  radius: scaled(20),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'أضف طفل جديد',
                        style: GoogleFonts.cairo(
                          fontSize: scaled(14.5),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8178C6),
                        ),
                      ),
                      SizedBox(width: scaled(8)),
                      Icon(
                        Icons.add_rounded,
                        color: const Color(0xFF8178C6),
                        size: scaled(28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChildCard(ChildModel? selectedChild) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    if (selectedChild == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: scaled(14),
          vertical: scaled(14),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(scaled(20)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_rounded,
              color: const Color(0xFFB0AADF),
              size: scaled(20),
            ),
            SizedBox(width: scaled(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'لا يوجد طفل محدد',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(15.5),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF342C69),
                    ),
                  ),
                  SizedBox(height: scaled(3)),
                  Text(
                    'أضف طفلاً لعرض بياناته من هنا',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(12.5),
                      color: const Color(0xFF7E79B5),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: scaled(10)),
            Container(
              width: scaled(50),
              height: scaled(50),
              decoration: const BoxDecoration(
                color: Color(0xFFB8D9FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.child_care_rounded,
                color: const Color(0xFF224D67),
                size: scaled(28),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _openChildDetails(selectedChild),
      borderRadius: BorderRadius.circular(scaled(20)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: scaled(14),
          vertical: scaled(14),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE9E6FF),
          borderRadius: BorderRadius.circular(scaled(20)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_rounded,
              color: const Color(0xFFAAA2D9),
              size: scaled(20),
            ),
            SizedBox(width: scaled(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    selectedChild.name,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(16),
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF342C69),
                    ),
                  ),
                  SizedBox(height: scaled(3)),
                  Text(
                    'اضغط هنا لعرض بيانات ${selectedChild.name}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(12.5),
                      color: const Color(0xFF7E79B5),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: scaled(10)),
            InitialAvatar(
              label: selectedChild.name,
              radius: scaled(23),
              backgroundColor: const Color(0xFF9FD1FF),
              foregroundColor: const Color(0xFF224D67),
              role: AvatarRole.child,
              childGender: selectedChild.gender,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenLoadingCard(double scale) {
    double scaled(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: scaled(14),
        vertical: scaled(16),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(scaled(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: scaled(20),
            height: scaled(20),
            child: const CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFF8178C6),
            ),
          ),
          SizedBox(width: scaled(10)),
          Text(
            'جارٍ تحميل بيانات الأطفال...',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: scaled(13),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF756FB3),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  const _HomeFeatureCard({
    required this.title,
    required this.subtitle,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.icon,
    required this.onTap,
    required this.scale,
  });

  final String title;
  final String subtitle;
  final Color iconBackgroundColor;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    double scaled(double value) => value * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(scaled(24)),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: scaled(14),
            vertical: scaled(14),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(scaled(24)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A8A82D0),
                blurRadius: scaled(20),
                offset: Offset(0, scaled(10)),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back_rounded,
                color: const Color(0xFFB0AADF),
                size: scaled(20),
              ),
              SizedBox(width: scaled(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(16),
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF342C69),
                      ),
                    ),
                    SizedBox(height: scaled(3)),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(12.5),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF756FB3),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: scaled(12)),
              Container(
                width: scaled(56),
                height: scaled(56),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(scaled(18)),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: scaled(31),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final adjustedRect = rect.deflate(strokeWidth / 2);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          adjustedRect,
          Radius.circular(radius),
        ),
      );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dashWidth = 12.0;
      const dashSpace = 8.0;

      while (distance < metric.length) {
        final nextDistance =
            (distance + dashWidth).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
