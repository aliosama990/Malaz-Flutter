import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/child_mode.dart';
import '../models/device_live_models.dart';
import '../models/safe_zone_status.dart';
import '../providers/child_provider.dart';
import '../providers/device_live_provider.dart';
import '../services/device_hub_service.dart';
import '../widgets/initial_avatar.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/network_error_state.dart';
import 'chatbot_screen.dart';
import 'child_data_screen.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'setting_screen.dart';

class ChildDetailsScreen extends StatefulWidget {
  const ChildDetailsScreen({super.key, required this.child});

  final ChildModel child;

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _BottomStatusPreset {
  const _BottomStatusPreset({
    required this.batteryPercentage,
    required this.batteryLabel,
    required this.isCharging,
    required this.activityText,
  });

  final int batteryPercentage;
  final String batteryLabel;
  final bool isCharging;
  final String activityText;
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  static const Color _pageBackground = Color(0xFFF1F1F4);
  static const Color _headerStart = Color(0xFFD4D5E0);
  static const Color _headerEnd = Color(0xFFC8C8D7);
  static const Color _panelColor = Color(0xFFD3D2F1);
  static const Color _headingColor = Color(0xFF234B70);
  static const Color _borderBlue = Color(0xFF3F7EEA);
  static const Color _successGreen = Color(0xFF43EC13);
  static const Color _softGreen = Color(0xFF2DAF4B);
  static const Color _warningOrange = Color(0xFFFFA000);
  static const Color _dangerRed = Color(0xFFFF2F3D);

  static const LatLng _fallbackMapCenter = LatLng(30.0444, 31.2357);
  static const TemporarySafeZoneStatusSource _safeZoneStatusSource =
      TemporarySafeZoneStatusSource();
  static final math.Random _bottomStatusRandom = math.Random();
  static final Map<String, _BottomStatusPreset> _bottomStatusByChild = {};
  static const List<_BottomStatusPreset> _bottomStatusPresets = [
    _BottomStatusPreset(
      batteryPercentage: 78,
      batteryLabel: 'البطارية جيدة',
      isCharging: true,
      activityText: 'ساكن لمدة 20 دقيقة',
    ),
    _BottomStatusPreset(
      batteryPercentage: 50,
      batteryLabel: 'بطارية متوسطة',
      isCharging: true,
      activityText: 'ساكن لمدة ساعة',
    ),
    _BottomStatusPreset(
      batteryPercentage: 92,
      batteryLabel: 'مشحونة بالكامل',
      isCharging: false,
      activityText: 'في حالة حركة الآن',
    ),
    _BottomStatusPreset(
      batteryPercentage: 35,
      batteryLabel: 'يفضل الشحن قريباً',
      isCharging: false,
      activityText: 'متحرك منذ 8 دقائق',
    ),
    _BottomStatusPreset(
      batteryPercentage: 64,
      batteryLabel: 'يشحن الآن',
      isCharging: true,
      activityText: 'ساكن لمدة 12 دقيقة',
    ),
  ];

  late Future<ChildModel?> _childFuture;
  late final DeviceLiveProvider _deviceLiveProvider;

  @override
  void initState() {
    super.initState();
    _deviceLiveProvider = DeviceLiveProvider();
    _subscribeToChildDevice(widget.child);
    _childFuture = Provider.of<ChildProvider>(
      context,
      listen: false,
    ).fetchChildById(widget.child.id).then((fetchedChild) {
      if (!mounted) {
        return fetchedChild;
      }

      _subscribeToChildDevice(fetchedChild ?? widget.child);
      return fetchedChild;
    });
  }

  @override
  void dispose() {
    _deviceLiveProvider.dispose();
    super.dispose();
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  void _subscribeToChildDevice(ChildModel child) {
    unawaited(_deviceLiveProvider.connectToDevice(child.deviceId));
  }

  void _retryChildDetails(ChildModel child) {
    _subscribeToChildDevice(child);
    setState(() {
      _childFuture = Provider.of<ChildProvider>(
        context,
        listen: false,
      ).fetchChildById(child.id).then((fetchedChild) {
        if (!mounted) {
          return fetchedChild;
        }

        _subscribeToChildDevice(fetchedChild ?? child);
        return fetchedChild;
      });
    });
  }

  void _retryLiveLocation(ChildModel child) {
    _subscribeToChildDevice(child);
  }

  Future<void> _handleBack() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _openChildSettings(ChildModel child) async {
    final updatedChild = await Navigator.push<ChildModel>(
      context,
      MaterialPageRoute(
        builder: (context) => ChildDataSettingsScreen(
          child: child,
          popWithResult: true,
        ),
      ),
    );

    if (!mounted || updatedChild == null) {
      return;
    }

    _subscribeToChildDevice(updatedChild);
    setState(() {
      _childFuture = Future<ChildModel?>.value(updatedChild);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DeviceLiveProvider>.value(
      value: _deviceLiveProvider,
      child: Consumer2<ChildProvider, DeviceLiveProvider>(
        builder: (context, childProvider, deviceLiveProvider, _) {
          return FutureBuilder<ChildModel?>(
            future: _childFuture,
            initialData: widget.child,
            builder: (context, snapshot) {
              final child = snapshot.data ?? widget.child;
              final latestReading = deviceLiveProvider.latestReading;
              final latestAlert = deviceLiveProvider.latestAlert;
              final recentAlerts = deviceLiveProvider.recentAlerts;
              final safeZoneStatus =
                  _safeZoneStatusSource.resolve(latestReading);
              final scale = _screenScale(context);
              double scaled(double value) => value * scale;

              return Scaffold(
                backgroundColor: _pageBackground,
                body: Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildTopBlurArea(),
                              Transform.translate(
                                offset: Offset(0, scaled(-34)),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: scaled(14),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildMainCard(
                                        child: child,
                                        deviceLiveProvider: deviceLiveProvider,
                                        latestReading: latestReading,
                                        safeZoneStatus: safeZoneStatus,
                                      ),
                                      if (childProvider.isLoading &&
                                          childProvider.errorMessage ==
                                              null) ...[
                                        SizedBox(height: scaled(14)),
                                        _buildStatusBanner(
                                          message: 'جارٍ تحديث بيانات الطفل...',
                                          backgroundColor:
                                              const Color(0xFFF0EEFF),
                                          borderColor: const Color(0xFFE2DBFF),
                                          textColor: const Color(0xFF6D6AA9),
                                        ),
                                      ],
                                      if (childProvider.errorMessage !=
                                          null) ...[
                                        SizedBox(height: scaled(14)),
                                        NetworkErrorState.inline(
                                          title: 'تعذر تحميل بيانات الطفل',
                                          onRetry: () =>
                                              _retryChildDetails(child),
                                        ),
                                      ],
                                      if (deviceLiveProvider.errorMessage !=
                                              null &&
                                          deviceLiveProvider.errorMessage !=
                                              childProvider.errorMessage) ...[
                                        SizedBox(height: scaled(14)),
                                        NetworkErrorState.inline(
                                          title: 'تعذر تحميل الموقع المباشر',
                                          onRetry: () =>
                                              _retryLiveLocation(child),
                                        ),
                                      ],
                                      if (latestAlert != null) ...[
                                        SizedBox(height: scaled(14)),
                                        _buildStatusBanner(
                                          message:
                                              'تنبيه مباشر: ${latestAlert.message}',
                                          backgroundColor:
                                              const Color(0xFFFFF3E0),
                                          borderColor: const Color(0xFFFFB74D),
                                          textColor: const Color(0xFFBF360C),
                                        ),
                                      ],
                                      if (deviceLiveProvider.isReadingStale &&
                                          latestReading != null) ...[
                                        SizedBox(height: scaled(14)),
                                        _buildStatusBanner(
                                          message:
                                              'لم تصل قراءات جديدة منذ ${_formatReadingTimestamp(latestReading.receivedAt)} وقد تكون البيانات قديمة.',
                                          backgroundColor:
                                              const Color(0xFFFFF8E1),
                                          borderColor: const Color(0xFFFFCC80),
                                          textColor: const Color(0xFFE65100),
                                        ),
                                      ],
                                      if (recentAlerts.isNotEmpty) ...[
                                        SizedBox(height: scaled(14)),
                                        _buildRecentAlertsCard(recentAlerts),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: _buildBottomNavBar(context, child),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopBlurArea() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final topPadding = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(scaled(4)),
        bottomRight: Radius.circular(scaled(4)),
      ),
      child: Container(
        height: topPadding + scaled(178),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _headerStart,
              _headerEnd,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x24000000),
              blurRadius: scaled(26),
              offset: Offset(0, scaled(12)),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: scaled(-30),
              top: topPadding + scaled(42),
              child: _buildHeaderOrb(scaled(110), 0.24),
            ),
            Positioned(
              right: scaled(-28),
              top: topPadding - scaled(18),
              child: _buildHeaderOrb(scaled(134), 0.18),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: scaled(-6),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: scaled(18),
                    sigmaY: scaled(18),
                  ),
                  child: Container(
                    height: scaled(58),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: topPadding + scaled(36),
              right: scaled(26),
              child: IconButton(
                onPressed: _handleBack,
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: const Color(0xFF66689A),
                  size: scaled(32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderOrb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMainCard({
    required ChildModel child,
    required DeviceLiveProvider deviceLiveProvider,
    required DeviceReading? latestReading,
    required SafeZoneStatus safeZoneStatus,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        scaled(16),
        scaled(16),
        scaled(16),
        scaled(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaled(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x21000000),
            blurRadius: scaled(26),
            offset: Offset(0, scaled(14)),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildChildHeader(child),
          SizedBox(height: scaled(16)),
          Container(
            width: double.infinity,
            height: scaled(1.4),
            color: const Color(0xFF163B64),
          ),
          SizedBox(height: scaled(18)),
          _buildVitalsPanel(
            latestReading: latestReading,
            deviceLiveProvider: deviceLiveProvider,
            safeZoneStatus: safeZoneStatus,
          ),
          SizedBox(height: scaled(16)),
          _buildLocationPanel(
            latestReading: latestReading,
            deviceLiveProvider: deviceLiveProvider,
            safeZoneStatus: safeZoneStatus,
          ),
          SizedBox(height: scaled(16)),
          _buildBatteryPanel(child),
        ],
      ),
    );
  }

  Widget _buildChildHeader(ChildModel child) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InitialAvatar(
              label: child.name,
              radius: scaled(26),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F3C60),
              role: AvatarRole.child,
              childGender: child.gender,
            ),
            SizedBox(width: scaled(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(22),
                      fontWeight: FontWeight.w800,
                      color: _headingColor,
                    ),
                  ),
                  SizedBox(height: scaled(2)),
                  Text(
                    _buildAgeText(child.age),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(15),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2A567F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: scaled(14)),
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openChildSettings(child),
              borderRadius: BorderRadius.circular(scaled(18)),
              child: Ink(
                padding: EdgeInsets.symmetric(
                  horizontal: scaled(16),
                  vertical: scaled(8),
                ),
                decoration: BoxDecoration(
                  color: _panelColor,
                  borderRadius: BorderRadius.circular(scaled(18)),
                  border: Border.all(
                    color: const Color(0xFF7E8ACA),
                    width: scaled(1.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: _headingColor,
                      size: scaled(20),
                    ),
                    SizedBox(width: scaled(8)),
                    Text(
                      'إعدادات الطفل',
                      style: GoogleFonts.cairo(
                        fontSize: scaled(13),
                        fontWeight: FontWeight.w800,
                        color: _headingColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsPanel({
    required DeviceReading? latestReading,
    required DeviceLiveProvider deviceLiveProvider,
    required SafeZoneStatus safeZoneStatus,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return _buildSoftPanel(
      child: Stack(
        children: [
          Positioned(
            right: scaled(52),
            top: scaled(14),
            bottom: scaled(14),
            child: Container(
              width: scaled(1.5),
              color: const Color(0xFF1F2437),
            ),
          ),
          Positioned(
            right: scaled(16),
            top: scaled(14),
            child: Icon(
              Icons.favorite_border_rounded,
              color: const Color(0xFFFF6A6D),
              size: scaled(32),
            ),
          ),
          Positioned(
            left: scaled(20),
            bottom: scaled(16),
            child: Container(
              width: scaled(13),
              height: scaled(13),
              decoration: BoxDecoration(
                color: _buildStatusDotColor(
                  deviceLiveProvider,
                  safeZoneStatus,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              scaled(18),
              scaled(16),
              scaled(70),
              scaled(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildHeartRateDisplay(latestReading),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(17),
                    fontWeight: FontWeight.w800,
                    color: _headingColor,
                  ),
                ),
                SizedBox(height: scaled(8)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _buildSafetyStatusText(
                      latestReading,
                      deviceLiveProvider,
                      safeZoneStatus,
                    ),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(15),
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: _headingColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPanel({
    required DeviceReading? latestReading,
    required DeviceLiveProvider deviceLiveProvider,
    required SafeZoneStatus safeZoneStatus,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return _buildSoftPanel(
      padding: EdgeInsets.fromLTRB(
        scaled(16),
        scaled(16),
        scaled(16),
        scaled(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: const Color(0xFF103A6A),
                size: scaled(34),
              ),
              SizedBox(width: scaled(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الموقع الحالي',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(17),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF123A67),
                      ),
                    ),
                    SizedBox(height: scaled(2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: scaled(15),
                          height: scaled(15),
                          decoration: BoxDecoration(
                            color: _buildStatusDotColor(
                              deviceLiveProvider,
                              safeZoneStatus,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: scaled(8)),
                        Flexible(
                          child: Text(
                            _buildLocationNameText(
                              latestReading,
                              safeZoneStatus,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                              fontSize: scaled(15),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4D5363),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: scaled(16)),
          _buildMapPreview(latestReading),
        ],
      ),
    );
  }

  Widget _buildMapPreview(DeviceReading? latestReading) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final latitude = latestReading?.latitude;
    final longitude = latestReading?.longitude;
    final hasCoordinates = latitude != null && longitude != null;
    final center =
        hasCoordinates ? LatLng(latitude, longitude) : _fallbackMapCenter;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scaled(6)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scaled(28)),
        border: Border.all(
          color: _borderBlue,
          width: scaled(3.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x22000000),
            blurRadius: scaled(16),
            offset: Offset(0, scaled(8)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(scaled(22)),
        child: SizedBox(
          height: scaled(180),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: hasCoordinates ? 15 : 13,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'malaz_app',
                      ),
                      if (hasCoordinates)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: center,
                              width: scaled(42),
                              height: scaled(42),
                              child: Icon(
                                Icons.location_pin,
                                color: const Color(0xFFD24D21),
                                size: scaled(42),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (!hasCoordinates)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: Text(
                      'في انتظار الموقع المباشر',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(16),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4E5872),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryPanel(ChildModel child) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final status = _resolveBottomStatus(child);

    return Container(
      width: double.infinity,
      height: scaled(132),
      padding: EdgeInsets.fromLTRB(
        scaled(20),
        scaled(18),
        scaled(20),
        scaled(18),
      ),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(scaled(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.devices_outlined,
                  color: const Color(0xFF153C69),
                  size: scaled(40),
                ),
                SizedBox(width: scaled(10)),
                Icon(
                  Icons.bolt_rounded,
                  color: const Color(0xFFFFC300),
                  size: scaled(32),
                ),
                SizedBox(width: scaled(10)),
                Text(
                  '${status.batteryPercentage}%',
                  style: GoogleFonts.cairo(
                    fontSize: scaled(24),
                    fontWeight: FontWeight.w800,
                    color: _softGreen,
                    height: 1,
                  ),
                ),
                SizedBox(width: scaled(12)),
                Expanded(
                  child: Text(
                    status.batteryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(13),
                      fontWeight: FontWeight.w700,
                      color: _headingColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: scaled(46),
            padding: EdgeInsets.symmetric(horizontal: scaled(14)),
            decoration: BoxDecoration(
              color: const Color(0xFFC4C3EA),
              borderRadius: BorderRadius.circular(scaled(22)),
            ),
            child: Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.directions_run_rounded,
                      color: const Color(0xFF626873),
                      size: scaled(30),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scaled(40)),
                    child: Text(
                      status.activityText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(17),
                        fontWeight: FontWeight.w500,
                        color: _headingColor,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _BottomStatusPreset _resolveBottomStatus(ChildModel child) {
    final childKey = child.id.trim().isNotEmpty
        ? child.id.trim()
        : '${child.name}-${child.birthDate}-${child.deviceId}';

    return _bottomStatusByChild.putIfAbsent(
      childKey,
      () => _bottomStatusPresets[
          _bottomStatusRandom.nextInt(_bottomStatusPresets.length)],
    );
  }

  Widget _buildSoftPanel({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: padding ??
          EdgeInsets.fromLTRB(
            scaled(18),
            scaled(14),
            scaled(18),
            scaled(14),
          ),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(scaled(28)),
      ),
      child: child,
    );
  }

  Widget _buildStatusBanner({
    required String message,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: scaled(16),
        vertical: scaled(12),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(scaled(16)),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          fontSize: scaled(13),
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecentAlertsCard(List<DeviceAlert> alerts) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final visibleAlerts = alerts.take(3).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: scaled(16),
        vertical: scaled(14),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(scaled(18)),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آخر التنبيهات',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: scaled(13),
              fontWeight: FontWeight.w800,
              color: const Color(0xFFBF360C),
            ),
          ),
          SizedBox(height: scaled(8)),
          for (final alert in visibleAlerts)
            Padding(
              padding: EdgeInsets.only(bottom: scaled(6)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatReadingTimestamp(alert.receivedAt),
                    style: GoogleFonts.cairo(
                      fontSize: scaled(11),
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(width: scaled(10)),
                  Expanded(
                    child: Text(
                      alert.message,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(12),
                        color: const Color(0xFF6D4C41),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _buildAgeText(int age) {
    if (age == 1) {
      return 'سنة واحدة';
    }
    if (age == 2) {
      return 'سنتان';
    }
    return '$age سنوات';
  }

  Color _buildStatusDotColor(
    DeviceLiveProvider provider,
    SafeZoneStatus safeZoneStatus,
  ) {
    final reading = provider.latestReading;
    if (reading?.isSOSPressed == true || reading?.fallDetected == true) {
      return _dangerRed;
    }

    if (provider.isReadingStale) {
      return _warningOrange;
    }

    if (safeZoneStatus.isInside == false) {
      return _warningOrange;
    }

    if (safeZoneStatus.isInside == true) {
      return _successGreen;
    }

    switch (provider.connectionStatus) {
      case DeviceHubConnectionStatus.connected:
        return _successGreen;
      case DeviceHubConnectionStatus.connecting:
      case DeviceHubConnectionStatus.reconnecting:
        return _warningOrange;
      case DeviceHubConnectionStatus.disconnected:
        return const Color(0xFF9AA2B5);
    }
  }

  String _buildHeartRateDisplay(DeviceReading? reading) {
    final heartRate = reading?.heartRateBPM;
    if (heartRate == null) {
      return 'في انتظار النبض';
    }

    return '$heartRate نبضة/دقيقة';
  }

  String _buildSafetyStatusText(
    DeviceReading? reading,
    DeviceLiveProvider provider,
    SafeZoneStatus safeZoneStatus,
  ) {
    if (reading == null) {
      return provider.isConnecting
          ? 'جارٍ استقبال الحالة المباشرة'
          : 'في انتظار حالة الطفل';
    }

    if (reading.isSOSPressed) {
      return 'تم تفعيل زر الاستغاثة';
    }

    if (reading.fallDetected) {
      return 'تم رصد سقوط ويحتاج متابعة';
    }

    if (safeZoneStatus.isInside == false) {
      return 'الطفل خارج المنطقة الآمنة';
    }

    if (safeZoneStatus.isInside == true) {
      final speed = reading.speed;
      if (speed != null && speed > 0.1) {
        return 'الطفل في حالة حركة آمنة';
      }

      return 'الطفل داخل المنطقة الآمنة';
    }

    final speed = reading.speed;
    if (speed != null && speed > 0.1) {
      return 'الطفل في حالة حركة آمنة';
    }

    return 'الطفل ساكن حالياً';
  }

  String _buildLocationNameText(
    DeviceReading? reading,
    SafeZoneStatus safeZoneStatus,
  ) {
    if (safeZoneStatus.isInside == false) {
      return 'خارج المنطقة الآمنة';
    }

    final statusZoneName = safeZoneStatus.zoneName;
    if (statusZoneName != null && statusZoneName.trim().isNotEmpty) {
      return statusZoneName.trim();
    }

    final rawData = reading?.rawData;
    const candidateKeys = <String>[
      'locationName',
      'LocationName',
      'locationLabel',
      'LocationLabel',
      'address',
      'Address',
      'placeName',
      'PlaceName',
      'zoneName',
      'ZoneName',
      'safeZoneName',
      'SafeZoneName',
      'areaName',
      'AreaName',
    ];

    if (rawData != null) {
      for (final key in candidateKeys) {
        final value = rawData[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    if (safeZoneStatus.isInside == true) {
      return 'داخل المنطقة الآمنة';
    }

    final latitude = reading?.latitude;
    final longitude = reading?.longitude;
    if (latitude == null || longitude == null) {
      return 'في انتظار اسم الموقع';
    }

    return '${_formatCoordinate(latitude)}, ${_formatCoordinate(longitude)}';
  }

  // ignore: unused_element
  String _buildBatteryText(DeviceReading? reading) {
    final batteryLevel = reading?.batteryLevel;
    if (batteryLevel == null) {
      return '--';
    }

    return '$batteryLevel%';
  }

  // ignore: unused_element
  Color _buildBatteryColor(DeviceReading? reading) {
    final batteryLevel = reading?.batteryLevel;
    if (batteryLevel == null) {
      return const Color(0xFF7C8A9D);
    }
    if (batteryLevel <= 20) {
      return const Color(0xFFE45B5B);
    }
    if (batteryLevel <= 40) {
      return const Color(0xFFF0A93D);
    }
    return _softGreen;
  }

  // ignore: unused_element
  String _buildActivitySummaryText(DeviceReading? reading) {
    if (reading == null) {
      return 'في انتظار حالة النشاط';
    }

    if (reading.isSOSPressed) {
      return 'يحتاج إلى تدخل فوري';
    }

    if (reading.fallDetected) {
      return 'تم رصد سقوط';
    }

    final speed = reading.speed;
    if (speed != null && speed > 0.1) {
      return 'في حالة حركة الآن';
    }

    return 'ساكن حالياً';
  }

  String _formatCoordinate(double value) {
    return value.toStringAsFixed(5);
  }

  String _formatReadingTimestamp(DateTime value) {
    return DateFormat('HH:mm:ss').format(value.toLocal());
  }

  Widget _buildBottomNavBar(BuildContext context, ChildModel child) {
    final scale = _screenScale(context);

    return MainBottomNav(
      currentIndex: MainBottomNav.mapIndex,
      sizeScale: scale,
      onTap: (index) {
        switch (index) {
          case MainBottomNav.homeIndex:
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
              (route) => false,
            );
            break;
          case MainBottomNav.mapIndex:
            break;
          case MainBottomNav.reportsIndex:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChangeNotifierProvider<DeviceLiveProvider>.value(
                  value: _deviceLiveProvider,
                  child: ReportsScreen(child: child),
                ),
              ),
            );
            break;
          case MainBottomNav.chatIndex:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatbotScreen(child: child),
              ),
            );
            break;
          case MainBottomNav.settingsIndex:
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingScreen(),
              ),
              (route) => false,
            );
            break;
        }
      },
    );
  }
}
