import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/screens/setting_child_screen.dart';
import 'package:malaz_app/screens/setting_screen.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/child_mode.dart';
import '../providers/child_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _childFuture = Provider.of<ChildProvider>(
      context,
      listen: false,
    ).fetchChildById(widget.child.id);
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();

    return FutureBuilder<ChildModel?>(
      future: _childFuture,
      initialData: widget.child,
      builder: (context, snapshot) {
        final child = snapshot.data ?? widget.child;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingChild(child: child),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Text(
                        childProvider.errorMessage!,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.registerTitle,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.registerTitle.withOpacity(0.3),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
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
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  InitialAvatar(
                                    label: child.name,
                                    radius: 28,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.18),
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
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '92 نبضه/دقيقه',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: AppColors.registerTitle,
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
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'الطفل في حالة حركه آمنه',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: AppColors.registerTitle,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'الموقع الحالي',
                                          style: GoogleFonts.cairo(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.registerTitle,
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
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'المدرسه',
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
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
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '50%',
                                          style: GoogleFonts.cairo(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.registerTitle,
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
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'ساكن لمدة ساعه',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: AppColors.registerTitle,
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
