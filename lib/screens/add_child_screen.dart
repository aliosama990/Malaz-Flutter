import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/child_mode.dart';
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
  static const List<String> _calendarMonthLabels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const List<String> _calendarWeekdayLabels = <String>[
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
  ];
  static const Color _mainSettingsDateTextColor = Color(0xFF355D84);
  static const Color _mainSettingsDateBorderColor = Color(0xFF345D86);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();

  String _selectedGender = AppStrings.addChildGenderMale;
  ChildCondition? _selectedCondition;
  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedYear;
  bool _showBirthDateError = false;
  bool _showConditionError = false;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _logoController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<Offset> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 140), _fadeController.forward);
    Future.delayed(
      const Duration(milliseconds: 180),
      _slideController.forward,
    );
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

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
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

  List<String> get _yearOptions => List<String>.generate(
        80,
        (index) => (DateTime.now().year - index).toString(),
      );

  DateTime? get _selectedBirthDateValue {
    final selectedYear = int.tryParse(_selectedYear ?? '');
    final selectedMonth = int.tryParse(_selectedMonth ?? '');
    final selectedDay = int.tryParse(_selectedDay ?? '');

    if (selectedYear == null || selectedMonth == null || selectedDay == null) {
      return null;
    }

    final candidate = DateTime(selectedYear, selectedMonth, selectedDay);
    if (candidate.year != selectedYear ||
        candidate.month != selectedMonth ||
        candidate.day != selectedDay) {
      return null;
    }

    return candidate;
  }

  String get _birthDateDisplayText {
    final selectedDate = _selectedBirthDateValue;
    if (selectedDate == null) {
      return 'اختر تاريخ الميلاد';
    }

    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final year = selectedDate.year.toString();
    return '$day / $month / $year';
  }

  void _applyBirthDate(DateTime date) {
    _selectedYear = date.year.toString();
    _selectedMonth = date.month.toString().padLeft(2, '0');
    _selectedDay = date.day.toString().padLeft(2, '0');
    _showBirthDateError = false;
  }

  Future<void> _openBirthDatePicker() async {
    final years =
        _yearOptions.map((year) => int.parse(year)).toList(growable: false);
    final selectedDate = await showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'birth_date_picker',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(
                            sigmaX: 14,
                            sigmaY: 14,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.09),
                              const Color(0xFFE8E6FA).withValues(alpha: 0.16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: _BirthDatePickerDialog(
                  initialDate: _selectedBirthDateValue,
                  firstYear: years.last,
                  lastYear: years.first,
                  monthLabels: _calendarMonthLabels,
                  weekdayLabels: _calendarWeekdayLabels,
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(
              curvedAnimation,
            ),
            child: child,
          ),
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _applyBirthDate(selectedDate);
    });
  }

  Future<void> _handleAddChild() async {
    final formIsValid = _formKey.currentState!.validate();
    final birthDate = _getBirthDate();
    final selectedCondition = _selectedCondition;

    setState(() {
      _showBirthDateError = birthDate == null;
      _showConditionError = selectedCondition == null;
    });

    if (!formIsValid || birthDate == null || selectedCondition == null) {
      return;
    }

    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final success = await childProvider.addChild(
      name: _nameController.text.trim(),
      birthDate: birthDate,
      gender: _getGenderValue(),
      deviceId: _deviceIdController.text.trim(),
      condition: selectedCondition,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      return;
    }

    if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Consumer<ChildProvider>(
            builder: (context, childProvider, _) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  scaled(22),
                  scaled(8),
                  scaled(22),
                  scaled(24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLogoHeader(),
                      SizedBox(height: scaled(18)),
                      _buildTitle(),
                      SizedBox(height: scaled(22)),
                      _buildLabeledTextField(
                        label: 'اسم الطفل',
                        controller: _nameController,
                        hint: 'اسم الطفل',
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.childNameRequired;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: scaled(14)),
                      _buildBirthDateSection(),
                      SizedBox(height: scaled(14)),
                      _buildGenderSection(),
                      SizedBox(height: scaled(14)),
                      _buildLabeledTextField(
                        label: 'ربط الجهاز',
                        controller: _deviceIdController,
                        hint: 'الرقم التسلسلي',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.deviceIdRequired;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: scaled(14)),
                      _buildConditionSection(),
                      SizedBox(height: scaled(42)),
                      _buildPrimaryButton(childProvider),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return FadeTransition(
      opacity: _logoFadeAnimation,
      child: SlideTransition(
        position: _logoSlideAnimation,
        child: SizedBox(
          height: scaled(126),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: scaled(-84),
                top: scaled(12),
                child: _buildCloudCircle(
                  size: scaled(132),
                  colors: const [Color(0xFFA8C5FF), Color(0xFFE6EEFF)],
                ),
              ),
              Positioned(
                left: scaled(34),
                top: scaled(-10),
                child: _buildCloudCircle(
                  size: scaled(150),
                  colors: const [Color(0xFFB7CEFF), Color(0xFFF1F4FF)],
                ),
              ),
              Positioned(
                left: scaled(126),
                top: scaled(-24),
                child: _buildCloudCircle(
                  size: scaled(158),
                  colors: const [Color(0xFFEDE8F6), Color(0xFFD7E2FF)],
                ),
              ),
              Positioned(
                top: scaled(34),
                child: SizedBox(
                  width: scaled(86),
                  height: scaled(86),
                  child: Padding(
                    padding: EdgeInsets.all(scaled(10)),
                    child: Image.asset(
                      'Avatar/New Logo Transparent.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: scaled(10),
                right: 0,
                child: _buildHeaderBackButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBackButton() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Material(
      color: Colors.white.withValues(alpha: 0.76),
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: scaled(42),
          height: scaled(42),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.registerTitle,
            size: scaled(27),
          ),
        ),
      ),
    );
  }

  Widget _buildCloudCircle({
    required double size,
    required List<Color> colors,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        AppStrings.addChildTitle,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: scaled(36),
          fontWeight: FontWeight.w800,
          color: AppColors.registerTitle,
          height: 1.15,
          shadows: const [
            Shadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
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
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(label),
            _buildShadowedField(
              child: TextFormField(
                controller: controller,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: scaled(14.5),
                  fontWeight: FontWeight.w600,
                  color: AppColors.registerTitle,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.cairo(
                    fontSize: scaled(14),
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: icon == null
                      ? null
                      : Icon(
                          icon,
                          color: AppColors.registerTitle,
                          size: scaled(24),
                        ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: scaled(14),
                    vertical: scaled(10),
                  ),
                  errorStyle: GoogleFonts.cairo(fontSize: scaled(10.5)),
                ),
                validator: validator,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthDateSection() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('تاريخ الميلاد'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: scaled(12)),
              child: _buildMainSettingsDateField(
                height: scaled(52),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openBirthDatePicker,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaled(10)),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              _birthDateDisplayText,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: scaled(14.5),
                                fontWeight: FontWeight.w700,
                                color: _selectedBirthDateValue == null
                                    ? _mainSettingsDateTextColor.withValues(
                                        alpha: 0.52,
                                      )
                                    : _mainSettingsDateTextColor,
                              ),
                            ),
                          ),
                          SizedBox(width: scaled(8)),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _mainSettingsDateTextColor.withValues(
                              alpha: 0.80,
                            ),
                            size: scaled(24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showBirthDateError)
              Padding(
                padding: EdgeInsets.only(top: scaled(5), right: scaled(4)),
                child: Text(
                  AppStrings.birthDateRequired,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(11),
                    color: Colors.red[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSettingsDateField({
    required Widget child,
    double height = 52,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: scaled(12)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(scaled(18)),
        border: Border.all(
          color: _mainSettingsDateBorderColor,
          width: scaled(1.2),
        ),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildGenderSection() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('النوع'),
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildChoiceOption(
                  label: AppStrings.addChildGenderMale,
                  selected: _selectedGender == AppStrings.addChildGenderMale,
                  onTap: () {
                    setState(() {
                      _selectedGender = AppStrings.addChildGenderMale;
                    });
                  },
                ),
                SizedBox(width: scaled(24)),
                _buildChoiceOption(
                  label: AppStrings.addChildGenderFemale,
                  selected: _selectedGender == AppStrings.addChildGenderFemale,
                  onTap: () {
                    setState(() {
                      _selectedGender = AppStrings.addChildGenderFemale;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionSection() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('الحالة الصحية للطفل'),
            Column(
              children: [
                _buildConditionListOption(
                  label: 'طبيعي',
                  selected: _selectedCondition == ChildCondition.normal,
                  onTap: () {
                    setState(() {
                      _selectedCondition = ChildCondition.normal;
                      _showConditionError = false;
                    });
                  },
                ),
                SizedBox(height: scaled(8)),
                _buildConditionListOption(
                  label: 'توحد',
                  selected: _selectedCondition == ChildCondition.autism,
                  onTap: () {
                    setState(() {
                      _selectedCondition = ChildCondition.autism;
                      _showConditionError = false;
                    });
                  },
                ),
                SizedBox(height: scaled(8)),
                _buildConditionListOption(
                  label: 'فرط حركة',
                  selected: _selectedCondition == ChildCondition.adhd,
                  onTap: () {
                    setState(() {
                      _selectedCondition = ChildCondition.adhd;
                      _showConditionError = false;
                    });
                  },
                ),
              ],
            ),
            if (_showConditionError)
              Padding(
                padding: EdgeInsets.only(top: scaled(6), right: scaled(4)),
                child: Text(
                  'الحالة الصحية مطلوبة',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(11),
                    color: Colors.red[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionListOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    const conditionAccentColor = Color(0xFF6D6AA9);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(scaled(16)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: scaled(14),
            vertical: scaled(10),
          ),
          decoration: BoxDecoration(
            color: selected
                ? conditionAccentColor.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(scaled(16)),
            border: Border.all(
              color: selected
                  ? conditionAccentColor
                  : conditionAccentColor.withValues(alpha: 0.42),
              width: selected ? scaled(1.5) : scaled(1.1),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: scaled(22),
                height: scaled(22),
                decoration: BoxDecoration(
                  color: selected ? conditionAccentColor : Colors.white,
                  borderRadius: BorderRadius.circular(scaled(7)),
                  border: Border.all(
                    color: selected
                        ? conditionAccentColor
                        : conditionAccentColor.withValues(alpha: 0.72),
                    width: scaled(1.4),
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: scaled(16),
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: scaled(10)),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(15),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: conditionAccentColor,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(scaled(20)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: scaled(2),
            vertical: scaled(4),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: scaled(15),
                  fontWeight: FontWeight.w700,
                  color: AppColors.registerTitle,
                  shadows: const [
                    Shadow(
                      color: Color(0x18000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              SizedBox(width: scaled(8)),
              Container(
                width: scaled(18),
                height: scaled(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.registerTitle,
                    width: scaled(1.4),
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: scaled(9),
                          height: scaled(9),
                          decoration: const BoxDecoration(
                            color: AppColors.registerTitle,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(ChildProvider childProvider) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: SizedBox(
            width: scaled(230),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6D6AA9),
                borderRadius: BorderRadius.circular(scaled(28)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(scaled(28)),
                  onTap: childProvider.isLoading ? null : _handleAddChild,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: scaled(14)),
                    child: Center(
                      child: childProvider.isLoading
                          ? SizedBox(
                              height: scaled(24),
                              width: scaled(24),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'ابدأ الان',
                              style: GoogleFonts.cairo(
                                fontSize: scaled(19),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Padding(
      padding: EdgeInsets.only(right: scaled(4), bottom: scaled(7)),
      child: Text(
        label,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.cairo(
          fontSize: scaled(16),
          fontWeight: FontWeight.w700,
          color: AppColors.registerTitle,
          shadows: const [
            Shadow(
              color: Color(0x18000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShadowedField({
    required Widget child,
    double height = 52,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      height: scaled(height),
      padding: EdgeInsets.symmetric(horizontal: scaled(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaled(18)),
        border: Border.all(
          color: AppColors.registerTitle,
          width: scaled(1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x26000000),
            blurRadius: scaled(8),
            offset: Offset(0, scaled(5)),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _BirthDatePickerDialog extends StatefulWidget {
  const _BirthDatePickerDialog({
    required this.initialDate,
    required this.firstYear,
    required this.lastYear,
    required this.monthLabels,
    required this.weekdayLabels,
  });

  final DateTime? initialDate;
  final int firstYear;
  final int lastYear;
  final List<String> monthLabels;
  final List<String> weekdayLabels;

  @override
  State<_BirthDatePickerDialog> createState() => _BirthDatePickerDialogState();
}

class _BirthDatePickerDialogState extends State<_BirthDatePickerDialog> {
  late DateTime _displayedMonth;
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final initialDate = widget.initialDate ?? DateTime.now();
    _displayedMonth = DateTime(initialDate.year, initialDate.month);
    _selectedDate = widget.initialDate;
  }

  List<int> get _yearItems => List<int>.generate(
        widget.lastYear - widget.firstYear + 1,
        (index) => widget.firstYear + index,
      );

  List<DateTime> get _calendarDays {
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final leadingDays = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final totalCells = leadingDays + daysInMonth <= 35 ? 35 : 42;
    final firstVisibleDay = firstDayOfMonth.subtract(
      Duration(days: leadingDays),
    );

    return List<DateTime>.generate(
      totalCells,
      (index) => DateTime(
        firstVisibleDay.year,
        firstVisibleDay.month,
        firstVisibleDay.day + index,
      ),
    );
  }

  void _changeMonth(int offset) {
    final candidate = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + offset,
    );

    if (candidate.year < widget.firstYear || candidate.year > widget.lastYear) {
      return;
    }

    setState(() {
      _displayedMonth = DateTime(candidate.year, candidate.month);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _displayedMonth = DateTime(date.year, date.month);
    });

    Navigator.of(context).pop(date);
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  Widget _buildTopSelector<T>({
    required T value,
    required List<T> items,
    required String Function(T item) labelBuilder,
    required ValueChanged<T?> onChanged,
    double width = 84,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: scaled(width),
      height: scaled(38),
      padding: EdgeInsets.symmetric(horizontal: scaled(11)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaled(11)),
        border: Border.all(
          color: const Color(0xFFD6D2D2),
          width: scaled(0.9),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: scaled(20),
            color: const Color(0xFF3C3C40),
          ),
          dropdownColor: Colors.white,
          style: GoogleFonts.cairo(
            fontSize: scaled(16),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF303035),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(16),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF303035),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(scaled(18)),
      child: SizedBox(
        width: scaled(34),
        height: scaled(34),
        child: Icon(
          icon,
          size: scaled(24),
          color: const Color(0xFF26262A),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final dialogWidth = (MediaQuery.sizeOf(context).width - scaled(52))
        .clamp(scaled(302), scaled(338))
        .toDouble();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.fromLTRB(
          scaled(20),
          scaled(18),
          scaled(20),
          scaled(18),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(scaled(20)),
          border: Border.all(
            color: const Color(0xFFD9D6D2),
            width: scaled(0.95),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x12000000),
              blurRadius: scaled(26),
              offset: Offset(0, scaled(12)),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _changeMonth(-1),
                  ),
                  SizedBox(width: scaled(10)),
                  _buildTopSelector<int>(
                    value: _displayedMonth.month,
                    items: List<int>.generate(12, (index) => index + 1),
                    labelBuilder: (month) => widget.monthLabels[month - 1],
                    onChanged: (month) {
                      if (month == null) {
                        return;
                      }
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, month);
                      });
                    },
                    width: 96,
                  ),
                  SizedBox(width: scaled(10)),
                  _buildTopSelector<int>(
                    value: _displayedMonth.year,
                    items: _yearItems,
                    labelBuilder: (year) => year.toString(),
                    onChanged: (year) {
                      if (year == null) {
                        return;
                      }
                      setState(() {
                        _displayedMonth = DateTime(year, _displayedMonth.month);
                      });
                    },
                    width: 84,
                  ),
                  const Spacer(),
                  _buildNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _changeMonth(1),
                  ),
                ],
              ),
              SizedBox(height: scaled(18)),
              Row(
                children: widget.weekdayLabels
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: GoogleFonts.cairo(
                              fontSize: scaled(12),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8A8A90),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              SizedBox(height: scaled(12)),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _calendarDays.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: scaled(6),
                  crossAxisSpacing: scaled(6),
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final day = _calendarDays[index];
                  final isCurrentMonth = day.month == _displayedMonth.month;
                  final isSelected = _selectedDate != null &&
                      DateUtils.isSameDay(day, _selectedDate);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectDate(day),
                      borderRadius: BorderRadius.circular(scaled(10)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3C3C3F)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(scaled(10)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: GoogleFonts.cairo(
                            fontSize: scaled(20),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isCurrentMonth
                                    ? const Color(0xFF36363B)
                                    : const Color(0xFFC8C8CD),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
