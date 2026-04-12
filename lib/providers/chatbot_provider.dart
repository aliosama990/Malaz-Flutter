import 'package:flutter/foundation.dart';

import '../models/chatbot_models.dart';
import '../services/api_service.dart';
import '../services/chatbot_service.dart';

class Message {
  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.content,
    this.rawData,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final dynamic content;
  final Map<String, dynamic>? rawData;
}

class Chat {
  Chat({
    required this.id,
    required this.title,
    required this.messages,
    this.sessionId,
    this.rawData,
  });

  final String id;
  final String title;
  final List<Message> messages;
  final String? sessionId;
  final Map<String, dynamic>? rawData;

  Chat copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    String? sessionId,
    Map<String, dynamic>? rawData,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      rawData: rawData ?? this.rawData,
    );
  }
}

class ChatbotProvider with ChangeNotifier {
  ChatbotProvider({ChatbotService? chatbotService})
      : _chatbotService = chatbotService ?? ChatbotService();

  static const String _newChatTitle = 'محادثة جديدة';
  static const int _chatTitleMaxLength = 30;

  final ChatbotService _chatbotService;

  List<Chat> _chats = const [];
  Chat? _currentChat;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  Future<void>? _bootstrapFuture;

  List<Chat> get chats => _chats;
  List<Message> get currentMessages => _currentChat?.messages ?? const [];
  Chat? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String? get currentSessionId => _currentChat?.sessionId;

  Future<void> initialize() {
    return _bootstrap();
  }

  void loadDummyChats() {
    _bootstrap();
  }

  void addDummyMessages() {
    _bootstrap();
  }

  void selectChat(Chat chat) {
    _selectChatAsync(chat);
  }

  void startNewChat() {
    _errorMessage = null;
    _currentChat = Chat(
      id: _createLocalChatId(),
      title: _newChatTitle,
      messages: const [],
    );
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isSending) {
      return;
    }

    _errorMessage = null;
    _isSending = true;

    final activeChat = _currentChat ?? _createDraftChat(trimmedText);
    final optimisticChat = activeChat.copyWith(
      title: _resolveOutgoingTitle(activeChat.title, trimmedText),
      messages: <Message>[
        ...activeChat.messages,
        Message(
          text: trimmedText,
          isUser: true,
          content: trimmedText,
        ),
      ],
    );

    _setCurrentChat(optimisticChat, previousId: activeChat.id);

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _chatbotService.sendMessage(
        message: trimmedText,
        sessionId: optimisticChat.sessionId,
      );

      final updatedChat = optimisticChat.copyWith(
        id: response.sessionId,
        sessionId: response.sessionId,
        title: _resolveOutgoingTitle(optimisticChat.title, trimmedText),
        messages: <Message>[
          ...optimisticChat.messages,
          ..._buildReplyMessages(response),
        ],
        rawData: response.rawData,
      );

