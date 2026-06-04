import 'dart:convert';

class ChatbotSessionModel {
  ChatbotSessionModel({
    required this.sessionId,
    required this.rawData,
  });

  final String sessionId;
  final Map<String, dynamic> rawData;

  factory ChatbotSessionModel.fromResponseItem(dynamic value) {
    if (value is String) {
      final sessionId = value.trim();
      if (sessionId.isEmpty) {
        throw const FormatException('Invalid ChatBot session item.');
      }

      return ChatbotSessionModel(
        sessionId: sessionId,
        rawData: <String, dynamic>{'sessionId': sessionId},
      );
    }

    if (value is Map) {
      return ChatbotSessionModel.fromJson(Map<String, dynamic>.from(value));
    }

    throw const FormatException('Invalid ChatBot session item.');
  }

  factory ChatbotSessionModel.fromJson(Map<String, dynamic> json) {
    final rawData = Map<String, dynamic>.from(json);

    return ChatbotSessionModel(
      sessionId: ChatbotContentParser.requireString(
        rawData,
        const ['sessionId', 'SessionId', 'id', 'Id'],
      ),
      rawData: rawData,
    );
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(rawData);
}

class ChatbotMessageModel {
  ChatbotMessageModel({
    this.sessionId,
    this.message,
    this.botReply,
    required this.rawData,
  });

  final String? sessionId;
  final dynamic message;
  final dynamic botReply;
  final Map<String, dynamic> rawData;

  factory ChatbotMessageModel.fromResponseItem(dynamic value) {
    if (value is Map) {
      return ChatbotMessageModel.fromJson(Map<String, dynamic>.from(value));
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && ChatbotContentParser.looksLikeJson(trimmed)) {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return ChatbotMessageModel.fromJson(
              Map<String, dynamic>.from(decoded));
        }
      }
    }

    throw const FormatException('Invalid ChatBot message item.');
  }

  factory ChatbotMessageModel.fromJson(Map<String, dynamic> json) {
    final rawData = Map<String, dynamic>.from(json);

    return ChatbotMessageModel(
      sessionId: ChatbotContentParser.readNullableString(
        rawData,
        const ['sessionId', 'SessionId'],
      ),
      message: ChatbotContentParser.parseNestedContent(
        ChatbotContentParser.readValue(
          rawData,
          const ['message', 'Message'],
        ),
      ),
      botReply: ChatbotContentParser.parseNestedContent(
        ChatbotContentParser.readValue(
          rawData,
          const ['reply', 'Reply', 'botReply', 'BotReply'],
        ),
      ),
      rawData: rawData,
    );
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(rawData);
}

class TalkChatResponseModel {
  TalkChatResponseModel({
    required this.sessionId,
    required this.chatMessage,
    required this.rawData,
  });

  final String sessionId;
  final ChatbotMessageModel chatMessage;
  final Map<String, dynamic> rawData;

  dynamic get message => chatMessage.message;
  dynamic get botReply => chatMessage.botReply;

  factory TalkChatResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = Map<String, dynamic>.from(json);

    return TalkChatResponseModel(
      sessionId: ChatbotContentParser.requireString(
        rawData,
        const ['sessionId', 'SessionId'],
      ),
      chatMessage: ChatbotMessageModel.fromJson(rawData),
      rawData: rawData,
    );
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(rawData);
}

class ChatbotContentParser {
  static const List<String> _preferredTextKeys = <String>[
    'reply',
    'Reply',
    'botReply',
    'BotReply',
    'message',
    'Message',
    'text',
    'Text',
    'content',
    'Content',
    'response',
    'Response',
    'answer',
    'Answer',
    'result',
    'Result',
    'parts',
    'Parts',
    'data',
    'Data',
    'value',
    'Value',
  ];
  static const Set<String> _nonDisplayKeys = <String>{
    'sessionId',
    'SessionId',
    'id',
    'Id',
    'role',
    'Role',
    'timestamp',
    'Timestamp',
    'createdAt',
    'CreatedAt',
  };

  static dynamic parseNestedContent(dynamic value) {
    return _normalizeValue(value);
  }

  static String? extractText(dynamic value) {
    return _extractText(parseNestedContent(value));
  }

  static dynamic readValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }

    return null;
  }

  static String requireString(Map<String, dynamic> json, List<String> keys) {
    final value = readNullableString(json, keys);
    if (value != null) {
      return value;
    }

    throw FormatException(
      'ChatBot field "${keys.first}" is missing or invalid.',
    );
  }

  static String? readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = readValue(json, keys);
    if (value == null) {
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    throw FormatException(
      'ChatBot field "${keys.first}" is missing or invalid.',
    );
  }

  static String? _extractText(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      if (looksLikeJson(trimmed)) {
        try {
          return _extractText(_normalizeValue(jsonDecode(trimmed)));
        } on FormatException {
          return trimmed;
        }
      }

      return trimmed;
    }

    if (value is num || value is bool) {
      return value.toString();
    }

    if (value is List) {
      final parts = value
          .map(_extractText)
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);

      if (parts.isEmpty) {
        return null;
      }

      return parts.join('\n');
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      for (final key in _preferredTextKeys) {
        if (!map.containsKey(key)) {
          continue;
        }

        final text = _extractText(map[key]);
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }

      for (final entry in map.entries) {
        if (_nonDisplayKeys.contains(entry.key)) {
          continue;
        }

        final text = _extractText(entry.value);
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }

      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || !looksLikeJson(trimmed)) {
        return value;
      }

      try {
        return _normalizeValue(jsonDecode(trimmed));
      } on FormatException {
        return value;
      }
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _normalizeValue(item)),
      );
    }

    if (value is List) {
      return value.map(_normalizeValue).toList(growable: false);
    }

    return value;
  }

  static bool looksLikeJson(String value) {
    if (value.length < 2) {
      return false;
    }

    final firstCharacter = value[0];
    final lastCharacter = value[value.length - 1];

    return (firstCharacter == '{' && lastCharacter == '}') ||
        (firstCharacter == '[' && lastCharacter == ']') ||
        (firstCharacter == '"' && lastCharacter == '"');
  }
}
