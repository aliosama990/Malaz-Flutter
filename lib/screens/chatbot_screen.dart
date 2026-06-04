import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/models/child_mode.dart';
import 'package:provider/provider.dart';
import '../constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/chatbot_provider.dart';
import '../widgets/initial_avatar.dart';
import 'chatbot_plus_screen.dart';
import 'home_screen.dart';

class ChatbotScreen extends StatefulWidget {
  final ChildModel child;
  const ChatbotScreen({super.key, required this.child});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  static const Color _referencePurple = Color(0xFF756DC0);
  static const Color _messagePurple = Color(0xFF686AA0);
  static const Color _softBubble = Color(0xFFF1F1F1);
  static const Color _inkBlue = Color(0xFF07335F);

  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  String? _queuedProviderError;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatbotProvider =
          Provider.of<ChatbotProvider>(context, listen: false);
      if (chatbotProvider.currentChat == null) {
        chatbotProvider.startNewChat();
      }
      await chatbotProvider.initialize();
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

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
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
    final chatbotProvider =
        Provider.of<ChatbotProvider>(context, listen: false);
    if (chatbotProvider.isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    chatbotProvider.sendMessage(text);
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _handleProviderError(ChatbotProvider chatbotProvider) {
    final errorMessage = chatbotProvider.errorMessage;
    if (errorMessage == null ||
        errorMessage.trim().isEmpty ||
        _queuedProviderError == errorMessage) {
      return;
    }

    _queuedProviderError = errorMessage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _queuedProviderError = null;
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );

      if (chatbotProvider.errorMessage == errorMessage) {
        chatbotProvider.clearError();
      }
      _queuedProviderError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      body: Consumer<ChatbotProvider>(
        builder: (context, chatbotProvider, child) {
          _handleProviderError(chatbotProvider);
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
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildInputArea(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final topPadding = MediaQuery.paddingOf(context).top;
    final user = context.watch<AuthProvider>().user;
    final userName = user?.name ?? '';
    final parentGender = user?.parentGender;

    return Container(
      height: topPadding + scaled(96),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _referencePurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(scaled(24)),
          bottomRight: Radius.circular(scaled(6)),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: scaled(18),
            top: topPadding + scaled(28),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: scaled(40),
                minHeight: scaled(40),
              ),
              icon: Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: scaled(28),
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
          Positioned(
            right: scaled(86),
            top: topPadding + scaled(12),
            child: Material(
              color: Colors.white.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(scaled(18)),
              child: InkWell(
                borderRadius: BorderRadius.circular(scaled(18)),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scaled(12),
                    vertical: scaled(5),
                  ),
                  child: Text(
                    'رجوع للرئيسية ←',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(10.5),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: scaled(78),
            bottom: scaled(18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.62,
              ),
              child: Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: scaled(16),
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: scaled(16),
            bottom: scaled(-5),
            child: InitialAvatar(
              label: userName,
              radius: scaled(25),
              backgroundColor: const Color(0xFF95D8F8),
              foregroundColor: Colors.black,
              role: AvatarRole.parent,
              parentGender: parentGender,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth =
        (screenWidth * 0.56).clamp(scaled(320), scaled(520)).toDouble();

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: scaled(2)),
        decoration: BoxDecoration(
          color: _messagePurple,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(scaled(34)),
            bottomLeft: Radius.circular(scaled(34)),
          ),
        ),
        child: SafeArea(
          child: Consumer<ChatbotProvider>(
            builder: (context, chatbotProvider, child) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  scaled(24),
                  scaled(28),
                  scaled(24),
                  scaled(26),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: scaled(472)),
                          child: Column(
                            children: [
                              Container(
                                height: scaled(58),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.96),
                                  borderRadius:
                                      BorderRadius.circular(scaled(30)),
                                ),
                                child: TextField(
                                  textAlign: TextAlign.left,
                                  style: GoogleFonts.cairo(
                                    color: Colors.black,
                                    fontSize: scaled(15),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    hintStyle: GoogleFonts.cairo(
                                      color: Colors.black,
                                      fontSize: scaled(15),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(
                                        left: scaled(26),
                                        right: scaled(22),
                                      ),
                                      child: Icon(
                                        Icons.search_rounded,
                                        color: Colors.black,
                                        size: scaled(24),
                                      ),
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: scaled(54),
                                      minHeight: scaled(58),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: scaled(20),
                                      vertical: scaled(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: scaled(48)),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(scaled(18)),
                                  onTap: () {
                                    chatbotProvider.startNewChat();
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: scaled(32),
                                      vertical: scaled(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white,
                                          size: scaled(24),
                                        ),
                                        SizedBox(width: scaled(12)),
                                        Text(
                                          'New Chat',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: scaled(16),
                                            fontWeight: FontWeight.w500,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: scaled(28)),
                              SizedBox(
                                height: scaled(180),
                                child: chatbotProvider.chats.isEmpty
                                    ? const SizedBox.shrink()
                                    : Stack(
                                        children: [
                                          Positioned(
                                            left: scaled(36),
                                            top: scaled(12),
                                            bottom: scaled(16),
                                            child: CustomPaint(
                                              size: Size(
                                                scaled(3),
                                                double.infinity,
                                              ),
                                              painter: DashedLinePainter(),
                                            ),
                                          ),
                                          ListView.separated(
                                            padding: EdgeInsets.only(
                                              left: scaled(68),
                                              right: scaled(10),
                                            ),
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount:
                                                chatbotProvider.chats.length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: scaled(31)),
                                            itemBuilder: (context, index) {
                                              final chat =
                                                  chatbotProvider.chats[index];
                                              return InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  scaled(12),
                                                ),
                                                onTap: () {
                                                  chatbotProvider
                                                      .selectChat(chat);
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  chat.title,
                                                  style: GoogleFonts.cairo(
                                                    color: Colors.white,
                                                    fontSize: scaled(15),
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.15,
                                                  ),
                                                  textAlign: TextAlign.left,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                              ),
                              const Spacer(),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Premium Membership',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: scaled(20),
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: scaled(16)),
                                    Text(
                                      AppStrings.chatbotPremiumDescription,
                                      style: GoogleFonts.cairo(
                                        color: Colors.white
                                            .withValues(alpha: 0.62),
                                        fontSize: scaled(13),
                                        fontWeight: FontWeight.w500,
                                        height: 1.32,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: scaled(28)),
                                    SizedBox(
                                      width: scaled(128),
                                      height: scaled(48),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ChatbotPlusScreen(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF245676),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              scaled(18),
                                            ),
                                            side: BorderSide(
                                              color: Colors.white,
                                              width: scaled(1.5),
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'الترقية',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: scaled(15),
                                            fontWeight: FontWeight.w800,
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
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          scaled(18),
          scaled(28),
          scaled(18),
          scaled(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: EdgeInsets.fromLTRB(
                  scaled(18),
                  scaled(14),
                  scaled(18),
                  scaled(16),
                ),
                decoration: BoxDecoration(
                  color: _softBubble,
                  borderRadius: BorderRadius.circular(scaled(56)),
                ),
                child: Text(
                  'مرحبًا! أنا هنا لمساعدتك في تربية طفلك، كيف أساعدك اليوم؟',
                  style: GoogleFonts.cairo(
                    fontSize: scaled(15),
                    height: 1.28,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(ChatbotProvider chatbotProvider) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    final messages = chatbotProvider.currentMessages;
    final showTypingIndicator = chatbotProvider.isSending;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        scaled(18),
        scaled(22),
        scaled(18),
        scaled(20),
      ),
      itemCount: messages.length + (showTypingIndicator ? 1 : 0),
      itemBuilder: (context, index) {
        if (showTypingIndicator && index == messages.length) {
          return _buildTypingIndicatorBubble();
        }

        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final isUser = message.isUser;
    final messageBubble = Container(
      margin: EdgeInsets.only(bottom: scaled(14)),
      padding: EdgeInsets.fromLTRB(
        scaled(18),
        scaled(12),
        scaled(18),
        scaled(14),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.64 : 0.72),
      ),
      decoration: BoxDecoration(
        color: isUser ? _messagePurple : _softBubble,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(scaled(40)),
          topRight: Radius.circular(scaled(40)),
          bottomLeft: Radius.circular(scaled(isUser ? 12 : 40)),
          bottomRight: Radius.circular(scaled(isUser ? 40 : 12)),
        ),
      ),
      child: Text(
        message.text,
        style: GoogleFonts.cairo(
          fontSize: scaled(15),
          fontWeight: FontWeight.w500,
          color: isUser ? Colors.white : Colors.black,
          height: 1.28,
        ),
        textAlign: TextAlign.right,
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: messageBubble,
    );
  }

  Widget _buildTypingIndicatorBubble() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: scaled(14)),
        padding: EdgeInsets.symmetric(
          horizontal: scaled(16),
          vertical: scaled(12),
        ),
        decoration: BoxDecoration(
          color: _softBubble,
          borderRadius: BorderRadius.circular(scaled(34)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: scaled(6),
              height: scaled(6),
              margin: EdgeInsets.only(right: index == 2 ? 0 : scaled(4)),
              decoration: const BoxDecoration(
                color: Color(0xFF6B6B6B),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          scaled(18),
          scaled(12),
          scaled(18),
          scaled(18),
        ),
        color: Colors.white,
        child: Container(
          constraints: BoxConstraints(minHeight: scaled(52)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(scaled(30)),
            border: Border.all(
              color: const Color(0xFFC9C9C9),
              width: scaled(2),
            ),
          ),
          child: TextField(
            controller: _messageController,
            textAlign: TextAlign.right,
            maxLines: null,
            style: GoogleFonts.cairo(
              fontSize: scaled(15),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4A4A4A),
            ),
            decoration: InputDecoration(
              hintText: '${AppStrings.chatbotTypeMessage}...',
              hintStyle: GoogleFonts.cairo(
                fontSize: scaled(15),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF777777),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(
                scaled(16),
                scaled(10),
                scaled(18),
                scaled(10),
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: scaled(20), right: scaled(8)),
                child: IconButton(
                  icon: Icon(
                    Icons.send_outlined,
                    color: _inkBlue,
                    size: scaled(24),
                  ),
                  onPressed: _sendMessage,
                ),
              ),
            ),
            onSubmitted: (_) => _sendMessage(),
          ),
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
      ..color = Colors.white.withValues(alpha: 0.4)
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
