import '../models/chatbot_models.dart';
import 'api_service.dart';

class ChatbotService {
  ChatbotService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<TalkChatResponseModel> sendMessage({
    required String message,
    String? sessionId,
  }) async {
    final response = await _apiService.post(
      '/Chatbot/Talk-chat',
      body: <String, dynamic>{
        'message': message,
        if (sessionId != null && sessionId.trim().isNotEmpty)
          'sessionId': sessionId,
      },
    );

    return _parseTalkChatResponse(response);
  }

  Future<List<ChatbotSessionModel>> getSessions() async {
    final response = await _apiService.get('/Chatbot/sessions');

    try {
      return _requireList(response.data)
          .map(ChatbotSessionModel.fromResponseItem)
          .toList(growable: false);
    } on FormatException {
      throw ApiException(
        'Unexpected response shape.',
        statusCode: response.statusCode,
        responseBody: response.rawBody,
      );
    }
  }

  Future<List<ChatbotMessageModel>> getSessionMessages(String sessionId) async {
    final response = await _apiService.get(
      '/Chatbot/sessions/$sessionId/messages',
    );

    try {
      return _requireList(response.data)
          .map(ChatbotMessageModel.fromResponseItem)
          .toList(growable: false);
    } on FormatException {
      throw ApiException(
        'Unexpected response shape.',
        statusCode: response.statusCode,
        responseBody: response.rawBody,
      );
    }
  }

  TalkChatResponseModel _parseTalkChatResponse(ApiResponse response) {
    try {
      return TalkChatResponseModel.fromJson(_requireMap(response.data));
    } on FormatException {
      throw ApiException(
        'Unexpected response shape.',
        statusCode: response.statusCode,
        responseBody: response.rawBody,
      );
    }
  }

  Map<String, dynamic> _requireMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw const FormatException('Invalid ChatBot response map.');
  }

  List<dynamic> _requireList(dynamic value) {
    if (value is List) {
      return List<dynamic>.from(value);
    }

    throw const FormatException('Invalid ChatBot response list.');
  }
}
