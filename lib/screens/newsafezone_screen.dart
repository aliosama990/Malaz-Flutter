import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/child_mode.dart';
import '../models/safe_zone_model.dart';
import '../providers/safezone_provider.dart';
import '../services/api_service.dart';
import '../utils/user_error_messages.dart';
import 'google_map.dart';

class NewSafeZoneScreen extends StatefulWidget {
  const NewSafeZoneScreen({
    super.key,
    required this.child,
    this.existingZone,
  });

  final ChildModel child;
  final SafeZoneModel? existingZone;

  @override
  State<NewSafeZoneScreen> createState() => _NewSafeZoneScreenState();
}

class _NewSafeZoneScreenState extends State<NewSafeZoneScreen> {
  static const Color _backgroundColor = Color(0xFFF7F8FF);
  static const Color _textColor = Color(0xFF2C5A7D);
  static const Color _titleColor = Color(0xFF07335F);
  static const Color _buttonColor = Color(0xFF6A68A6);
  static const Color _borderColor = Color(0xFFC9C9C9);
  static const Color _placeholderColor = Color(0xFF808080);
  static const int _defaultSafeZoneType = 1;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  MapSelectionResult? _selectedLocation;

  bool _nameError = false;
  bool _locationError = false;
  bool _radiusError = false;

  bool get _isEditing => widget.existingZone != null;

  @override
  void initState() {
    super.initState();

    final zone = widget.existingZone;
    if (zone == null) {
      return;
    }

    _nameController.text = zone.name;
    _radiusController.text = zone.radiusInMeters.toString();
    _selectedLocation = MapSelectionResult(
      latitude: zone.latitude,
      longitude: zone.longitude,
      label:
          '${zone.latitude.toStringAsFixed(5)}, ${zone.longitude.toStringAsFixed(5)}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  Future<void> _openMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapScreen(child: widget.child),
      ),
    );

