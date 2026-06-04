import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/child_mode.dart';
import '../models/emergency_audio_alert_model.dart';
import '../providers/auth_provider.dart';
import '../providers/device_live_provider.dart';
import '../widgets/main_bottom_nav.dart';
import 'chatbot_screen.dart';
import 'emergency_alert_details_screen.dart';
import 'home_screen.dart';
import 'safezone_screen.dart';
import 'setting_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.child,
  });

  final ChildModel child;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const Color _pageBackground = Color(0xFFF4F5FB);
  static const Color _surface = Colors.white;
  static const Color _heading = Color(0xFF23233E);
  static const Color _muted = Color(0xFF9AA1B4);
  static const Color _purple = Color(0xFF8575C8);
  static const Color _red = Color(0xFFFF5061);
  static const Color _redSoft = Color(0xFFFFF1F3);
  static const Color _orange = Color(0xFFE58600);
  static const Color _orangeSoft = Color(0xFFFFFAE8);
  static const Color _green = Color(0xFF33BE74);
  static const Color _greenSoft = Color(0xFFEFFFF7);

  _ReportFilter _selectedFilter = _ReportFilter.emergency;
  String? _selectedAlertId;

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  String get _childName {
    final name = widget.child.name.trim();
    return name.isEmpty ? 'سلمى' : name;
  }

  String get _deviceId {
    final deviceId = widget.child.deviceId.trim();
    return deviceId.isEmpty ? 'what89' : deviceId;
  }

  DateTime get _sampleToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  EmergencyAudioAlert _buildEmergencyAudioAlert({
    required String id,
    required DateTime time,
    required String locationName,
    required bool isSos,
  }) {
    return EmergencyAudioAlert(
      childName: _childName,
      deviceId: _deviceId,
      timestamp: time,
      latitude: 31.0444,
      longitude: 31.3847,
      locationName: locationName,
      isSOSPressed: isSos,
      audioUrl: '/emergency-audio/$_deviceId/$id.mp3',
      audioFileName: '$id.mp3',
    );
  }

  List<_ReportAlert> get _sampleAlerts {
    final today = _sampleToday;
    final schoolTimeAlert =
        DateTime(today.year, today.month, today.day, 11, 45);
    final safeZoneAlert = DateTime(today.year, today.month, today.day, 10, 3);
    final sosAlertTime = DateTime(today.year, today.month, today.day, 10, 35);
    final dailyAlertTime = DateTime(today.year, today.month, today.day, 8, 30);
    final dailyWarningTime =
        DateTime(today.year, today.month, today.day, 10, 3);
    final dailySafeTime = DateTime(today.year, today.month, today.day, 10, 35);
    final dailySchoolEndTime =
        DateTime(today.year, today.month, today.day, 11, 45);
    final dailyHomeTime = DateTime(today.year, today.month, today.day, 14, 15);
    final sosAlert = _buildEmergencyAudioAlert(
      id: '20260514155821877_24762b38bd9443f68c589848199b00f0',
      time: sosAlertTime,
      locationName: 'المدرسة الدولية - الحدود الشمالية',
      isSos: true,
    );

    return <_ReportAlert>[
      _ReportAlert(
        id: 'school-end',
        title: 'اقترب موعد انتهاء اليوم الدراسي لـ $_childName',
        description: 'يرجى التوجه لاصطحابها في أقرب وقت ممكن',
        time: schoolTimeAlert,
        locationName: 'المدرسة الدولية - 10:03 ص',
        kind: _ReportAlertKind.emergency,
        emergencyAudioAlert: _buildEmergencyAudioAlert(
          id: 'school-end-alert',
          time: schoolTimeAlert,
          locationName: 'المدرسة الدولية - 10:03 ص',
          isSos: false,
        ),
      ),
      _ReportAlert(
        id: 'safe-zone',
        title: '$_childName تقترب من حدود منطقة الأمان',
        description: 'اقتربت $_childName من الحدود المخصصة للمنطقة الآمنة',
        time: safeZoneAlert,
        locationName: 'منطقة الأمان - الحدود الشمالية',
        kind: _ReportAlertKind.emergency,
        emergencyAudioAlert: _buildEmergencyAudioAlert(
          id: 'safe-zone-alert',
          time: safeZoneAlert,
          locationName: 'منطقة الأمان - الحدود الشمالية',
          isSos: false,
        ),
      ),
      _ReportAlert(
        id: 'sos',
        title: '$_childName ضغطت زر الطوارئ',
        description:
            'تم استلام نداء الطوارئ ورسالة صوتية من الجهاز - يرجى الرد فوراً',
        time: sosAlertTime,
        locationName: sosAlert.locationName,
        kind: _ReportAlertKind.emergency,
        isSos: true,
        emergencyAudioAlert: sosAlert,
      ),
      _ReportAlert(
        id: 'daily-arrival',
        title: '$_childName وصلت المدرسة بأمان',
        description: 'تم تأكيد وصولها داخل المنطقة الآمنة بنجاح',
        time: dailyAlertTime,
        locationName: 'المدرسة الدولية',
        kind: _ReportAlertKind.daily,
        statusLabel: 'آمن',
        statusTone: _DailyStatusTone.safe,
      ),
      _ReportAlert(
        id: 'daily-near-zone',
        title: '$_childName اقتربت من حدود المنطقة الآمنة',
        description: 'تحذير اقتراب من الحدود المخصصة للمنطقة',
        time: dailyWarningTime,
        locationName: 'منطقة الأمان',
        kind: _ReportAlertKind.daily,
        statusLabel: 'تحذير',
        statusTone: _DailyStatusTone.warning,
      ),
      _ReportAlert(
        id: 'daily-inside-zone',
        title: '$_childName الآن داخل منطقة أمان',
        description: 'عادت $_childName داخل الحدود الآمنة المحددة',
        time: dailySafeTime,
        locationName: 'منطقة الأمان',
        kind: _ReportAlertKind.daily,
        statusLabel: 'آمن',
        statusTone: _DailyStatusTone.safe,
      ),
      _ReportAlert(
        id: 'daily-school-end',
        title: 'اقترب موعد نهاية اليوم الدراسي لـ $_childName',
        description: 'يرجى التوجه لاصطحابها من المدرسة',
        time: dailySchoolEndTime,
        locationName: 'المدرسة الدولية',
        kind: _ReportAlertKind.daily,
        statusLabel: 'تنبيه',
        statusTone: _DailyStatusTone.notice,
      ),
      _ReportAlert(
        id: 'daily-home',
        title: '$_childName وصلت إلى المنزل',
        description: 'تم تسجيل وصولها إلى منطقة المنزل بأمان',
        time: dailyHomeTime,
        locationName: 'المنزل',
        kind: _ReportAlertKind.daily,
        statusLabel: 'آمن',
        statusTone: _DailyStatusTone.safe,
      ),
    ];
  }

  List<_ReportAlert> _visibleAlerts(
    List<EmergencyAudioAlert> emergencyAudioAlerts,
  ) {
    final alerts = _alertsWithLiveEmergencyAudio(emergencyAudioAlerts);
    switch (_selectedFilter) {
      case _ReportFilter.all:
        return alerts;
      case _ReportFilter.emergency:
        return alerts
            .where((alert) => alert.kind == _ReportAlertKind.emergency)
            .toList(growable: false);
      case _ReportFilter.daily:
        return alerts
            .where((alert) => alert.kind == _ReportAlertKind.daily)
            .toList(growable: false);
      case _ReportFilter.today:
        final today = _sampleToday;
        return alerts
            .where(
              (alert) =>
                  alert.time.year == today.year &&
                  alert.time.month == today.month &&
                  alert.time.day == today.day,
            )
            .toList(growable: false);
    }
  }

  List<_ReportAlert> _alertsWithLiveEmergencyAudio(
    List<EmergencyAudioAlert> emergencyAudioAlerts,
  ) {
    if (emergencyAudioAlerts.isEmpty) {
      return _sampleAlerts;
    }

    return <_ReportAlert>[
      ...emergencyAudioAlerts.indexed.map(
        (entry) => _buildReportAlertFromEmergencyAudio(
          alert: entry.$2,
          index: entry.$1,
        ),
      ),
      ..._sampleAlerts,
    ];
  }

  _ReportAlert _buildReportAlertFromEmergencyAudio({
    required EmergencyAudioAlert alert,
    required int index,
  }) {
    final childName =
        alert.childName.trim().isEmpty ? _childName : alert.childName.trim();
    final locationName = alert.locationName.trim().isEmpty
        ? 'الموقع غير محدد'
        : alert.locationName.trim();
    final audioKey = alert.audioUrl.trim().isNotEmpty
        ? alert.audioUrl.trim()
        : alert.audioFileName.trim();
    final reportId = audioKey.isNotEmpty
        ? 'live-emergency-$audioKey'
        : 'live-emergency-${alert.deviceId}-${alert.timestamp}-$index';
    final hasAudio = alert.audioUrl.trim().isNotEmpty ||
        alert.audioFileName.trim().isNotEmpty;

    return _ReportAlert(
      id: reportId,
      title: alert.isSOSPressed
          ? '$childName ضغطت زر الطوارئ'
          : 'نداء طوارئ من $childName',
      description: hasAudio
          ? 'تم استلام نداء الطوارئ ورسالة صوتية من الجهاز - يرجى الرد فوراً'
          : 'تم استلام نداء طوارئ من الجهاز - يرجى الرد فوراً',
      time: alert.timestamp?.toLocal() ?? DateTime.now(),
      locationName: locationName,
      kind: _ReportAlertKind.emergency,
      isSos: alert.isSOSPressed,
      emergencyAudioAlert: alert,
    );
  }

  _ReportSectionInfo get _sectionInfo {
    switch (_selectedFilter) {
      case _ReportFilter.emergency:
        return const _ReportSectionInfo(
          title: 'تنبيهات الطوارئ',
          badgeText: '2 جديد',
          accentColor: _red,
          badgeBackgroundColor: _redSoft,
          badgeTextColor: _red,
        );
      case _ReportFilter.daily:
        return const _ReportSectionInfo(
          title: 'التنبيهات اليومية',
          badgeText: '5 تنبيهات',
          accentColor: Color(0xFFFFC247),
          badgeBackgroundColor: Color(0xFFFFF6D9),
          badgeTextColor: _orange,
        );
      case _ReportFilter.all:
        return const _ReportSectionInfo(
          title: 'كل التنبيهات',
          badgeText: '7 تنبيهات',
          accentColor: _purple,
          badgeBackgroundColor: Color(0xFFEAFBFF),
          badgeTextColor: Color(0xFF4861CF),
        );
      case _ReportFilter.today:
        return const _ReportSectionInfo(
          title: 'تنبيهات اليوم',
          badgeText: 'اليوم',
          accentColor: _purple,
          badgeBackgroundColor: Color(0xFFEAFBFF),
          badgeTextColor: Color(0xFF4861CF),
        );
    }
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
    if (index == MainBottomNav.reportsIndex) {
      return;
    }

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

  Future<void> _selectAndOpenAlert(_ReportAlert alert) async {
    final emergencyAudioAlert = alert.emergencyAudioAlert;
    if (emergencyAudioAlert == null) {
      return;
    }

    setState(() {
      _selectedAlertId = alert.id;
    });

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyAlertDetailsScreen(
          alert: emergencyAudioAlert,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    final userName =
        context.watch<AuthProvider>().user?.name.trim().isNotEmpty == true
            ? context.watch<AuthProvider>().user!.name.trim()
            : 'مروة عبد الرحمن';
    final deviceLiveProvider = _watchDeviceLiveProviderIfAvailable(context);
    final emergencyAudioAlerts = _liveEmergencyAudioAlerts(deviceLiveProvider);
    final alerts = _visibleAlerts(emergencyAudioAlerts);
    final sectionInfo = _sectionInfo;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      scale: scale,
                      userName: userName,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16 * scale,
                        0,
                        16 * scale,
                        14 * scale,
                      ),
                      child: Column(
                        children: [
                          _buildStatsRow(scale),
                          SizedBox(height: 24 * scale),
                          _buildFilters(scale),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildAlertsSectionHeader(
                      scale: scale,
                      sectionInfo: sectionInfo,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      0,
                      16 * scale,
                      20 * scale,
                    ),
                    sliver: SliverList.separated(
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => SizedBox(height: 14 * scale),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        if (alert.kind == _ReportAlertKind.daily) {
                          return _buildDailyAlertCard(
                            alert: alert,
                            scale: scale,
                          );
                        }

                        return _buildAlertCard(
                          alert: alert,
                          scale: scale,
                          isSelected: _selectedAlertId == alert.id,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: MainBottomNav(
                currentIndex: MainBottomNav.reportsIndex,
                onTap: _onBottomNavTap,
                sizeScale: scale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DeviceLiveProvider? _watchDeviceLiveProviderIfAvailable(
    BuildContext context,
  ) {
    try {
      return context.watch<DeviceLiveProvider>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  List<EmergencyAudioAlert> _liveEmergencyAudioAlerts(
    DeviceLiveProvider? scopedProvider,
  ) {
    return scopedProvider?.recentEmergencyAudioAlerts ??
        const <EmergencyAudioAlert>[];
  }

  Widget _buildHeader({
    required double scale,
    required String userName,
  }) {
    return Container(
      color: _surface,
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        (16 + MediaQuery.paddingOf(context).top) * scale,
        16 * scale,
        22 * scale,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60 * scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildBackButton(scale),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildAvatar(scale),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'التقارير اليومية',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 23 * scale,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: _heading,
                      ),
                    ),
                    SizedBox(height: 7 * scale),
                    Text(
                      '$userName - الأربعاء',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11 * scale,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(double scale) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _goHome,
        borderRadius: BorderRadius.circular(11 * scale),
        child: Ink(
          width: 34 * scale,
          height: 34 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFF),
            borderRadius: BorderRadius.circular(11 * scale),
            border: Border.all(color: const Color(0xFFE8E4F4)),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF697087),
            size: 17 * scale,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double scale) {
    return Container(
      width: 52 * scale,
      height: 52 * scale,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _purple,
        shape: BoxShape.circle,
      ),
      child: Text(
        _childName.characters.first,
        style: GoogleFonts.cairo(
          fontSize: 18 * scale,
          height: 1,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsRow(double scale) {
    final stats = <_ReportStat>[
      const _ReportStat(
        value: 'آمن',
        label: 'الحالة الآن',
        valueColor: _green,
        backgroundColor: _greenSoft,
        borderColor: Color(0xFFC8F4DF),
      ),
      const _ReportStat(
        value: '5',
        label: 'تنبيه يومي',
        valueColor: _orange,
        backgroundColor: _orangeSoft,
        borderColor: Color(0xFFF8DE9C),
      ),
      const _ReportStat(
        value: '2',
        label: 'تنبيه طوارئ',
        valueColor: _red,
        backgroundColor: _redSoft,
        borderColor: Color(0xFFFFCED5),
      ),
    ];

    return Row(
      children: stats
          .map(
            (stat) => Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                child: _buildStatCard(
                  stat: stat,
                  scale: scale,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildStatCard({
    required _ReportStat stat,
    required double scale,
  }) {
    return Container(
      height: 64 * scale,
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: stat.backgroundColor,
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: stat.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: stat.value == 'آمن' ? 18 * scale : 20 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
              color: stat.valueColor,
            ),
          ),
          SizedBox(height: 9 * scale),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 10 * scale,
              height: 1,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8F94AA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(double scale) {
    return Row(
      children: [
        _buildFilterChip(
          label: 'الكل',
          scale: scale,
          selected: _selectedFilter == _ReportFilter.all,
          onTap: () => _setFilter(_ReportFilter.all),
        ),
        SizedBox(width: 12 * scale),
        _buildFilterChip(
          label: 'الطوارئ',
          scale: scale,
          selected: _selectedFilter == _ReportFilter.emergency,
          onTap: () => _setFilter(_ReportFilter.emergency),
        ),
        SizedBox(width: 12 * scale),
        _buildFilterChip(
          label: 'اليومية',
          scale: scale,
          selected: _selectedFilter == _ReportFilter.daily,
          onTap: () => _setFilter(_ReportFilter.daily),
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _setFilter(_ReportFilter.today),
            borderRadius: BorderRadius.circular(9 * scale),
            child: Ink(
              height: 34 * scale,
              padding: EdgeInsets.symmetric(horizontal: 11 * scale),
              decoration: BoxDecoration(
                color: _selectedFilter == _ReportFilter.today
                    ? const Color(0xFFEAFBFF)
                    : const Color(0xFFFAFAFF),
                borderRadius: BorderRadius.circular(9 * scale),
                border: Border.all(color: const Color(0xFFE4E3F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14 * scale,
                    color: _selectedFilter == _ReportFilter.today
                        ? const Color(0xFF4861CF)
                        : const Color(0xFF8E95AA),
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    'اليوم',
                    style: GoogleFonts.cairo(
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.w700,
                      color: _selectedFilter == _ReportFilter.today
                          ? const Color(0xFF4861CF)
                          : const Color(0xFF8E95AA),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _setFilter(_ReportFilter filter) {
    setState(() {
      _selectedFilter = filter;
      _selectedAlertId = null;
    });
  }

  Widget _buildFilterChip({
    required String label,
    required double scale,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8 * scale),
        child: Ink(
          height: 26 * scale,
          padding: EdgeInsets.symmetric(horizontal: 13 * scale),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAFBFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11 * scale,
                height: 1,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: selected
                    ? const Color(0xFF4861CF)
                    : const Color(0xFF8179A5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsSectionHeader({
    required double scale,
    required _ReportSectionInfo sectionInfo,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        16 * scale,
        16 * scale,
        14 * scale,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3FA),
        border: Border(
          top: BorderSide(color: Color(0xFFE8EAF2)),
        ),
      ),
      child: Row(
        children: [
          Text(
            sectionInfo.title,
            style: GoogleFonts.cairo(
              fontSize: 15 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
              color: _heading,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              Container(
                width: 2 * scale,
                height: 18 * scale,
                decoration: BoxDecoration(
                  color: sectionInfo.accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(width: 8 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 3 * scale,
                ),
                decoration: BoxDecoration(
                  color: sectionInfo.badgeBackgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  sectionInfo.badgeText,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: 9 * scale,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: sectionInfo.badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAlertCard({
    required _ReportAlert alert,
    required double scale,
  }) {
    final tone = alert.statusTone ?? _DailyStatusTone.safe;
    final toneColors = _dailyToneColors(tone);

    return Container(
      constraints: BoxConstraints(minHeight: 104 * scale),
      padding: EdgeInsets.fromLTRB(
        12 * scale,
        14 * scale,
        14 * scale,
        12 * scale,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15 * scale),
        border: Border.all(color: toneColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: toneColors.shadowColor,
            blurRadius: 18 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 33 * scale,
                height: 33 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: toneColors.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 17 * scale,
                  color: toneColors.iconColor,
                ),
              ),
              SizedBox(width: 11 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: 13 * scale,
                        height: 1.35,
                        fontWeight: FontWeight.w900,
                        color: _heading,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      alert.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: 10 * scale,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF858DA5),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 9 * scale),
              Text(
                _formatTime(alert.time),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 9 * scale,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9DA5BA),
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 9 * scale,
                vertical: 4 * scale,
              ),
              decoration: BoxDecoration(
                color: toneColors.badgeBackgroundColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                alert.statusLabel ?? 'آمن',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 9 * scale,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: toneColors.badgeTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required _ReportAlert alert,
    required double scale,
    required bool isSelected,
  }) {
    final isEmergency = alert.kind == _ReportAlertKind.emergency;
    final markerColor = isEmergency ? _red : _green;
    final cardRadius = BorderRadius.circular(15 * scale);
    final cardShadow = [
      BoxShadow(
        color: isEmergency ? const Color(0x14FF5061) : const Color(0x1233BE74),
        blurRadius: 18 * scale,
        offset: Offset(0, 8 * scale),
      ),
    ];
    final cardBody = Container(
      constraints: BoxConstraints(
        minHeight: isSelected ? 118 * scale : 112 * scale,
      ),
      padding: EdgeInsets.fromLTRB(
        12 * scale,
        14 * scale,
        14 * scale,
        12 * scale,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: cardRadius,
        border: Border.all(
          color:
              isEmergency ? const Color(0xFFFFDCE2) : const Color(0xFFE4F4EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isSelected ? 12 * scale : 7 * scale,
                          height: 7 * scale,
                          margin: EdgeInsets.only(top: 7 * scale),
                          decoration: BoxDecoration(
                            color: markerColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        SizedBox(width: 9 * scale),
                        Expanded(
                          child: Text(
                            alert.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              fontSize: 13 * scale,
                              height: 1.35,
                              fontWeight: FontWeight.w900,
                              color: _heading,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * scale),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        alert.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: 10 * scale,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF858DA5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12 * scale),
              Text(
                _formatTime(alert.time),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 9 * scale,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9DA5BA),
                ),
              ),
            ],
          ),
          SizedBox(height: 13 * scale),
          if (isSelected)
            Row(
              textDirection: TextDirection.ltr,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9 * scale,
                    vertical: 5 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: _redSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'SOS',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: GoogleFonts.cairo(
                      fontSize: 8 * scale,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: _red,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 5 * scale,
                  height: 5 * scale,
                  decoration: const BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Flexible(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      alert.locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: 9 * scale,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9DA5BA),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              textDirection: TextDirection.ltr,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: markerColor,
                  size: 13 * scale,
                ),
                const Spacer(),
                Flexible(
                  flex: 6,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      alert.locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: 9 * scale,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9DA5BA),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    final content = Container(
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        boxShadow: cardShadow,
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: Stack(
          children: [
            cardBody,
            if (isSelected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3 * scale,
                  color: _red,
                ),
              ),
          ],
        ),
      ),
    );

    if (alert.emergencyAudioAlert == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectAndOpenAlert(alert),
        borderRadius: BorderRadius.circular(15 * scale),
        child: content,
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  _DailyToneColors _dailyToneColors(_DailyStatusTone tone) {
    switch (tone) {
      case _DailyStatusTone.safe:
        return const _DailyToneColors(
          iconColor: _green,
          iconBackgroundColor: _greenSoft,
          badgeTextColor: _green,
          badgeBackgroundColor: _greenSoft,
          borderColor: Color(0xFFE7EDF5),
          shadowColor: Color(0x12000000),
        );
      case _DailyStatusTone.warning:
        return const _DailyToneColors(
          iconColor: _green,
          iconBackgroundColor: _orangeSoft,
          badgeTextColor: _orange,
          badgeBackgroundColor: _orangeSoft,
          borderColor: Color(0xFFFFE8B7),
          shadowColor: Color(0x14E58600),
        );
      case _DailyStatusTone.notice:
        return const _DailyToneColors(
          iconColor: _green,
          iconBackgroundColor: _orangeSoft,
          badgeTextColor: _orange,
          badgeBackgroundColor: _orangeSoft,
          borderColor: Color(0xFFE7EDF5),
          shadowColor: Color(0x12000000),
        );
    }
  }
}

class _ReportStat {
  const _ReportStat({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String value;
  final String label;
  final Color valueColor;
  final Color backgroundColor;
  final Color borderColor;
}

class _ReportAlert {
  const _ReportAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.locationName,
    required this.kind,
    this.isSos = false,
    this.emergencyAudioAlert,
    this.statusLabel,
    this.statusTone,
  });

  final String id;
  final String title;
  final String description;
  final DateTime time;
  final String locationName;
  final _ReportAlertKind kind;
  final bool isSos;
  final EmergencyAudioAlert? emergencyAudioAlert;
  final String? statusLabel;
  final _DailyStatusTone? statusTone;
}

class _ReportSectionInfo {
  const _ReportSectionInfo({
    required this.title,
    required this.badgeText,
    required this.accentColor,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
  });

  final String title;
  final String badgeText;
  final Color accentColor;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;
}

class _DailyToneColors {
  const _DailyToneColors({
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.badgeTextColor,
    required this.badgeBackgroundColor,
    required this.borderColor,
    required this.shadowColor,
  });

  final Color iconColor;
  final Color iconBackgroundColor;
  final Color badgeTextColor;
  final Color badgeBackgroundColor;
  final Color borderColor;
  final Color shadowColor;
}

enum _ReportAlertKind {
  emergency,
  daily,
}

enum _ReportFilter {
  all,
  emergency,
  daily,
  today,
}

enum _DailyStatusTone {
  safe,
  warning,
  notice,
}
