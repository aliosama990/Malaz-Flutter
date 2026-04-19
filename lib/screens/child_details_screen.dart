import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:malaz_app/screens/setting_child_screen.dart';
import 'package:malaz_app/screens/setting_screen.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/child_mode.dart';
import '../models/device_live_models.dart';
import '../providers/child_provider.dart';
import '../providers/device_live_provider.dart';
import '../services/device_hub_service.dart';
import '../widgets/initial_avatar.dart';
import 'chatbot_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'safezone_screen.dart';

class ChildDetailsScreen extends StatefulWidget {
  final ChildModel child;

  const ChildDetailsScreen({super.key, required this.child});

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
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

  void _subscribeToChildDevice(ChildModel child) {
    unawaited(_deviceLiveProvider.connectToDevice(child.deviceId));
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

              return Scaffold(
                backgroundColor: Colors.white,
                body: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SettingChild(child: child),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.settings,
                                color: AppColors.registerTitle,
                                size: 28,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_forward,
                                color: AppColors.registerTitle,
                                size: 28,
                                weight: 700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (childProvider.errorMessage != null)
                        _buildStatusBanner(
                          message: childProvider.errorMessage!,
                          backgroundColor: const Color(0xFFFFF3F3),
                          borderColor: const Color(0xFFFFCDD2),
                          textColor: Colors.red.shade700,
                        ),
                      if (deviceLiveProvider.errorMessage != null &&
                          deviceLiveProvider.errorMessage !=
                              childProvider.errorMessage)
                        _buildStatusBanner(
                          message: deviceLiveProvider.errorMessage!,
                          backgroundColor: const Color(0xFFFFF8E1),
                          borderColor: const Color(0xFFFFE082),
                          textColor: const Color(0xFF8D6E63),
                        ),
                      if (latestAlert != null)
                        _buildStatusBanner(
                          message: 'تنبيه مباشر: ${latestAlert.message}',
                          backgroundColor: const Color(0xFFFFF3E0),
                          borderColor: const Color(0xFFFFB74D),
                          textColor: const Color(0xFFBF360C),
                        ),
                      if (deviceLiveProvider.isReadingStale &&
                          latestReading != null)
                        _buildStatusBanner(
                          message:
                              'لم تصل قراءات جديدة منذ ${_formatReadingTimestamp(latestReading.receivedAt)} وقد تكون البيانات قديمة.',
                          backgroundColor: const Color(0xFFFFF8E1),
                          borderColor: const Color(0xFFFFCC80),
                          textColor: const Color(0xFFE65100),
                        ),
                      if (recentAlerts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          child: _buildRecentAlertsCard(recentAlerts),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.05,
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.registerTitle,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.registerTitle
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              child.name,
                                              style: GoogleFonts.cairo(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              '${child.age} سنوات',
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _buildConnectionStatusText(
                                                deviceLiveProvider,
                                                child,
                                              ),
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                color:
                                                    _buildConnectionStatusColor(
                                                  deviceLiveProvider,
                                                  child,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _buildLastUpdatedText(
                                                deviceLiveProvider,
                                              ),
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                color: _buildLastUpdatedColor(
                                                  deviceLiveProvider,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        InitialAvatar(
                                          label: child.name,
                                          radius: 28,
                                          backgroundColor:
                                              Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                          foregroundColor: Colors.white,
                                          role: AvatarRole.child,
                                          childGender: child.gender,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _buildGreyCard(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                _buildHeartRateText(
                                                  latestReading,
                                                ),
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.registerTitle,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(
                                                Icons.favorite_outline,
                                                color: AppColors.registerTitle,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                _buildPrimaryStatusText(
                                                  deviceLiveProvider,
                                                ),
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.registerTitle,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: _buildStatusDotColor(
                                                    deviceLiveProvider,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildGreyCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                'الموقع الحالي',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.registerTitle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.location_on,
                                                color: AppColors.registerTitle,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _buildLocationText(
                                                    latestReading,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: _buildStatusDotColor(
                                                    deviceLiveProvider,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              height: 160,
                                              width: double.infinity,
                                              color: const Color(0xFFCFD8DC),
                                              child: const Icon(
                                                Icons.map,
                                                size: 60,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildGreyCard(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                _buildBatteryText(
                                                  latestReading,
                                                ),
                                                style: GoogleFonts.cairo(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.registerTitle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.bolt,
                                                color: Colors.amber,
                                                size: 22,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                _buildMovementText(
                                                  latestReading,
                                                ),
                                                textAlign: TextAlign.right,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.registerTitle,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(
                                                Icons.directions_run,
                                                color: AppColors.registerTitle,
                                                size: 22,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomNavBar(context, child),
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

  Widget _buildStatusBanner({
    required String message,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          message,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAlertsCard(List<DeviceAlert> alerts) {
    final visibleAlerts = alerts.take(3).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'آخر التنبيهات',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFBF360C),
            ),
          ),
          const SizedBox(height: 8),
          for (final alert in visibleAlerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatReadingTimestamp(alert.receivedAt),
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alert.message,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
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

  Widget _buildGreyCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD6DAE0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  String _buildConnectionStatusText(
    DeviceLiveProvider provider,
    ChildModel child,
  ) {
    if (child.deviceId.trim().isEmpty) {
      return 'لا يوجد جهاز مرتبط بهذا الطفل';
    }

    switch (provider.connectionStatus) {
      case DeviceHubConnectionStatus.connected:
        return 'متصل بالجهاز ${child.deviceId}';
      case DeviceHubConnectionStatus.connecting:
        return 'جارٍ الاتصال بالجهاز ${child.deviceId}';
      case DeviceHubConnectionStatus.reconnecting:
        return 'جارٍ إعادة الاتصال بالجهاز ${child.deviceId}';
      case DeviceHubConnectionStatus.disconnected:
        return 'غير متصل بالجهاز ${child.deviceId}';
    }
  }

  Color _buildConnectionStatusColor(
    DeviceLiveProvider provider,
    ChildModel child,
  ) {
    if (child.deviceId.trim().isEmpty) {
      return Colors.orange.shade100;
    }

    switch (provider.connectionStatus) {
      case DeviceHubConnectionStatus.connected:
        return Colors.green.shade100;
      case DeviceHubConnectionStatus.connecting:
      case DeviceHubConnectionStatus.reconnecting:
        return Colors.orange.shade100;
      case DeviceHubConnectionStatus.disconnected:
        return Colors.red.shade100;
    }
  }

  Color _buildStatusDotColor(DeviceLiveProvider provider) {
    final reading = provider.latestReading;
    if (reading?.isSOSPressed == true || reading?.fallDetected == true) {
      return Colors.red;
    }

    if (provider.isReadingStale) {
      return Colors.orange;
    }

    switch (provider.connectionStatus) {
      case DeviceHubConnectionStatus.connected:
        return Colors.green;
      case DeviceHubConnectionStatus.connecting:
      case DeviceHubConnectionStatus.reconnecting:
        return Colors.orange;
      case DeviceHubConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String _buildLastUpdatedText(DeviceLiveProvider provider) {
    final lastUpdated = provider.lastReadingReceivedAt;
    if (lastUpdated == null) {
      return 'آخر تحديث: لا توجد قراءات بعد';
    }

    final timestamp = _formatReadingTimestamp(lastUpdated);
    if (provider.isReadingStale) {
      return 'آخر تحديث: $timestamp - البيانات قديمة';
    }

    return 'آخر تحديث: $timestamp';
  }

  Color _buildLastUpdatedColor(DeviceLiveProvider provider) {
    if (provider.lastReadingReceivedAt == null) {
      return Colors.white70;
    }

    if (provider.isReadingStale) {
      return Colors.orange.shade100;
    }

    return Colors.white70;
  }

  String _buildHeartRateText(DeviceReading? reading) {
    final heartRate = reading?.heartRateBPM;
    if (heartRate == null) {
      return 'في انتظار نبض القلب';
    }

    return '$heartRate نبضة/دقيقة';
  }

  String _buildPrimaryStatusText(DeviceLiveProvider provider) {
    final reading = provider.latestReading;
    if (reading == null) {
      return 'في انتظار قراءات الجهاز...';
    }

    if (reading.isSOSPressed) {
      return 'تم الضغط على زر الاستغاثة';
    }

    if (reading.fallDetected) {
      return 'تم رصد سقوط';
    }

    final oxygenLevel = reading.oxygenLevel;
    if (oxygenLevel != null) {
      return 'نسبة الأكسجين $oxygenLevel%';
    }

    return 'الطفل في حالة حركة آمنة';
  }

  String _buildLocationText(DeviceReading? reading) {
    final latitude = reading?.latitude;
    final longitude = reading?.longitude;
    if (latitude == null || longitude == null) {
      return 'في انتظار الموقع الحالي';
    }

    return '${_formatCoordinate(latitude)}, ${_formatCoordinate(longitude)}';
  }

  String _buildBatteryText(DeviceReading? reading) {
    final batteryLevel = reading?.batteryLevel;
    if (batteryLevel == null) {
      return 'في انتظار مستوى البطارية';
    }

    return '$batteryLevel%';
  }

  String _buildMovementText(DeviceReading? reading) {
    if (reading == null) {
      return 'في انتظار حالة الحركة';
    }

    if (reading.isSOSPressed) {
      return 'تم تفعيل زر الاستغاثة';
    }

    if (reading.fallDetected) {
      return 'تم رصد سقوط ويحتاج متابعة';
    }

    final speed = reading.speed;
    if (speed != null && speed > 0.1) {
      return 'الطفل يتحرك بسرعة ${_formatSpeed(speed)} كم/س';
    }

    return 'الطفل ساكن حالياً';
  }

  String _formatCoordinate(double value) {
    return value.toStringAsFixed(5);
  }

  String _formatReadingTimestamp(DateTime value) {
    return DateFormat('HH:mm:ss').format(value.toLocal());
  }

  String _formatSpeed(double value) {
    final roundedValue = value.toStringAsFixed(1);
    if (roundedValue.endsWith('.0')) {
      return roundedValue.substring(0, roundedValue.length - 2);
    }

    return roundedValue;
  }

  Widget _buildBottomNavBar(BuildContext context, ChildModel child) {
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
            color: Colors.black.withValues(alpha: 0.06),
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
            final isActive = index == 4;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                switch (index) {
                  case 4: //
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                    break;
                  case 3: //
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SafeZonesScreen(child: child),
                      ),
                    );
                    break;
                  case 2: //
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsScreen(child: child),
                      ),
                    );
                    break;
                  case 1: //
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatbotScreen(child: child),
                      ),
                    );
                    break;
                  case 0: //
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
