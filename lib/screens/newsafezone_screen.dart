import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/models/child_mode.dart';
import 'package:malaz_app/models/safe_zone_model.dart';
import 'package:malaz_app/providers/safezone_provider.dart';
import 'package:malaz_app/screens/google_map.dart';
import 'package:malaz_app/services/api_service.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';

class NewSafeZoneScreen extends StatefulWidget {
  const NewSafeZoneScreen({
    Key? key,
    required this.child,
    this.existingZone,
  }) : super(key: key);

  final ChildModel child;
  final SafeZoneModel? existingZone;

  @override
  State<NewSafeZoneScreen> createState() => _NewSafeZoneScreenState();
}

class _NewSafeZoneScreenState extends State<NewSafeZoneScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  MapSelectionResult? _selectedLocation;
  int? _selectedType;

  bool _nameError = false;
  bool _locationError = false;
  bool _radiusError = false;
  bool _typeError = false;

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
    _selectedType = zone.type;
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
      _typeError = !_isEditing && _selectedType == null;
    });

    if (_nameError || _locationError || _radiusError || _typeError) {
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
              type: _selectedType!,
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
            return AlertDialog(
              title: const Text('حذف منطقة الامان'),
              content: const Text('هل تريد حذف منطقة الامان هذه؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('حذف'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    if (!mounted) {
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
          error.errorMessages.isNotEmpty
              ? error.errorMessages.join('\n')
              : error.message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<SafeZoneProvider>().isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 32),
                      _buildLabel('اسم المكان'),
                      const SizedBox(height: 8),
                      _buildNameField(),
                      if (_nameError)
                        _buildErrorText('من فضلك ادخل اسم المكان'),
                      const SizedBox(height: 24),
                      _buildLabel('اختر موقعك'),
                      const SizedBox(height: 8),
                      _buildLocationField(),
                      if (_locationError) ...[
                        const SizedBox(height: 6),
                        _buildErrorText('من فضلك اختر الموقع على الخريطة'),
                      ],
                      const SizedBox(height: 24),
                      _buildLabel('نطاق المنطقة بالمتر'),
                      const SizedBox(height: 8),
                      _buildRadiusField(),
                      if (_radiusError) ...[
                        const SizedBox(height: 6),
                        _buildErrorText('من فضلك ادخل نطاقاً صحيحاً'),
                      ],
                      const SizedBox(height: 24),
                      _buildLabel('نوع المنطقة'),
                      const SizedBox(height: 8),
                      if (_isEditing)
                        _buildReadOnlyTypeField()
                      else
                        _buildTypeField(),
                      if (_typeError) ...[
                        const SizedBox(height: 6),
                        _buildErrorText('من فضلك اختر نوع المنطقة'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  if (_isEditing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : _deleteSafeZone,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'حذف المنطقة',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitSafeZone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.registerTitle,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'حفظ التعديلات' : 'اضف موقعك',
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
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.registerTitle,
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
        fontSize: 15,
        color: AppColors.registerTitle,
      ),
      onChanged: (value) {
        if (_nameError && value.trim().isNotEmpty) {
          setState(() => _nameError = false);
        }
      },
      decoration: _inputDecoration(_nameError),
    );
  }

  Widget _buildLocationField() {
    return GestureDetector(
      onTap: _openMap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _locationError ? Colors.red : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                _selectedLocation?.label ?? 'الموقع',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  color: _selectedLocation != null
                      ? AppColors.registerTitle
                      : Colors.grey,
                ),
                textAlign: TextAlign.right,
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
    );
  }

  Widget _buildRadiusField() {
    return TextField(
      controller: _radiusController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
        fontSize: 15,
        color: AppColors.registerTitle,
      ),
      onChanged: (value) {
        if (_radiusError && int.tryParse(value.trim()) != null) {
          setState(() => _radiusError = false);
        }
      },
      decoration: _inputDecoration(_radiusError),
    );
  }

  Widget _buildTypeField() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedType,
      isExpanded: true,
      decoration: _inputDecoration(_typeError),
      items: const [
        DropdownMenuItem<int>(
          value: 0,
          child: Text('School'),
        ),
        DropdownMenuItem<int>(
          value: 1,
          child: Text('Home'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedType = value;
          _typeError = false;
        });
      },
    );
  }

  Widget _buildReadOnlyTypeField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        widget.existingZone!.typeDisplayName,
        style: GoogleFonts.cairo(
          fontSize: 15,
          color: AppColors.registerTitle,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  InputDecoration _inputDecoration(bool hasError) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFFE0E0E0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFFE0E0E0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: hasError ? Colors.red : AppColors.registerTitle,
        ),
      ),
    );
  }

  Widget _buildErrorText(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 12,
        color: Colors.red,
      ),
      textAlign: TextAlign.right,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            _isEditing ? 'تعديل موقع الامان' : 'اضف مواقع الامان',
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
