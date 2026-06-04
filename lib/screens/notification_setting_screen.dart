import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/alert_setting_model.dart';
import '../models/child_mode.dart';
import '../providers/child_provider.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({
    super.key,
    required this.child,
  });

  final ChildModel child;

  @override
  State<NotificationSettingScreen> createState() =>
      _NotificationSettindScreenState();
}

class NotificationSettindScreen extends NotificationSettingScreen {
  const NotificationSettindScreen({
    super.key,
    required super.child,
  });
}

class _NotificationSettindScreenState extends State<NotificationSettingScreen> {
  static const Color _screenBackground = Color(0xFFFDFDFF);
  static const Color _headerStart = Color(0xFFCCD1F0);
  static const Color _headerEnd = Color(0xFFC1C6E8);
  static const Color _cardBackground = Color(0xFFC5C8EE);
  static const Color _primaryTextColor = Color(0xFF355D84);
  static const Color _primaryButtonColor = Color(0xFF6C6CA8);

  bool _safeZoneAlerted = true;
  bool _highHeartRateAlert = true;
  bool _soSenableAlert = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _didLoadSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  Future<void> _loadSettings() async {
    final childProvider = context.read<ChildProvider>();
    final alertSetting = await childProvider.fetchAlertSetting(widget.child.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _didLoadSettings = alertSetting != null;
      if (alertSetting != null) {
        _safeZoneAlerted = alertSetting.safeZoneAlerted;
        _highHeartRateAlert = alertSetting.highHeartRateAlert;
        _soSenableAlert = alertSetting.soSenableAlert;
      }
    });

    _showProviderErrorIfAny(childProvider);
  }

  Future<void> _saveSettings() async {
    if (!_didLoadSettings || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final childProvider = context.read<ChildProvider>();
    final didSave = await childProvider.updateAlertSetting(
      widget.child.id,
      AlertSettingModel(
        safeZoneAlerted: _safeZoneAlerted,
        highHeartRateAlert: _highHeartRateAlert,
        soSenableAlert: _soSenableAlert,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (didSave) {
      Navigator.pop(context);
      return;
    }

    _showProviderErrorIfAny(childProvider);
  }

  void _showProviderErrorIfAny(ChildProvider childProvider) {
    final errorMessage = childProvider.errorMessage;
    if (errorMessage == null || errorMessage.trim().isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Scaffold(
      backgroundColor: _screenBackground,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBlurredHeader(),
            Transform.translate(
              offset: Offset(0, scaled(-18)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scaled(18)),
                child: _buildSettingsCard(),
              ),
            ),
            const Spacer(),
            _buildDoneButton(),
            SizedBox(height: scaled(28)),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredHeader() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final topPadding = MediaQuery.paddingOf(context).top;
    final headerHeight = topPadding + scaled(176);

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(scaled(32)),
          bottomRight: Radius.circular(scaled(32)),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_headerStart, _headerEnd],
                  ),
                ),
              ),
            ),
            Positioned(
              left: scaled(70),
              top: topPadding + scaled(82),
              child: _buildHeaderBlurBlob(
                size: scaled(34),
                color: const Color(0xFFFF6C75),
                blur: scaled(16),
                opacity: 0.70,
              ),
            ),
            Positioned(
              left: scaled(28),
              top: topPadding + scaled(74),
              child: _buildHeaderBlurBlob(
                size: scaled(92),
                color: Colors.white,
                blur: scaled(20),
                opacity: 0.22,
              ),
            ),
            Positioned(
              right: scaled(48),
              top: topPadding + scaled(64),
              child: _buildHeaderBlurBlob(
                size: scaled(52),
                color: const Color(0xFFE7D6C5),
                blur: scaled(18),
                opacity: 0.50,
              ),
            ),
            Positioned(
              right: scaled(102),
              top: topPadding + scaled(22),
              child: _buildHeaderBlurBlob(
                size: scaled(22),
                color: const Color(0xFF5E5A73),
                blur: scaled(10),
                opacity: 0.42,
              ),
            ),
            Positioned(
              right: scaled(126),
              top: topPadding + scaled(10),
              child: _buildHeaderBlurBlob(
                size: scaled(12),
                color: const Color(0xFF646176),
                blur: scaled(6),
                opacity: 0.46,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: scaled(-4),
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
                          Colors.white.withValues(alpha: 0.02),
                          Colors.white.withValues(alpha: 0.54),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: topPadding + scaled(28),
              right: scaled(22),
              child: _buildHeaderBackButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBlurBlob({
    required double size,
    required Color color,
    required double blur,
    required double opacity,
  }) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }

  Widget _buildHeaderBackButton() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return ClipRRect(
      borderRadius: BorderRadius.circular(scaled(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: scaled(12),
          sigmaY: scaled(12),
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: scaled(44),
              height: scaled(44),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(scaled(24)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: _primaryTextColor,
                size: scaled(28),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        scaled(20),
        scaled(20),
        scaled(20),
        scaled(28),
      ),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(scaled(32)),
      ),
      child: Column(
        children: [
          Text(
            'اعدادات التنبيه',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: scaled(24),
              fontWeight: FontWeight.w800,
              color: _primaryTextColor,
              height: 1.2,
            ),
          ),
          SizedBox(height: scaled(28)),
          if (_isLoading)
            SizedBox(
              height: scaled(120),
              child: const Center(
                child: CircularProgressIndicator(
                  color: _primaryButtonColor,
                ),
              ),
            )
          else if (!_didLoadSettings)
            SizedBox(
              height: scaled(120),
              child: Center(
                child: Text(
                  'تعذر تحميل إعدادات التنبيه',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(15),
                    fontWeight: FontWeight.w700,
                    color: _primaryTextColor,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                _buildToggleRow(
                  label: 'تنبيه خروج من منطقة الامان',
                  value: _safeZoneAlerted,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() => _safeZoneAlerted = value);
                        },
                ),
                SizedBox(height: scaled(22)),
                _buildToggleRow(
                  label: 'تنبيه نبض مرتفع',
                  value: _highHeartRateAlert,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() => _highHeartRateAlert = value);
                        },
                ),
                SizedBox(height: scaled(22)),
                _buildToggleRow(
                  label: 'تفعيل زر sos',
                  value: _soSenableAlert,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() => _soSenableAlert = value);
                        },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Center(
      child: SizedBox(
        width: scaled(220),
        child: Container(
          decoration: BoxDecoration(
            color: _primaryButtonColor,
            borderRadius: BorderRadius.circular(scaled(28)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A4D4A8E),
                blurRadius: scaled(18),
                offset: Offset(0, scaled(10)),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(scaled(28)),
              onTap: _isLoading || !_didLoadSettings || _isSaving
                  ? null
                  : _saveSettings,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: scaled(12)),
                child: Center(
                  child: _isSaving
                      ? SizedBox(
                          width: scaled(24),
                          height: scaled(24),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'تم',
                          style: GoogleFonts.cairo(
                            fontSize: scaled(18),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Row(
      textDirection: TextDirection.ltr,
      children: [
        Transform.scale(
          scale: 0.96 * scale,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _primaryButtonColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _primaryButtonColor.withValues(alpha: 0.42),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
        Container(
          width: scaled(3),
          height: scaled(40),
          margin: EdgeInsets.only(left: scaled(12), right: scaled(22)),
          color: const Color(0xFFACA8A6),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: scaled(16),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF07335F),
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
