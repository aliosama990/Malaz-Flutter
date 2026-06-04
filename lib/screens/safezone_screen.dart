import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/child_mode.dart';
import '../models/safe_zone_model.dart';
import '../providers/safezone_provider.dart';
import '../widgets/network_error_state.dart';
import 'home_screen.dart';
import 'newsafezone_screen.dart';

class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({
    super.key,
    required this.child,
  });

  final ChildModel child;

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends State<SafeZonesScreen> {
  static const Color _backgroundColor = Color(0xFFF7F8FF);
  static const Color _textColor = Color(0xFF2C466D);
  static const Color _buttonColor = Color(0xFF6A68A6);
  static const Color _buttonBorderColor = Color(0xFF294B7B);
  static const Color _successGreen = Color(0xFF2FB05A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadZones();
    });
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  Future<void> _loadZones() async {
    try {
      await context.read<SafeZoneProvider>().fetchZonesForChild(
            widget.child.id,
          );
    } catch (_) {
      // Provider owns the user-facing error state.
    }
  }

  Future<void> _openAddSafeZone() async {
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
  }

  Future<void> _openEditSafeZone(SafeZoneModel zone) async {
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
  }

  Future<void> _handleBackPressed() async {
    final didPop = await Navigator.maybePop(context);
    if (didPop || !mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final safeZoneProvider = context.watch<SafeZoneProvider>();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              SizedBox(height: scaled(30)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: scaled(22)),
                  child: _buildBody(safeZoneProvider),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  scaled(22),
                  scaled(18),
                  scaled(22),
                  scaled(22),
                ),
                child: _buildAddButton(),
              ),
              SizedBox(height: scaled(18)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        scaled(22),
        scaled(28),
        scaled(22),
        0,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'المناطق الامنة',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: scaled(24),
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _handleBackPressed,
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: const Color(0xFF07335F),
                size: scaled(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SafeZoneProvider provider) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _buttonColor,
        ),
      );
    }

    if (provider.errorMessage != null && provider.zones.isEmpty) {
      return NetworkErrorState(
        title: 'تعذر تحميل المناطق الآمنة',
        onRetry: _loadZones,
        secondaryLabel: 'رجوع',
        onSecondary: _handleBackPressed,
      );
    }

    if (provider.zones.isEmpty) {
      return Center(
        child: Text(
          'لا توجد مناطق امان حالياً',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: scaled(17),
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
      );
    }

    final showOfflineBanner = provider.errorMessage != null;

    return RefreshIndicator(
      onRefresh: _loadZones,
      color: _buttonColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.zones.length + (showOfflineBanner ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: scaled(14)),
        itemBuilder: (context, index) {
          if (showOfflineBanner && index == 0) {
            return const OfflineBanner();
          }

          final zoneIndex = showOfflineBanner ? index - 1 : index;
          return _buildZoneCard(provider.zones[zoneIndex]);
        },
      ),
    );
  }

  Widget _buildZoneCard(SafeZoneModel zone) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openEditSafeZone(zone),
        borderRadius: BorderRadius.circular(scaled(28)),
        child: Ink(
          height: scaled(70),
          padding: EdgeInsets.symmetric(horizontal: scaled(18)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(scaled(22)),
            border: Border.all(
              color: const Color(0xFFDADADA),
              width: scaled(1.7),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: scaled(14),
                height: scaled(14),
                decoration: const BoxDecoration(
                  color: _successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: scaled(12)),
              Expanded(
                child: Text(
                  _zoneDisplayName(zone),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(18),
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Center(
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openAddSafeZone,
            borderRadius: BorderRadius.circular(scaled(26)),
            child: Ink(
              height: scaled(58),
              decoration: BoxDecoration(
                color: _buttonColor,
                borderRadius: BorderRadius.circular(scaled(26)),
                border: Border.all(
                  color: _buttonBorderColor,
                  width: scaled(2),
                ),
              ),
              child: Center(
                child: Text(
                  'اضافة منطقة امان جديد',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(17),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _zoneDisplayName(SafeZoneModel zone) {
    final name = zone.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    return 'منطقة امان';
  }
}