      _setCurrentChat(updatedChat, previousId: optimisticChat.id);
    } on ApiException catch (error) {
      _errorMessage = _getApiErrorMessage(error);
    } catch (_) {
      _errorMessage = 'Unexpected response shape.';
    } finally {
      _isSending = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sessions = await _chatbotService.getSessions();
      final existingChatsBySessionId = <String, Chat>{
        for (final chat in _chats)
          if (chat.sessionId != null) chat.sessionId!: chat,
      };

      final draftChats = _chats
          .where((chat) => chat.sessionId == null)
          .toList(growable: false);
      final remoteChats = sessions.map((session) {
        final existingChat = existingChatsBySessionId[session.sessionId];

        return Chat(
          id: session.sessionId,
          sessionId: session.sessionId,
          title: _resolveSessionTitle(existingChat, session),
          messages: existingChat?.messages ?? const [],
          rawData: session.rawData,
        );
      }).toList(growable: false);

      _chats = <Chat>[
        ...draftChats,
        ...remoteChats,
      ];
      _currentChat = _resolveCurrentChat(_currentChat);
      return true;
    } on ApiException catch (error) {
      _errorMessage = _getApiErrorMessage(error);
      return false;
    } catch (_) {
      _errorMessage = 'Unexpected response shape.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchSessionMessages(String sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final messageModels = await _chatbotService.getSessionMessages(sessionId);
      final existingChat = _findChatBySessionId(sessionId) ??
          Chat(
            id: sessionId,
            sessionId: sessionId,
            title: sessionId,
            messages: const [],
          );

      final messages = _flattenMessages(messageModels);
      final updatedChat = existingChat.copyWith(
        messages: messages,
        title: _resolveTitleFromMessages(
          existingChat.title,
          existingChat.sessionId,
          messages,
        ),
      );

      _upsertChat(updatedChat, previousId: existingChat.id);
      if (_shouldKeepFetchedChatActive(sessionId, existingChat.id)) {
        _currentChat = _resolveCurrentChat(updatedChat);
      }
      return true;
    } on ApiException catch (error) {
      _errorMessage = _getApiErrorMessage(error);
      return false;
    } catch (_) {
      _errorMessage = 'Unexpected response shape.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapFuture != null) {
      await _bootstrapFuture;
      return;
    }

    _bootstrapFuture = _loadInitialState();
    try {
      await _bootstrapFuture;
    } finally {
      _bootstrapFuture = null;
    }
  }

  Future<void> _loadInitialState() async {
    final loaded = await fetchSessions();
    if (!loaded) {
      return;
    }

    Chat? firstRemoteChat;
    for (final chat in _chats) {
      if (chat.sessionId != null) {
        firstRemoteChat = chat;
        break;
      }
    }

    if (_currentChat == null && firstRemoteChat != null) {
      await fetchSessionMessages(firstRemoteChat.sessionId!);
      return;
    }

    final sessionId = _currentChat?.sessionId;
    if (sessionId != null && currentMessages.isEmpty) {
      await fetchSessionMessages(sessionId);
    }
  }

  Future<void> _selectChatAsync(Chat chat) async {
    final resolvedChat = _findChatById(chat.id) ?? chat;
    _currentChat = resolvedChat;
    _errorMessage = null;
    notifyListeners();

    final sessionId = resolvedChat.sessionId;
    if (sessionId == null || resolvedChat.messages.isNotEmpty) {
      return;
    }

    await fetchSessionMessages(sessionId);
  }

  Chat _createDraftChat(String firstMessageText) {
    final draftChat = Chat(
      id: _createLocalChatId(),
      title: _buildChatTitle(firstMessageText),
      messages: const [],
    );

    _chats = <Chat>[draftChat, ..._chats];
    _currentChat = draftChat;
    return draftChat;
  }

  void _setCurrentChat(Chat chat, {String? previousId}) {
    _upsertChat(chat, previousId: previousId);
    _currentChat = _resolveCurrentChat(chat);
  }

  bool _shouldKeepFetchedChatActive(String sessionId, String chatId) {
    final activeChat = _currentChat;
    if (activeChat == null) {
      return true;
    }

    if (activeChat.id == chatId) {
      return true;
    }

    return activeChat.sessionId == sessionId;
  }

  void _upsertChat(Chat updatedChat, {String? previousId}) {
    final updatedChats = List<Chat>.from(_chats);
    final index = updatedChats.indexWhere((chat) {
      if (previousId != null && chat.id == previousId) {
        return true;
      }

      if (chat.id == updatedChat.id) {
        return true;
      }

      return updatedChat.sessionId != null &&
          chat.sessionId == updatedChat.sessionId;
    });

    if (index == -1) {
      updatedChats.insert(0, updatedChat);
    } else {
      updatedChats[index] = updatedChat;
    }

    _chats = updatedChats;
  }

  Chat? _resolveCurrentChat(Chat? candidate) {
    if (candidate == null) {
      return null;
    }

    for (final chat in _chats) {
      if (chat.id == candidate.id) {
        return chat;
      }

      if (candidate.sessionId != null &&
          chat.sessionId == candidate.sessionId) {
        return chat;
      }
    }

    return candidate;
  }

  Chat? _findChatById(String id) {
    for (final chat in _chats) {
      if (chat.id == id) {
        return chat;
      }
    }

    return null;
  }

  Chat? _findChatBySessionId(String sessionId) {
    for (final chat in _chats) {
      if (chat.sessionId == sessionId) {
        return chat;
      }
    }

    return null;
  }

  List<Message> _flattenMessages(List<ChatbotMessageModel> messageModels) {
    final flattenedMessages = <Message>[];

    for (final messageModel in messageModels) {
      final userMessage = _buildMessage(
        content: messageModel.message,
        isUser: true,
        rawData: messageModel.rawData,
      );
      if (userMessage != null) {
        flattenedMessages.add(userMessage);
      }

      final botMessage = _buildMessage(
        content: messageModel.botReply,
        isUser: false,
        rawData: messageModel.rawData,
      );
      if (botMessage != null) {
        flattenedMessages.add(botMessage);
      }
    }

    return flattenedMessages;
  }

  List<Message> _buildReplyMessages(TalkChatResponseModel response) {
    final botMessage = _buildMessage(
      content: response.botReply,
      isUser: false,
      rawData: response.rawData,
    );

    if (botMessage == null) {
      return const [];
    }

    return <Message>[botMessage];
  }

  Message? _buildMessage({
    required dynamic content,
    required bool isUser,
    required Map<String, dynamic>? rawData,
  }) {
    final text = _contentToText(content);
    if (text == null) {
      return null;
    }

    return Message(
      text: text,
      isUser: isUser,
      content: content,
      rawData: rawData,
    );
  }

  String? _contentToText(dynamic content) {
    return ChatbotContentParser.extractText(content);
  }

  String _resolveSessionTitle(
    Chat? existingChat,
    ChatbotSessionModel sessionModel,
  ) {
    if (existingChat == null) {
      return sessionModel.sessionId;
    }

    if (existingChat.title.trim().isEmpty ||
        existingChat.title == _newChatTitle ||
        existingChat.title == existingChat.sessionId) {
      return sessionModel.sessionId;
    }

    return existingChat.title;
  }

  String _resolveOutgoingTitle(String currentTitle, String fallbackText) {
    if (currentTitle.trim().isEmpty || currentTitle == _newChatTitle) {
      return _buildChatTitle(fallbackText);
    }

    return currentTitle;
  }

  String _resolveTitleFromMessages(
    String currentTitle,
    String? sessionId,
    List<Message> messages,
  ) {
    if (currentTitle.trim().isNotEmpty &&
        currentTitle != _newChatTitle &&
        currentTitle != sessionId) {
      return currentTitle;
    }

    for (final message in messages) {
      if (message.isUser && message.text.trim().isNotEmpty) {
        return _buildChatTitle(message.text);
      }
    }

    return currentTitle;
  }

  String _buildChatTitle(String text) {
    if (text.length <= _chatTitleMaxLength) {
      return text;
    }

    return '${text.substring(0, _chatTitleMaxLength)}...';
  }

  String _createLocalChatId() {
    return 'draft-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _getApiErrorMessage(ApiException error) {
    if (error.errorMessages.isNotEmpty) {
      return error.errorMessages.join('\n');
    }

    return error.message;
  }
}
