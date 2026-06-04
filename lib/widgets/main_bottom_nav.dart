import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainBottomNav extends StatelessWidget {
  static const int homeIndex = 0;
  static const int mapIndex = 1;
  static const int reportsIndex = 2;
  static const int chatIndex = 3;
  static const int settingsIndex = 4;

  const MainBottomNav({
    super.key,
    required this.onTap,
    this.currentIndex,
    this.sizeScale = 1,
  });

  final ValueChanged<int> onTap;
  final int? currentIndex;
  final double sizeScale;

  @override
  Widget build(BuildContext context) {
    double scaled(double value) => value * sizeScale;

    const navItems = <_MainNavItem>[
      _MainNavItem(
        icon: Icons.home_outlined,
        label: 'الرئيسية',
      ),
      _MainNavItem(
        icon: Icons.location_on_outlined,
        label: 'المكان',
      ),
      _MainNavItem(
        icon: Icons.auto_graph_rounded,
        label: 'التقارير',
      ),
      _MainNavItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'شات',
      ),
      _MainNavItem(
        icon: Icons.settings_outlined,
        label: 'الإعدادات',
      ),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(scaled(16), 0, scaled(16), scaled(14)),
      padding: EdgeInsets.symmetric(
        horizontal: scaled(10),
        vertical: scaled(11),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF6D69A9),
        borderRadius: BorderRadius.circular(scaled(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x29655BA0),
            blurRadius: scaled(20),
            offset: Offset(0, scaled(10)),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(navItems.length, (index) {
            final navItem = navItems[index];
            final isActive = currentIndex == index;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      navItem.icon,
                      size: scaled(24),
                      color: isActive ? const Color(0xFF0A3B71) : Colors.white,
                    ),
                    SizedBox(height: scaled(5)),
                    Text(
                      navItem.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(10.5),
                        fontWeight:
                            isActive ? FontWeight.w800 : FontWeight.w600,
                        color:
                            isActive ? const Color(0xFF0A3B71) : Colors.white,
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

class _MainNavItem {
  const _MainNavItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
