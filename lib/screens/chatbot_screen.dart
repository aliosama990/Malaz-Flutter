import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/models/child_mode.dart';
import 'package:malaz_app/screens/notifications_screen.dart';
import 'package:malaz_app/screens/safezone_screen.dart';
import 'package:malaz_app/screens/setting_child_screen.dart';
import 'package:provider/provider.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';
import '../providers/chatbot_provider.dart';
import 'chatbot_plus_screen.dart';
import 'child_details_screen.dart';
import 'setting_screen.dart'; // 

class ChatbotScreen extends StatefulWidget {
  final ChildModel child;
  const ChatbotScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 1;
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _headerController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
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
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatbotProvider =
          Provider.of<ChatbotProvider>(context, listen: false);
      if (chatbotProvider.chats.isEmpty) {
        chatbotProvider.loadDummyChats();
      }
      if (chatbotProvider.currentMessages.isEmpty) {
        chatbotProvider.addDummyMessages();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final chatbotProvider =
        Provider.of<ChatbotProvider>(context, listen: false);
    chatbotProvider.sendMessage(text);
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 4: // 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChildDetailsScreen(child: widget.child),
          ),
        );
        break;

      case 3: // 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SafeZonesScreen(child: widget.child),
          ),
        );
        break;

      case 2: // 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationsScreen(child: widget.child),
          ),
        );
        break;

      case 1: // 
        break;

      case 0: // 
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
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Consumer<ChatbotProvider>(
          builder: (context, chatbotProvider, child) {
            return Column(
              children: [
                SlideTransition(
                  position: _headerSlideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildHeader(),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: chatbotProvider.currentMessages.isEmpty
                          ? _buildEmptyState()
                          : _buildMessagesList(chatbotProvider),
                    ),
                  ),
                ),
                if (chatbotProvider.isLoading)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        color: AppColors.registerTitle,
                      ),
                    ),
                  ),
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildInputArea(),
                  ),
                ),
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBottomNavBar(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: const BoxDecoration(
        color: AppColors.registerTitle,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // أيقونة القائمة
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          // ✅ اسم الأهل ثابت لحد ما يتربط بالداتا بيز
          Text(
            'مروه عبد الرحمن',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.registerTitle,
      child: SafeArea(
        child: Consumer<ChatbotProvider>(
          builder: (context, chatbotProvider, child) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      textAlign: TextAlign.left,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Icon(Icons.search,
                              color: Colors.white.withOpacity(0.7), size: 22),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    onTap: () {
                      chatbotProvider.startNewChat();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'New Chat',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: chatbotProvider.chats.isEmpty
                      ? const SizedBox.shrink()
                      : Stack(
                          children: [
                            Positioned(
                              left: 24,
                              top: 0,
                              bottom: 0,
                              child: CustomPaint(
                                size: const Size(2, double.infinity),
                                painter: DashedLinePainter(),
                              ),
                            ),
                            ListView.builder(
                              padding:
                                  const EdgeInsets.only(left: 44, right: 16),
                              itemCount: chatbotProvider.chats.length,
                              itemBuilder: (context, index) {
                                final chat = chatbotProvider.chats[index];
                                return InkWell(
                                  onTap: () {
                                    chatbotProvider.selectChat(chat);
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 8),
                                    child: Text(
                                      chat.title,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400),
                                      textAlign: TextAlign.left,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    children: [
                      const Text(
                        'Premium Membership',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.chatbotPremiumDescription,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ChatbotPlusScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 44, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'الترقية',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.chatbotWelcomeMessage,
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF224D67)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.chatbotHowCanHelp,
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9E9E9E)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(ChatbotProvider chatbotProvider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: chatbotProvider.currentMessages.length,
      itemBuilder: (context, index) {
        final message = chatbotProvider.currentMessages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.registerTitle
              : const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: message.isUser ? Colors.white : Colors.black,
            height: 1.4,
          ),
          textAlign: message.isUser ? TextAlign.right : TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD3D5D2).withOpacity(0.92),
          borderRadius: BorderRadius.circular(50),
        ),
        child: TextField(
          controller: _messageController,
          textAlign: TextAlign.right,
          maxLines: null,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4A4A4A),
          ),
          decoration: InputDecoration(
            hintText: 'اكتب رسالة',
            hintStyle: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF686767),
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: IconButton(
                icon:
                    const Icon(Icons.send, color: Color(0xFF6B6B6B), size: 22),
                onPressed: _sendMessage,
              ),
            ),
          ),
          onSubmitted: (_) => _sendMessage(),
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

// CustomPainter للخط المنقط
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 5;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