    if (result != null && result is MapSelectionResult) {
      setState(() {
        _selectedLocation = result;
        _locationError = false;
      });
    }
  }

  Future<void> _submitSafeZone() async {
    final name = _nameController.text.trim();
    final radiusText = _radiusController.text.trim();
    final radiusInMeters = int.tryParse(radiusText);

    setState(() {
      _nameError = name.isEmpty;
      _locationError = _selectedLocation == null;
      _radiusError = radiusInMeters == null || radiusInMeters <= 0;
    });

    if (_nameError || _locationError || _radiusError) {
      return;
    }

    try {
      if (_isEditing) {
        await context.read<SafeZoneProvider>().updateZone(
              widget.existingZone!.id,
              name: name,
              latitude: _selectedLocation!.latitude,
              longitude: _selectedLocation!.longitude,
              radiusInMeters: radiusInMeters!,
            );
      } else {
        await context.read<SafeZoneProvider>().addZone(
              childId: widget.child.id,
              name: name,
              latitude: _selectedLocation!.latitude,
              longitude: _selectedLocation!.longitude,
              radiusInMeters: radiusInMeters!,
              type: _defaultSafeZoneType,
            );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } on ApiException catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteSafeZone() async {
    final zone = widget.existingZone;
    if (zone == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  'حذف منطقة الامان',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
                content: Text(
                  'هل تريد حذف منطقة الامان هذه؟',
                  style: GoogleFonts.cairo(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('إلغاء', style: GoogleFonts.cairo()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'حذف',
                      style: GoogleFonts.cairo(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await context.read<SafeZoneProvider>().deleteZone(zone.id);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } on ApiException catch (error) {
      _showError(error);
    }
  }

  void _showError(ApiException error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          UserErrorMessages.fromApiException(error),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final isSubmitting = context.watch<SafeZoneProvider>().isSubmitting;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    scaled(22),
                    scaled(32),
                    scaled(22),
                    scaled(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLabel('اسم المكان'),
                      SizedBox(height: scaled(8)),
                      _buildNameField(),
                      if (_nameError)
                        _buildErrorText('من فضلك ادخل اسم المكان'),
                      SizedBox(height: scaled(22)),
                      _buildLabel('اختر موقعك'),
                      SizedBox(height: scaled(8)),
                      _buildLocationField(),
                      if (_locationError)
                        _buildErrorText('من فضلك اختر الموقع على الخريطة'),
                      SizedBox(height: scaled(22)),
                      _buildRadiusField(),
                      if (_radiusError)
                        _buildErrorText('من فضلك ادخل نطاقاً صحيحاً'),
                      SizedBox(height: scaled(34)),
                      if (_isEditing) ...[
                        _buildDeleteButton(isSubmitting),
                        SizedBox(height: scaled(18)),
                      ],
                      _buildSubmitButton(isSubmitting),
                    ],
                  ),
                ),
              ),
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
            _isEditing ? 'تعديل موقع الامان' : 'اضف مواقع الامان',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: scaled(24),
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: _titleColor,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: _titleColor,
                size: scaled(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Text(
      text,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
        fontSize: scaled(16),
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: _textColor,
      ),
    );
  }

  Widget _buildNameField() {
    return _buildTextInput(
      controller: _nameController,
      hasError: _nameError,
      onChanged: (value) {
        if (_nameError && value.trim().isNotEmpty) {
          setState(() => _nameError = false);
        }
      },
    );
  }

  Widget _buildLocationField() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openMap,
        borderRadius: BorderRadius.circular(scaled(20)),
        child: Ink(
          height: scaled(56),
          padding: EdgeInsets.symmetric(horizontal: scaled(16)),
          decoration: _fieldDecoration(_locationError),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: _placeholderColor,
                size: scaled(24),
              ),
              SizedBox(width: scaled(10)),
              Expanded(
                child: Text(
                  _selectedLocation?.label ?? 'الموقع',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(15),
                    fontWeight: FontWeight.w500,
                    color: _selectedLocation == null
                        ? _placeholderColor
                        : _textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusField() {
    return _buildTextInput(
      controller: _radiusController,
      hasError: _radiusError,
      keyboardType: TextInputType.number,
      hintText: 'ضع الابعاد بالمتر',
      onChanged: (value) {
        final radius = int.tryParse(value.trim());
        if (_radiusError && radius != null && radius > 0) {
          setState(() => _radiusError = false);
        }
      },
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required bool hasError,
    TextInputType? keyboardType,
    String? hintText,
    ValueChanged<String>? onChanged,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      height: scaled(56),
      decoration: _fieldDecoration(hasError),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.cairo(
          fontSize: scaled(15),
          fontWeight: FontWeight.w500,
          color: _textColor,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.cairo(
            fontSize: scaled(14),
            fontWeight: FontWeight.w500,
            color: _placeholderColor,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: scaled(24),
            vertical: scaled(12),
          ),
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration(bool hasError) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(scaled(28)),
      border: Border.all(
        color: hasError ? Colors.red : _borderColor,
        width: scaled(1.7),
      ),
    );
  }

  Widget _buildErrorText(String text) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Padding(
      padding: EdgeInsets.only(top: scaled(8)),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          fontSize: scaled(14),
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isSubmitting) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Center(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _submitSafeZone,
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonColor,
            disabledBackgroundColor: _buttonColor.withValues(alpha: 0.55),
            minimumSize: Size.fromHeight(scaled(58)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaled(26)),
            ),
            elevation: 0,
          ),
          child: isSubmitting
              ? SizedBox(
                  width: scaled(28),
                  height: scaled(28),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isEditing ? 'حفظ التعديلات' : 'اضف موقعك',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(17),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(bool isSubmitting) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Center(
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isSubmitting ? null : _deleteSafeZone,
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(scaled(62)),
            side: BorderSide(color: Colors.red, width: scaled(1.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaled(24)),
            ),
          ),
          child: Text(
            'حذف المنطقة',
            style: GoogleFonts.cairo(
              fontSize: scaled(18),
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}
