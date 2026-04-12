import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/alert_setting_model.dart';
import '../models/child_mode.dart';
import '../providers/child_provider.dart';

class NotificationSettindScreen extends StatefulWidget {
  final ChildModel child;

  const NotificationSettindScreen({Key? key, required this.child})
      : super(key: key);

  @override
  State<NotificationSettindScreen> createState() =>
      _NotificationSettindScreenState();
}

class _NotificationSettindScreenState extends State<NotificationSettindScreen> {
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
      SnackBar(content: Text(errorMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'اعدادات التنبيه',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.registerTitle,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.registerTitle,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: BoxDecoration(
                  color: AppColors.registerTitle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 220,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      )
                    : !_didLoadSettings
                        ? SizedBox(
                            height: 220,
                            child: Center(
                              child: Text(
                                'تعذر تحميل إعدادات التنبيه',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              _buildToggleRow(
                                label: 'تنبيه خروج من منطقة الامان',
                                value: _safeZoneAlerted,
                                onChanged: _isSaving
                                    ? null
                                    : (v) {
                                        setState(() => _safeZoneAlerted = v);
                                      },
                              ),
                              const SizedBox(height: 28),
                              _buildToggleRow(
                                label: 'تنبيه نبض مرتفع',
                                value: _highHeartRateAlert,
                                onChanged: _isSaving
                                    ? null
                                    : (v) {
                                        setState(() => _highHeartRateAlert = v);
                                      },
                              ),
                              const SizedBox(height: 28),
                              _buildToggleRow(
                                label: 'تفعيل زر SOS',
                                value: _soSenableAlert,
                                onChanged: _isSaving
                                    ? null
                                    : (v) {
                                        setState(() => _soSenableAlert = v);
                                      },
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: _isSaving ? null : _saveSettings,
                                child: Container(
                                  width: 120,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'تم',
                                            style: GoogleFonts.cairo(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF6B9AB8),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.white24,
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}
