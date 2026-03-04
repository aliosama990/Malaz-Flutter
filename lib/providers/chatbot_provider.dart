import 'package:flutter/foundation.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class Chat {
  final String id;
  final String title;
  final List<Message> messages;

  Chat({
    required this.id,
    required this.title,
    required this.messages,
  });
}

class ChatbotProvider with ChangeNotifier {
  List<Chat> _chats = [];
  Chat? _currentChat;
  bool _isLoading = false;

  List<Chat> get chats => _chats;
  List<Message> get currentMessages => _currentChat?.messages ?? [];
  bool get isLoading => _isLoading;

  void loadDummyChats() {
    _chats = [
      Chat(
        id: '1',
        title: 'أريد انا اعرف كيفية التواص...',
        messages: [],
      ),
      Chat(
        id: '2',
        title: 'نصائح لتحسين التركيز',
        messages: [],
      ),
      Chat(
        id: '3',
        title: 'كيف اتعامل مع نوبات الغضب',
        messages: [],
      ),
    ];
    notifyListeners();
  }

  void addDummyMessages() {
    if (_currentChat == null) {
      _currentChat = Chat(
        id: DateTime.now().toString(),
        title: 'محادثة جديدة',
        messages: [],
      );
    }

    // إضافة رسائل dummy للعرض
    _currentChat!.messages.addAll([
      Message(
        text: 'مرحباً! أنا هنا لمساعدتك في تربية طفلك كيف اساعدك اليوم',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Message(
        text:
            'أريد انا اعرف كيفية التواصل الصحيحة مع اطفالي في اعرف مع ان مشعتم ضربا',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
      Message(
        text: 'فهمتك.. الوقت المناسب.. تختلف:\n'
            '1. اختيار الوقت المناسب بعد الممارسة مباشرة ان كان متعب\n'
            '2. ابدئ بالاستماع قبل الكلام و تحلى بالصبر\n'
            '3. اظهر التعاطف قبل التصحيح\n'
            '4. استخدم اسئلة مفتوحة\n'
            '5. كون هادئ\n'
            '6. اعتمد الوفوض الايجابي في الكلام\n'
            '7. اعتمد الإشارات الغير لفظية الإيجابية\n'
            '8. مدح الشجاعة على الصراحة\n'
            '9. شاركه من همومك همعه في يشعر بانه الدور وطبيعي غير مدعاه',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    ]);

    notifyListeners();
  }

  void selectChat(Chat chat) {
    _currentChat = chat;

  
    if (_currentChat!.messages.isEmpty) {
      _currentChat!.messages.addAll([
        Message(
          text: chat.title,
          isUser: true,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Message(
          text: 'شكراً على سؤالك! دعني أساعدك في هذا الموضوع...',
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ]);
    }

    notifyListeners();
  }

  void startNewChat() {
    _currentChat = Chat(
      id: DateTime.now().toString(),
      title: 'محادثة جديدة',
      messages: [],
    );
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (_currentChat == null) {
      _currentChat = Chat(
        id: DateTime.now().toString(),
        title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
        messages: [],
      );
      _chats.insert(0, _currentChat!);
    }

    
    _currentChat!.messages.add(Message(text: text, isUser: true));
    notifyListeners();

   
    _isLoading = true;
    notifyListeners();


    await Future.delayed(const Duration(seconds: 1));

 
    _currentChat!.messages.add(
      Message(
        text: _getBotResponse(text),
        isUser: false,
      ),
    );

    _isLoading = false;
    notifyListeners();
  }

  String _getBotResponse(String userMessage) {
    // ردود تلقائية بسيطة
    if (userMessage.contains('مساعدة') || userMessage.contains('ساعدني')) {
      return 'بالتأكيد! أنا هنا لمساعدتك. كيف يمكنني مساعدتك في تربية طفلك؟';
    } else if (userMessage.contains('شكر')) {
      return 'العفو! سعيد بمساعدتك. هل هناك شيء آخر تريد معرفته؟';
    } else if (userMessage.contains('طفل') || userMessage.contains('ابن')) {
      return 'التعامل مع الأطفال يتطلب الصبر والفهم. حاول أن تستمع لهم جيداً وتفهم احتياجاتهم.';
    } else {
      return 'فهمت سؤالك. دعني أساعدك في ذلك. يمكنني تقديم نصائح مخصصة بناءً على احتياجاتك.';
    }
  }
}
