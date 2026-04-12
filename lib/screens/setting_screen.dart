import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/initial_avatar.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settingItems = [
      {
        'icon': Icons.person_outline,
        'label': 'تعديل البروفايل',
        'onTap': () => _showEditProfile(context),
      },
      {
        'icon': Icons.shield_outlined,
        'label': 'الامان',
        'onTap': () => _showSecurity(context),
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'الاشعارات',
        'onTap': () => _showNotifications(context),
      },
      {
        'icon': Icons.lock_outline,
        'label': 'الخصوصية',
        'onTap': () => _showPrivacy(context),
      },
      {
        'icon': Icons.info_outline,
        'label': 'نبذه عنا',
        'onTap': () => _showAbout(context),
      },
      {
        'icon': Icons.key_outlined,
        'label': 'تغير الباسورد',
        'onTap': () => _showChangePassword(context),
      },
      {
        'icon': Icons.delete_outline,
        'label': 'حذف الاكونت',
        'onTap': () => _showDeleteAccount(context),
      },
      {
        'icon': Icons.phone_outlined,
        'label': 'تواصل معنا',
        'onTap': () => _showContactUs(context),
      },
      {
        'icon': Icons.logout,
        'label': 'تسجيل خروج',
        'onTap': () => _showLogout(context),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: settingItems.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Color(0xFFF0F0F0),
                ),
                itemBuilder: (context, index) {
                  final item = settingItems[index];
                  return _buildSettingItem(
                    icon: item['icon'],
                    label: item['label'],
                    onTap: item['onTap'],
                  );
                },
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
            'الاعدادات',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.registerTitle,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              ),
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

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFFBDBDBD),
              size: 16,
            ),
            Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.registerTitle,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.registerTitle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final userName = user?.name ?? '';
    final nameController = TextEditingController(text: userName);
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            _sheetTitle('تعديل البروفايل'),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  InitialAvatar(
                    label: userName,
                    radius: 40,
                    backgroundColor: AppColors.registerTitle,
                    foregroundColor: Colors.white,
                    role: AvatarRole.parent,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.registerTitle,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildField('الاسم', nameController),
            const SizedBox(height: 12),
            _buildField('رقم الهاتف', phoneController,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildField('الايميل', emailController,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),
            _sheetButton('حفظ', () {
              Navigator.pop(context);
              _showSuccess(context, 'تم تحديث البروفايل بنجاح');
            }),
          ],
        ),
      ),
    );
  }

  void _showSecurity(BuildContext context) {
    bool faceId = false;
    bool twoFactor = false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              _sheetTitle('الامان'),
              const SizedBox(height: 20),
              _buildSwitchTile(
                'Face ID / بصمة الاصبع',
                faceId,
                (val) => setModalState(() => faceId = val),
              ),
              const Divider(),
              _buildSwitchTile(
                'التحقق بخطوتين',
                twoFactor,
                (val) => setModalState(() => twoFactor = val),
              ),
              const SizedBox(height: 20),
              _sheetButton('حفظ', () {
                Navigator.pop(context);
                _showSuccess(context, 'تم حفظ إعدادات الامان');
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    bool allNotifications = true;
    bool emergency = true;
    bool dailyReports = true;
    bool locationAlerts = true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              _sheetTitle('الاشعارات'),
              const SizedBox(height: 20),
              _buildSwitchTile('كل الاشعارات', allNotifications,
                  (val) => setModalState(() => allNotifications = val)),
              const Divider(),
              _buildSwitchTile('اشعارات الطوارئ', emergency,
                  (val) => setModalState(() => emergency = val)),
              const Divider(),
              _buildSwitchTile('التقارير اليومية', dailyReports,
                  (val) => setModalState(() => dailyReports = val)),
              const Divider(),
              _buildSwitchTile('تنبيهات الموقع', locationAlerts,
                  (val) => setModalState(() => locationAlerts = val)),
              const SizedBox(height: 20),
              _sheetButton('حفظ', () {
                Navigator.pop(context);
                _showSuccess(context, 'تم حفظ إعدادات الاشعارات');
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    bool shareLocation = true;
    bool shareHealthData = false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              _sheetTitle('الخصوصية'),
              const SizedBox(height: 20),
              _buildSwitchTile('مشاركة الموقع', shareLocation,
                  (val) => setModalState(() => shareLocation = val)),
              const Divider(),
              _buildSwitchTile('مشاركة البيانات الصحية', shareHealthData,
                  (val) => setModalState(() => shareHealthData = val)),
              const SizedBox(height: 20),
              _sheetButton('حفظ', () {
                Navigator.pop(context);
                _showSuccess(context, 'تم حفظ إعدادات الخصوصية');
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(child: _sheetHandle()),
            const SizedBox(height: 16),
            _sheetTitle('نبذه عنا'),
            const SizedBox(height: 16),
            Text(
              'تطبيق ملاذ هو تطبيق لمتابعة سلامة الأطفال ومراقبة صحتهم وتحديد مواقعهم في الوقت الفعلي لتوفير الأمان لكل عائلة.',
              style: GoogleFonts.cairo(
                  fontSize: 14, color: Colors.grey.shade700, height: 1.8),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text('الإصدار: 1.0.0',
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.right),
            const SizedBox(height: 24),
            _sheetButton('حسناً', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    bool oldObscure = true;
    bool newObscure = true;
    bool confirmObscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 16),
              _sheetTitle('تغير الباسورد'),
              const SizedBox(height: 20),
              _buildPassField('الباسورد القديم', oldPass, oldObscure,
                  () => setModalState(() => oldObscure = !oldObscure)),
              const SizedBox(height: 12),
              _buildPassField('الباسورد الجديد', newPass, newObscure,
                  () => setModalState(() => newObscure = !newObscure)),
              const SizedBox(height: 12),
              _buildPassField('تأكيد الباسورد', confirmPass, confirmObscure,
                  () => setModalState(() => confirmObscure = !confirmObscure)),
              const SizedBox(height: 24),
              _sheetButton('تغيير', () {
                if (newPass.text == confirmPass.text &&
                    newPass.text.isNotEmpty) {
                  Navigator.pop(context);
                  _showSuccess(context, 'تم تغيير الباسورد بنجاح');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('الباسورد غير متطابق',
                          style: GoogleFonts.cairo(),
                          textAlign: TextAlign.right),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف الاكونت',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: Colors.red),
            textAlign: TextAlign.right),
        content: Text('هل انت متأكد من حذف حسابك؟ لن تتمكن من استعادته.',
            style: GoogleFonts.cairo(fontSize: 14), textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(color: AppColors.registerTitle)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showContactUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            _sheetTitle('تواصل معنا'),
            const SizedBox(height: 20),
            _buildContactItem(Icons.email_outlined, 'support@malaz.com'),
            const SizedBox(height: 12),
            _buildContactItem(Icons.phone_outlined, '+20 100 000 0000'),
            const SizedBox(height: 12),
            _buildContactItem(Icons.language_outlined, 'www.malaz.com'),
            const SizedBox(height: 24),
            _sheetButton('حسناً', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تسجيل خروج',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: AppColors.registerTitle),
            textAlign: TextAlign.right),
        content: Text('هل انت متأكد من تسجيل الخروج؟',
            style: GoogleFonts.cairo(fontSize: 14), textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.registerTitle,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('خروج', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _sheetHandle() => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _sheetTitle(String title) => Center(
        child: Text(
          title,
          style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.registerTitle),
        ),
      );

  Widget _sheetButton(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.registerTitle,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
          ),
          child: Text(label,
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _buildField(String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(color: AppColors.registerTitle),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.registerTitle)),
      ),
    );
  }

  Widget _buildPassField(String hint, TextEditingController controller,
      bool obscure, VoidCallback toggleObscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(color: AppColors.registerTitle),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey,
              size: 20),
          onPressed: toggleObscure,
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.registerTitle)),
      ),
    );
  }

  Widget _buildSwitchTile(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.registerTitle,
        ),
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 14, color: AppColors.registerTitle)),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(text,
              style: GoogleFonts.cairo(
                  fontSize: 14, color: AppColors.registerTitle)),
          const SizedBox(width: 12),
          Icon(icon, color: AppColors.registerTitle, size: 20),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.cairo(), textAlign: TextAlign.right),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
