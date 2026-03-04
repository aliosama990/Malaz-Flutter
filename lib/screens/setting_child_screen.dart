import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/screens/child_data_screen.dart';
import 'package:malaz_app/screens/notification_setting_screen.dart';
import '../constants/app_colors.dart';
import '../models/child_mode.dart';

class SettingChild extends StatelessWidget {
  final ChildModel child;

  const SettingChild({Key? key, required this.child}) : super(key: key);

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
                    'الاعدادات',
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSettingsCard(
                    context: context,
                    label: 'اعدادات البيانات',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // ✅ بعت الطفل الصح
                          builder: (context) =>
                              ChildDataSettingsScreen(child: child),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsCard(
                    context: context,
                    label: 'اعدادات التنبيه',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NotificationSettindScreen(child: child),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.keyboard_arrow_left,
                color: Colors.grey.shade400,
                size: 22,
              ),
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.registerTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
