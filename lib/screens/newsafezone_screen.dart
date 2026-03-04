import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/models/child_mode.dart';
import 'package:malaz_app/screens/google_map.dart';
import '../constants/app_colors.dart';
import 'safezone_screen.dart';

class NewSafeZoneScreen extends StatefulWidget {
  final ChildModel child;
  const NewSafeZoneScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<NewSafeZoneScreen> createState() => _NewSafeZoneScreenState();
}

class _NewSafeZoneScreenState extends State<NewSafeZoneScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedLocation;

  bool _nameError = false;
  bool _locationError = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapScreen(child: widget.child),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _selectedLocation = result;
        _locationError = false;
      });
    }
  }

  void _addSafeZone() {
    final name = _nameController.text.trim();

    setState(() {
      _nameError = name.isEmpty;
      _locationError = _selectedLocation == null;
    });

    if (_nameError || _locationError) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SafeZonesScreen(
          child: widget.child,
          newZone: {
            'name': name,
            'location': _selectedLocation,
            'isActive': true,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'اسم المكان',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.registerTitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        color: AppColors.registerTitle,
                      ),
                      onChanged: (val) {
                        if (_nameError && val.isNotEmpty) {
                          setState(() => _nameError = false);
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _nameError
                                ? Colors.red
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _nameError
                                ? Colors.red
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _nameError
                                ? Colors.red
                                : AppColors.registerTitle,
                          ),
                        ),
                      ),
                    ),
                    if (_nameError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'من فضلك ادخل اسم المكان',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'اختر موقعك',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.registerTitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openMap,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _locationError
                                ? Colors.red
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _selectedLocation ?? 'الموقع',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                color: _selectedLocation != null
                                    ? AppColors.registerTitle
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on_outlined,
                              color: _selectedLocation != null
                                  ? AppColors.registerTitle
                                  : Colors.grey,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_locationError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'من فضلك اختر الموقع على الخريطة',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addSafeZone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.registerTitle,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'اضف موقعك',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
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
            'اضف مواقع الامان',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
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
    );
  }
}
