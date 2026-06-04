import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/screens/child_data_screen.dart';
import 'package:malaz_app/screens/home_screen.dart';
import 'package:malaz_app/screens/notification_setting_screen.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/child_mode.dart';
import '../providers/child_provider.dart';

class SettingChild extends StatelessWidget {
  final ChildModel child;

  const SettingChild({super.key, required this.child});

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  Future<void> _deleteChild(BuildContext context) async {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                'حذف الطفل',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.right,
              ),
              content: Text(
                'هل تريد حذف هذا الطفل؟',
                style: GoogleFonts.cairo(fontSize: scaled(14)),
                textAlign: TextAlign.right,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.cairo(
                      color: AppColors.registerTitle,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'حذف',
                    style: GoogleFonts.cairo(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    final didDelete =
        await context.read<ChildProvider>().deleteChildFromServer(child.id);

    if (!context.mounted) {
      return;
    }

    if (!didDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<ChildProvider>().errorMessage ??
                'حدث خطأ أثناء حذف الطفل',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final childProvider = context.watch<ChildProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: scaled(20),
                vertical: scaled(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'الاعدادات',
                    style: GoogleFonts.cairo(
                      fontSize: scaled(20),
                      fontWeight: FontWeight.bold,
                      color: AppColors.registerTitle,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_forward,
                        color: AppColors.registerTitle,
                        size: scaled(28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: scaled(20)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: scaled(20)),
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
                          builder: (context) => ChildDataSettingsScreen(
                            child: child,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: scaled(16)),
                  _buildSettingsCard(
                    context: context,
                    label: 'اعدادات التنبيه',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NotificationSettingScreen(child: child),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: scaled(16)),
                  _buildSettingsCard(
                    context: context,
                    label: 'حذف الطفل',
                    labelColor: Colors.red,
                    onTap: () {
                      if (childProvider.isLoading) {
                        return;
                      }

                      _deleteChild(context);
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
    Color? labelColor,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: scaled(56),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scaled(14)),
          border: Border.all(color: Colors.grey.shade300, width: scaled(1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: scaled(6),
              offset: Offset(0, scaled(2)),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaled(16)),
          child: Row(
            children: [
              Icon(
                Icons.keyboard_arrow_left,
                color: Colors.grey.shade400,
                size: scaled(22),
              ),
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: scaled(15),
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? AppColors.registerTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
