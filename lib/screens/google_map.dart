import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:malaz_app/models/child_mode.dart';

import '../constants/app_colors.dart';
import '../widgets/initial_avatar.dart';
import '../widgets/main_bottom_nav.dart';
import 'chatbot_screen.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'setting_screen.dart';

class MapSelectionResult {
  const MapSelectionResult({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

class GoogleMapScreen extends StatefulWidget {
  final ChildModel child;
  const GoogleMapScreen({super.key, required this.child});

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  static const LatLng _initialPosition = LatLng(30.0444, 31.2357);
  static const double _bottomNavOverlayHeight = 112;

  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isSearching = false;
  bool _isLocating = false;

  final int _currentNavIndex = MainBottomNav.mapIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case MainBottomNav.homeIndex: // الرئيسية
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
        break;
      case MainBottomNav.mapIndex: // المكان - انت فيه
        break;
      case MainBottomNav.reportsIndex: // التقارير
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReportsScreen(child: widget.child),
          ),
        );
        break;
      case MainBottomNav.chatIndex: // شات
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatbotScreen(child: widget.child),
          ),
        );
        break;
      case MainBottomNav.settingsIndex: // الاعدادات
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingScreen(),
          ),
        );
        break;
    }
  }

  Future<void> _searchPlace([String? query]) async {
    final searchQuery = (query ?? _searchController.text).trim();
    if (searchQuery.isEmpty) {
      _showMessage('من فضلك ادخل اسم المكان');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        <String, String>{
          'q': searchQuery,
          'format': 'jsonv2',
          'limit': '1',
        },
      );

      final response = await http.get(
        uri,
        headers: const <String, String>{
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _showMessage('تعذر البحث عن المكان حالياً');
        return;
      }

      final data = jsonDecode(response.body);
      if (data is! List || data.isEmpty) {
        _showMessage('لم يتم العثور على نتائج');
        return;
      }

      final firstResult = data.first;
      if (firstResult is! Map) {
        _showMessage('تعذر قراءة نتيجة البحث');
        return;
      }

      final latitude = double.tryParse(firstResult['lat']?.toString() ?? '');
      final longitude = double.tryParse(firstResult['lon']?.toString() ?? '');

      if (latitude == null || longitude == null) {
        _showMessage('تعذر قراءة احداثيات المكان');
        return;
      }

      final label =
          firstResult['display_name']?.toString().trim().isNotEmpty == true
              ? firstResult['display_name'].toString()
              : searchQuery;

      _updateSelectedLocation(
        LatLng(latitude, longitude),
        label: label,
      );
    } on TimeoutException {
      _showMessage('انتهت مهلة البحث. حاول مرة أخرى.');
    } catch (_) {
      _showMessage('حدث خطأ أثناء البحث عن المكان');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isLocating) {
      return;
    }

    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!kIsWeb) {
          await Geolocator.openLocationSettings();
        }
        _showMessage(
            'خدمات الموقع غير مفعلة. يرجى تفعيلها ثم المحاولة مرة أخرى.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('تم رفض إذن الوصول إلى الموقع.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!kIsWeb) {
          await Geolocator.openAppSettings();
        }
        _showMessage(
          kIsWeb
              ? 'إذن الموقع مرفوض. يرجى السماح بالوصول للموقع من إعدادات المتصفح.'
              : 'إذن الموقع مرفوض نهائياً. يرجى منحه من إعدادات التطبيق.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _updateSelectedLocation(
        LatLng(position.latitude, position.longitude),
        label:
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
      );
    } on TimeoutException {
      _showMessage('انتهت مهلة تحديد الموقع. حاول مرة أخرى.');
    } catch (_) {
      _showMessage('تعذر تحديد موقعك الحالي.');
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _updateSelectedLocation(
    LatLng position, {
    required String label,
  }) {
    setState(() {
      _selectedPosition = position;
      _selectedAddress = label;
      _searchController.text = label;
    });

    _mapController.move(position, 16);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final markers = _selectedPosition == null
        ? const <Marker>[]
        : <Marker>[
            Marker(
              point: _selectedPosition!,
              width: scaled(48),
              height: scaled(48),
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.location_pin,
                color: AppColors.registerTitle,
                size: scaled(48),
              ),
            ),
          ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialPosition,
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom |
                        InteractiveFlag.doubleTapDragZoom |
                        InteractiveFlag.scrollWheelZoom,
                  ),
                  onTap: (_, position) {
                    _updateSelectedLocation(
                      position,
                      label:
                          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'malaz_app',
                  ),
                  MarkerLayer(markers: markers),
                  const RichAttributionWidget(
                    showFlutterMapAttribution: false,
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  scaled(18),
                  scaled(12),
                  scaled(18),
                  0,
                ),
                child: _buildSearchBar(),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + scaled(108),
              right: scaled(18),
              child: _buildMapControlButton(
                icon: Icons.layers_outlined,
                onPressed: () {},
              ),
            ),
            Positioned(
              right: scaled(18),
              bottom: MediaQuery.paddingOf(context).bottom +
                  scaled(_bottomNavOverlayHeight) +
                  (_selectedAddress != null ? scaled(72) : scaled(14)),
              child: _buildLocationControlButton(),
            ),
            if (_selectedAddress != null)
              Positioned(
                left: scaled(20),
                right: scaled(20),
                bottom: MediaQuery.paddingOf(context).bottom +
                    scaled(_bottomNavOverlayHeight) +
                    scaled(8),
                child: _buildConfirmLocationButton(),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _buildBottomNavBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      constraints: BoxConstraints(minHeight: scaled(64)),
      padding: EdgeInsets.fromLTRB(
        scaled(18),
        scaled(8),
        scaled(10),
        scaled(8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaled(34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: scaled(18),
            offset: Offset(0, scaled(6)),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: const Color(0xFF2F80ED),
            size: scaled(32),
          ),
          SizedBox(width: scaled(8)),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _searchPlace,
              textInputAction: TextInputAction.search,
              enabled: !_isSearching,
              textAlign: TextAlign.left,
              style: GoogleFonts.cairo(
                fontSize: scaled(20),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF262A33),
              ),
              decoration: InputDecoration(
                hintText: 'Search here',
                hintStyle: GoogleFonts.cairo(
                  color: const Color(0xFF757575),
                  fontSize: scaled(20),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          SizedBox(width: scaled(8)),
          if (_isSearching)
            SizedBox(
              width: scaled(22),
              height: scaled(22),
              child: const CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.registerTitle,
              ),
            )
          else
            IconButton(
              tooltip: 'Search',
              onPressed: () => _searchPlace(),
              icon: Icon(
                Icons.keyboard_voice_rounded,
                color: const Color(0xFF4B4B4B),
                size: scaled(30),
              ),
            ),
          SizedBox(width: scaled(6)),
          InitialAvatar(
            label: widget.child.name,
            radius: scaled(23),
            backgroundColor: AppColors.registerTitle,
            foregroundColor: Colors.white,
            role: AvatarRole.child,
            childGender: widget.child.gender,
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: scaled(58),
      height: scaled(58),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaled(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: scaled(14),
            offset: Offset(0, scaled(4)),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: const Color(0xFF30343B),
          size: scaled(32),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLocationControlButton() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: scaled(70),
      height: scaled(70),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: scaled(16),
            offset: Offset(0, scaled(5)),
          ),
        ],
      ),
      child: IconButton(
        icon: _isLocating
            ? SizedBox(
                width: scaled(24),
                height: scaled(24),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFF30343B),
                ),
              )
            : Icon(
                Icons.navigation_outlined,
                color: const Color(0xFF30343B),
                size: scaled(34),
              ),
        onPressed: _isLocating ? null : _moveToCurrentLocation,
      ),
    );
  }

  Widget _buildConfirmLocationButton() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return ElevatedButton(
      onPressed: () {
        final selectedPosition = _selectedPosition;
        final selectedAddress = _selectedAddress;
        if (selectedPosition == null || selectedAddress == null) {
          return;
        }

        Navigator.pop(
          context,
          MapSelectionResult(
            latitude: selectedPosition.latitude,
            longitude: selectedPosition.longitude,
            label: selectedAddress,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.registerTitle,
        padding: EdgeInsets.symmetric(vertical: scaled(16)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaled(16)),
        ),
        elevation: scaled(8),
        shadowColor: Colors.black.withValues(alpha: 0.18),
      ),
      child: Text(
        'تأكيد الموقع',
        style: GoogleFonts.cairo(
          fontSize: scaled(16),
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final scale = _screenScale(context);

    return MainBottomNav(
      currentIndex: _currentNavIndex,
      onTap: _onNavTap,
      sizeScale: scale,
    );
  }
}
