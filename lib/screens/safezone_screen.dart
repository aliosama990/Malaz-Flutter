import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/models/child_mode.dart';
import 'package:malaz_app/models/safe_zone_model.dart';
import 'package:malaz_app/providers/safezone_provider.dart';
import 'package:malaz_app/screens/newsafezone_screen.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import 'child_details_screen.dart';

class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({
    Key? key,
    required this.child,
  }) : super(key: key);

  final ChildModel child;

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends State<SafeZonesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadZones();
    });
  }

  Future<void> _loadZones() async {
    try {
      await context
          .read<SafeZoneProvider>()
          .fetchZonesForChild(widget.child.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeZoneProvider = context.watch<SafeZoneProvider>();

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
                    Expanded(child: _buildBody(safeZoneProvider)),
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

  Widget _buildBody(SafeZoneProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.zones.isEmpty) {
      return Center(
        child: Text(
          provider.errorMessage!,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: AppColors.registerTitle,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (provider.zones.isEmpty) {
      return Center(
        child: Text(
          'لا توجد مناطق امان حالياً',
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.registerTitle,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadZones,
      child: ListView.builder(
        itemCount: provider.zones.length,
        itemBuilder: (context, index) {
          return _buildZoneCard(provider.zones[index]);
        },
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

  Widget _buildZoneCard(SafeZoneModel zone) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewSafeZoneScreen(
              child: widget.child,
              existingZone: zone,
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        await _loadZones();
      },
      child: Container(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      zone.name,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.registerTitle,
                      ),
                    ),
                    Text(
                      zone.typeDisplayName,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewSafeZoneScreen(child: widget.child),
            ),
          );

          if (!mounted) {
            return;
          }

          await _loadZones();
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
