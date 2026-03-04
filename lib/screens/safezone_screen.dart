import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/models/child_mode.dart';
import 'package:malaz_app/screens/newsafezone_screen.dart';
import '../constants/app_colors.dart';
import 'child_details_screen.dart';

class SafeZonesScreen extends StatefulWidget {
  final ChildModel child;
  final Map<String, dynamic>? newZone;

  const SafeZonesScreen({
    Key? key,
    required this.child,
    this.newZone,
  }) : super(key: key);

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends State<SafeZonesScreen> {
  late List<Map<String, dynamic>> safeZones;

  @override
  void initState() {
    super.initState();

    safeZones = [
      {'name': 'المدرسه', 'isActive': true},
      {'name': 'المنزل', 'isActive': true},
      {'name': 'النادي', 'isActive': true},
    ];

    if (widget.newZone != null) {
      safeZones.add(widget.newZone!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ...safeZones.map((zone) => _buildZoneCard(zone)).toList(),
                    const SizedBox(height: 20),
                    _buildAddButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'المناطق الامنه',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.registerTitle,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChildDetailsScreen(child: widget.child),
                  ),
                );
              },
              icon: const Icon(
                Icons.arrow_forward,
                color: AppColors.registerTitle,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFFBDBDBD),
            size: 16,
          ),
          Row(
            children: [
              Text(
                zone['name'],
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.registerTitle,
                ),
              ),
              const SizedBox(width: 10),
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
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewSafeZoneScreen(child: widget.child),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.registerTitle,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'اضافة منطقة امان جديدة',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '+',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
