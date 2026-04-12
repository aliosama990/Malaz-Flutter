import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_images.dart';
import '../constants/app_strings.dart';
import '../providers/child_provider.dart';
import 'home_screen.dart';

class AddChildScreen extends StatefulWidget {
  final bool canSkip;

  const AddChildScreen({
    super.key,
    this.canSkip = true,
  });

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();

  String _selectedGender = AppStrings.addChildGenderMale;
  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedYear;
  bool _showBirthDateError = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deviceIdController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  String? _getBirthDate() {
    if (_selectedYear != null &&
        _selectedMonth != null &&
        _selectedDay != null) {
      return '$_selectedYear-${_selectedMonth!.padLeft(2, '0')}-${_selectedDay!.padLeft(2, '0')}';
    }
    return null;
  }

  int _getGenderValue() {
    return _selectedGender == AppStrings.addChildGenderFemale ? 1 : 0;
  }

  Future<void> _handleAddChild() async {
    if (_formKey.currentState!.validate()) {
      final birthDate = _getBirthDate();
      if (birthDate == null) {
        setState(() {
          _showBirthDateError = true;
        });
        return;
      }

      setState(() {
        _showBirthDateError = false;
      });

      final childProvider = Provider.of<ChildProvider>(context, listen: false);

      final success = await childProvider.addChild(
        name: _nameController.text.trim(),
        birthDate: birthDate,
        gender: _getGenderValue(),
        deviceId: _deviceIdController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              childProvider.errorMessage ?? AppStrings.addChildError,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ChildProvider>(
          builder: (context, childProvider, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: SlideTransition(
                          position: _logoSlideAnimation,
                          child: Image.asset(
                            AppImages.logo,
                            height: 100,
                            width: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          AppStrings.addChildTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.registerTitle,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildLabeledTextField(
                        label: 'اسم الطفل',
                        controller: _nameController,
                        hint: 'اسم الطفل',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.childNameRequired;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _buildBirthDateSection(),

                      const SizedBox(height: 14),

                      _buildGenderSection(),

                      const SizedBox(height: 14),

                      _buildLabeledTextField(
                        label: 'ربط الجهاز',
                        controller: _deviceIdController,
                        hint: 'الرقم التسلسلي',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.deviceIdRequired;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // ✅ زرار ابدأ الان
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.registerTitle,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.registerTitle.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: childProvider.isLoading
                                    ? null
                                    : _handleAddChild,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.center,
                                  child: childProvider.isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          AppStrings.addChildButton,
                                          style: GoogleFonts.cairo(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 6),
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.registerTitle,
                ),
              ),
            ),
            // ✅ الـ Field
            TextFormField(
              controller: controller,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: icon != null
                    ? Icon(
                        icon,
                        color: Colors.grey.shade400,
                        size: 20,
                      )
                    : null,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.registerTitle,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1.5,
                  ),
                ),
              ),
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ تاريخ الميلاد مع Label فوقه
  Widget _buildBirthDateSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ✅ Label
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 6),
              child: Text(
                'تاريخ الميلاد',
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.registerTitle,
                ),
              ),
            ),
            // ✅ الـ Dropdowns
            Row(
              children: [
                // MM
                Expanded(
                  child: _buildDateDropdown(
                    hint: 'MM',
                    value: _selectedMonth,
                    items: List.generate(
                        12, (index) => (index + 1).toString().padLeft(2, '0')),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                        _showBirthDateError = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // DD
                Expanded(
                  child: _buildDateDropdown(
                    hint: 'DD',
                    value: _selectedDay,
                    items: List.generate(
                        31, (index) => (index + 1).toString().padLeft(2, '0')),
                    onChanged: (value) {
                      setState(() {
                        _selectedDay = value;
                        _showBirthDateError = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // YYYY
                Expanded(
                  child: _buildDateDropdown(
                    hint: 'YYYY',
                    value: _selectedYear,
                    items: List.generate(100, (index) {
                      final year = DateTime.now().year - index;
                      return year.toString();
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                        _showBirthDateError = false;
                      });
                    },
                  ),
                ),
              ],
            ),
            // ✅ Error
            if (_showBirthDateError)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 4),
                child: Text(
                  AppStrings.birthDateRequired,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.red[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _showBirthDateError ? Colors.red : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.cairo(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade400,
            size: 20,
          ),
          dropdownColor: Colors.white,
          menuMaxHeight: 300,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.cairo(
                  color: AppColors.registerTitle,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ✅ النوع مع Label فوقه
  Widget _buildGenderSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ✅ Label
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 6),
              child: Text(
                'النوع',
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.registerTitle,
                ),
              ),
            ),
            // ✅ Radio buttons
            RadioGroup<String>(
              groupValue: _selectedGender,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedGender = value;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                // أنثى
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGender = AppStrings.addChildGenderFemale;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        AppStrings.addChildGenderFemale,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: AppColors.registerTitle,
                          fontWeight: FontWeight.w500,
                        ),
                       ),
                       Radio<String>(
                         value: AppStrings.addChildGenderFemale,
                        activeColor: AppColors.registerTitle,
                       ),
                     ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGender = AppStrings.addChildGenderMale;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        AppStrings.addChildGenderMale,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: AppColors.registerTitle,
                          fontWeight: FontWeight.w500,
                        ),
                       ),
                       Radio<String>(
                         value: AppStrings.addChildGenderMale,
                        activeColor: AppColors.registerTitle,
                       ),
                     ],
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
}
