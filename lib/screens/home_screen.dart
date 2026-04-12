import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/screens/login_screen.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/child_mode.dart';
import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../widgets/initial_avatar.dart';
import 'add_child_screen.dart';
import 'chatbot_screen.dart';
import 'child_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const String _addChildMenuValue = '__add_child__';
  static const String _childMenuValuePrefix = 'child:';

  late AnimationController _fadeController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  bool _isChildSelectorOpen = false;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<ChildProvider>(context, listen: false)
          .fetchMyChildren();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  ChildModel? _resolveSelectedChild(List<ChildModel> children) {
    if (children.isEmpty) {
      return null;
    }

    if (_selectedChildId == null) {
      return children.first;
    }

    for (final child in children) {
      if (child.id == _selectedChildId) {
        return child;
      }
    }

    return children.first;
  }

  void _selectChild(ChildModel child) {
    setState(() {
      _selectedChildId = child.id;
      _isChildSelectorOpen = false;
    });
  }

  void _openAddChildScreen() {
    setState(() {
      _isChildSelectorOpen = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddChildScreen(canSkip: false),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildChildMenuItems({
    required ChildProvider childProvider,
    required List<ChildModel> children,
    required ChildModel? selectedChild,
  }) {
    final dropdownChildren = selectedChild == null
        ? children
        : children.where((child) => child.id != selectedChild.id).toList();
    final items = <PopupMenuEntry<String>>[];

    if (children.isEmpty) {
      items.add(
        PopupMenuItem<String>(
          enabled: false,
          height: 52,
          child: Center(
            child: Text(
              childProvider.errorMessage ?? AppStrings.noChildrenYet,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      );
    } else if (dropdownChildren.isEmpty) {
      items.add(
        PopupMenuItem<String>(
          enabled: false,
          height: 48,
          child: Center(
            child: Text(
              'لا يوجد أطفال آخرون',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      );
    } else {
      for (final child in dropdownChildren) {
        items.add(
          PopupMenuItem<String>(
            value: '$_childMenuValuePrefix${child.id}',
            height: 56,
            child: _buildChildOption(child: child),
          ),
        );
      }
    }

    items.add(const PopupMenuDivider(height: 8));
    items.add(
      PopupMenuItem<String>(
        value: _addChildMenuValue,
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.addAnotherChild,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.add,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );

    return items;
  }

  Widget _buildChildSelector({
    required ChildProvider childProvider,
    required List<ChildModel> children,
    required ChildModel? selectedChild,
  }) {
    final selectorText = selectedChild != null
        ? selectedChild.name
        : childProvider.isLoading
            ? 'جارٍ تحميل الأطفال...'
            : children.isEmpty
                ? 'أضف طفلاً'
                : 'اختر الطفل';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.registerTitle,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return PopupMenuButton<String>(
            enabled: !childProvider.isLoading,
            tooltip: '',
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 10),
            elevation: 8,
            color: AppColors.registerTitle,
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
              maxHeight: 260,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            onOpened: () {
              setState(() {
                _isChildSelectorOpen = true;
              });
            },
            onCanceled: () {
              setState(() {
                _isChildSelectorOpen = false;
              });
            },
            onSelected: (value) {
              if (value == _addChildMenuValue) {
                _openAddChildScreen();
                return;
              }

              for (final child in children) {
                if (value == '$_childMenuValuePrefix${child.id}') {
                  _selectChild(child);
                  return;
                }
              }

              setState(() {
                _isChildSelectorOpen = false;
              });
            },
            itemBuilder: (_) => _buildChildMenuItems(
              childProvider: childProvider,
              children: children,
              selectedChild: selectedChild,
            ),
            child: Material(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      _isChildSelectorOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: selectedChild == null
                          ? Text(
                              selectorText,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    selectorText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InitialAvatar(
                                  label: selectedChild.name,
                                  radius: 18,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.18),
                                  foregroundColor: Colors.white,
                                  role: AvatarRole.child,
                                  childGender: selectedChild.gender,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChildOption({
    required ChildModel child,
  }) {
    return Row(
      children: [
        const Icon(
          Icons.keyboard_arrow_left_rounded,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  child.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InitialAvatar(
                label: child.name,
                radius: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
                role: AvatarRole.child,
                childGender: child.gender,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer2<AuthProvider, ChildProvider>(
          builder: (context, authProvider, childProvider, _) {
            final userName = authProvider.user?.name ?? '';
            final children = childProvider.children;
            final selectedChild = _resolveSelectedChild(children);

            return Column(
              children: [
                SlideTransition(
                  position: _headerSlideAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 22),
                    color: AppColors.registerTitle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout,
                              color: Colors.white, size: 26),
                          onPressed: () {
                            Provider.of<AuthProvider>(context, listen: false)
                                .logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            InitialAvatar(
                              label: userName,
                              radius: 20,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              foregroundColor: Colors.white,
                              role: AvatarRole.parent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEDFE0),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        AppStrings.homeSelectChild,
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.homeActionText,
                                        ),
                                      ),
                                    ),
                                    _buildChildSelector(
                                      childProvider: childProvider,
                                      children: children,
                                      selectedChild: selectedChild,
                                    ),
                                    if (selectedChild != null) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChildDetailsScreen(
                                                  child: selectedChild,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            size: 16,
                                            color: AppColors.registerTitle,
                                          ),
                                          label: Text(
                                            'عرض بيانات الطفل',
                                            style: GoogleFonts.cairo(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.registerTitle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                if (selectedChild == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'أضف طفلاً أولاً لفتح المساعد الذكي',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatbotScreen(
                                      child: selectedChild,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: AppColors.registerTitle,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppStrings.homeHowCanHelp,
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.registerTitle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.chat_bubble_outline,
                                      color: AppColors.registerTitle,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _openAddChildScreen,
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.registerTitle,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppStrings.addAnotherChild,
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.add,
                                        color: Colors.white, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
