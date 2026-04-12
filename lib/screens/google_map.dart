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
import 'chatbot_screen.dart';
import 'child_details_screen.dart';
import 'notifications_screen.dart';
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

  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isSearching = false;
  bool _isLocating = false;

  final int _currentNavIndex = 3;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 4: // الرئيسية
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChildDetailsScreen(child: widget.child),
          ),
        );
        break;
      case 3: // المكان - انت فيه
        break;
      case 2: // التقارير
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationsScreen(child: widget.child),
          ),
        );
        break;
      case 1: // شات
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatbotScreen(child: widget.child),
          ),
        );
        break;
      case 0: // الاعدادات
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
    final markers = _selectedPosition == null
        ? const <Marker>[]
        : <Marker>[
            Marker(
              point: _selectedPosition!,
              width: 48,
              height: 48,
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.location_pin,
                color: AppColors.registerTitle,
                size: 48,
              ),
            ),
          ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
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

                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _searchPlace,
                              textInputAction: TextInputAction.search,
                              enabled: !_isSearching,
                              textAlign: TextAlign.left,
                              decoration: const InputDecoration(
                                hintText: 'Search here',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_isSearching)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.registerTitle,
                              ),
                            )
                          else
                            IconButton(
                              onPressed: () => _searchPlace(),
                              icon: const Icon(
                                Icons.arrow_forward,
                                color: AppColors.registerTitle,
                                size: 20,
                              ),
                            ),
                          InitialAvatar(
                            label: widget.child.name,
                            radius: 16,
                            backgroundColor: AppColors.registerTitle,
                            foregroundColor: Colors.white,
                            role: AvatarRole.child,
                            childGender: widget.child.gender,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 80,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.layers_outlined,
                            color: Colors.black54),
                        onPressed: () {},
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: _selectedAddress != null ? 100 : 20,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: _isLocating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black54,
                                ),
                              )
                            : const Icon(Icons.navigation_outlined,
                                color: Colors.black54),
                        onPressed: _isLocating ? null : _moveToCurrentLocation,
                      ),
                    ),
                  ),

                  // ✅ زرار تأكيد الموقع لما يختار مكان
                  if (_selectedAddress != null)
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: ElevatedButton(
                        onPressed: () {
                          final selectedPosition = _selectedPosition;
                          final selectedAddress = _selectedAddress;
                          if (selectedPosition == null ||
                              selectedAddress == null) {
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'تأكيد الموقع',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ✅ Navbar الخاص بالطفل
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
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
            color: Colors.black.withValues(alpha: 0.06),
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
            final isActive = _currentNavIndex == index;
            return GestureDetector(
              onTap: () => _onNavTap(index),
              behavior: HitTestBehavior.opaque,
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
