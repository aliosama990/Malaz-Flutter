import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/child_mode.dart';

class NotificationSettindScreen extends StatefulWidget {
  final ChildModel child;

  const NotificationSettindScreen({Key? key, required this.child})
      : super(key: key);

  @override
  State<NotificationSettindScreen> createState() =>
      _NotificationSettindScreenState();
}

class _NotificationSettindScreenState extends State<NotificationSettindScreen> {
  bool _safeZoneAlert = true;
  bool _highHeartRateAlert = true;
  bool _sosAlert = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final id = widget.child.id; // ✅ key بـ id الطفل
    setState(() {
      _safeZoneAlert = prefs.getBool('${id}_safeZoneAlert') ?? true;
      _highHeartRateAlert = prefs.getBool('${id}_highHeartRateAlert') ?? true;
      _sosAlert = prefs.getBool('${id}_sosAlert') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final id = widget.child.id; // ✅ key بـ id الطفل
    await prefs.setBool('${id}_$key', value);
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
                child: Column(
                  children: [
                    _buildToggleRow(
                      label: 'تنبيه خروج من منطقة الامان',
                      value: _safeZoneAlert,
                      onChanged: (v) {
                        setState(() => _safeZoneAlert = v);
                        _saveSetting('safeZoneAlert', v);
                      },
                    ),
                    const SizedBox(height: 28),
                    _buildToggleRow(
                      label: 'تنبيه نبض مرتفع',
                      value: _highHeartRateAlert,
                      onChanged: (v) {
                        setState(() => _highHeartRateAlert = v);
                        _saveSetting('highHeartRateAlert', v);
                      },
                    ),
                    const SizedBox(height: 28),
                    _buildToggleRow(
                      label: 'تفعيل زر SOS',
                      value: _sosAlert,
                      onChanged: (v) {
                        setState(() => _sosAlert = v);
                        _saveSetting('sosAlert', v);
                      },
                    ),
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
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
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
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
