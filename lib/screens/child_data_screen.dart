import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/child_provider.dart';
import '../models/child_mode.dart';
import 'child_details_screen.dart';

class ChildDataSettingsScreen extends StatefulWidget {
  // ✅ استقبل الطفل اللي هتعدل عليه
  final ChildModel child;

  const ChildDataSettingsScreen({Key? key, required this.child})
      : super(key: key);

  @override
  State<ChildDataSettingsScreen> createState() =>
      _ChildDataSettingsScreenState();
}

class _ChildDataSettingsScreenState extends State<ChildDataSettingsScreen> {
  final _nameController = TextEditingController();
  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedDay;
  int _gender = 0;
  final _deviceController = TextEditingController();

  final List<String> _years =
      List.generate(30, (i) => (DateTime.now().year - i).toString());
  final List<String> _months =
      List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
  final List<String> _days =
      List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));

  @override
  void initState() {
    super.initState();
    final child = widget.child;
    _nameController.text = child.name;
    _deviceController.text = child.deviceId;
    _gender = child.gender;

    try {
      final parts = child.birthDate.split('-');
      if (parts.length == 3) {
        _selectedYear = parts[0];
        _selectedMonth = parts[1];
        _selectedDay = parts[2];
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  String _buildBirthDate() {
    final parts = widget.child.birthDate.split('-');
    final fallbackYear = parts.isNotEmpty ? parts[0] : '';
    final fallbackMonth = parts.length > 1 ? parts[1] : '01';
    final fallbackDay = parts.length > 2 ? parts[2] : '01';

    return '${_selectedYear ?? fallbackYear}-'
        '${_selectedMonth ?? fallbackMonth}-'
        '${_selectedDay ?? fallbackDay}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'اعدادات البيانات',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 28),
                        decoration: BoxDecoration(
                          color: AppColors.registerTitle,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildLabel('اسم الطفل'),
                            _buildTextField(
                              controller: _nameController,
                              hint: 'محمود محمد',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('تاريخ الميلاد'),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    hint: 'MM',
                                    value: _selectedMonth,
                                    items: _months,
                                    onChanged: (v) =>
                                        setState(() => _selectedMonth = v),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDropdown(
                                    hint: 'DD',
                                    value: _selectedDay,
                                    items: _days,
                                    onChanged: (v) =>
                                        setState(() => _selectedDay = v),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDropdown(
                                    hint: 'YYYY',
                                    value: _selectedYear,
                                    items: _years,
                                    onChanged: (v) =>
                                        setState(() => _selectedYear = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('النوع'),
                            RadioGroup<int>(
                              groupValue: _gender,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _gender = value);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text('انثى',
                                          style: GoogleFonts.cairo(
                                              color: Colors.white)),
                                      Radio<int>(
                                        value: 1,
                                        activeColor: Colors.white,
                                        fillColor: const WidgetStatePropertyAll(
                                            Colors.white),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Text('ذكر',
                                          style: GoogleFonts.cairo(
                                              color: Colors.white)),
                                      Radio<int>(
                                        value: 0,
                                        activeColor: Colors.white,
                                        fillColor: const WidgetStatePropertyAll(
                                            Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('ربط الجهاز'),
                            _buildTextField(
                              controller: _deviceController,
                              hint: 'الرقم التسلسلي',
                              icon: null,
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  if (childProvider.isLoading) {
                                    return;
                                  }

                                  final provider =
                                      context.read<ChildProvider>();
                                  final navigator = Navigator.of(context);
                                  final updatedChild =
                                      await provider.updateChildDetails(
                                    childId: widget.child.id,
                                    name: _nameController.text.isNotEmpty
                                        ? _nameController.text.trim()
                                        : widget.child.name,
                                    birthDate: _buildBirthDate(),
                                    gender: _gender,
                                    deviceId: _deviceController.text.isNotEmpty
                                        ? _deviceController.text.trim()
                                        : widget.child.deviceId,
                                  );

                                  if (!mounted) {
                                    return;
                                  }

                                  if (updatedChild == null) {
                                    _showError(
                                      provider.errorMessage ??
                                          'حدث خطأ أثناء تحديث بيانات الطفل',
                                    );
                                    return;
                                  }

                                  navigator.pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => ChildDetailsScreen(
                                          child: updatedChild),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 130,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  child: Center(
                                    child: childProvider.isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'تم',
                                            style: GoogleFonts.cairo(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.cairo(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: Colors.white54),
        suffixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        filled: true,
        fillColor: AppColors.registerTitle,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.registerTitle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: GoogleFonts.cairo(color: Colors.white54)),
        isExpanded: true,
        underline: const SizedBox(),
        iconEnabledColor: Colors.white,
        dropdownColor: AppColors.registerTitle,
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.cairo(color: Colors.white)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
