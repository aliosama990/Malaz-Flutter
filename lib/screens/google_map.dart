import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:malaz_app/models/child_mode.dart';
import '../constants/app_colors.dart';
import 'child_details_screen.dart';
import 'notifications_screen.dart';
import 'chatbot_screen.dart';
import 'safezone_screen.dart';
import 'setting_screen.dart';

class GoogleMapScreen extends StatefulWidget {
  final ChildModel child;
  const GoogleMapScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  GoogleMapController? _mapController;

  static const LatLng _initialPosition = LatLng(30.0444, 31.2357);

  LatLng? _selectedPosition;
  String? _selectedAddress;
  final Set<Marker> _markers = {};

  int _currentNavIndex = 3;

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
            builder: (context) => SettingScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _initialPosition,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: _markers,
                    onTap: (LatLng position) {
                      setState(() {
                        _selectedPosition = position;
                        _selectedAddress =
                            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
                        _markers.clear();
                        _markers.add(
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: position,
                            infoWindow:
                                const InfoWindow(title: 'المكان المحدد'),
                          ),
                        );
                      });
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
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
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mic,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          const Expanded(
                            child: TextField(
                              textAlign: TextAlign.left,
                              decoration: InputDecoration(
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
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.registerTitle,
                            child: Text(
                              widget.child.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                            color: Colors.black.withOpacity(0.12),
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
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.navigation_outlined,
                            color: Colors.black54),
                        onPressed: () {},
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
                          Navigator.pop(context, _selectedAddress);
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
