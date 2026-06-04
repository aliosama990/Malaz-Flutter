import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malaz_app/constants/app_strings.dart';
import 'package:malaz_app/models/chatbot_models.dart';
import 'package:malaz_app/models/child_mode.dart';
import 'package:malaz_app/providers/auth_provider.dart';
import 'package:malaz_app/providers/chatbot_provider.dart';
import 'package:malaz_app/screens/chatbot_screen.dart';
import 'package:malaz_app/services/chatbot_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'keeps the bot reply visible when initial chatbot bootstrap finishes late',
    (tester) async {
      final chatbotService = _DelayedBootstrapChatbotService();
      final chatbotProvider = ChatbotProvider(chatbotService: chatbotService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(),
            ),
            ChangeNotifierProvider<ChatbotProvider>.value(
              value: chatbotProvider,
            ),
          ],
          child: MaterialApp(
            home: ChatbotScreen(
              child: ChildModel(
                id: 'child-1',
                name: 'Ali',
                birthDate: '2018-05-10',
                gender: 0,
                deviceId: 'watch123',
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 250));

      final inputFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText ==
                '${AppStrings.chatbotTypeMessage}...',
      );

      expect(inputFinder, findsOneWidget);

      await tester.enterText(inputFinder, 'كيف حال طفلي؟');
      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pump();

      expect(find.text('كيف حال طفلي؟'), findsOneWidget);
      expect(
          find.text(_DelayedBootstrapChatbotService.botReply), findsOneWidget);

      chatbotService.completeBootstrap();
      await tester.pump();

      expect(find.text('كيف حال طفلي؟'), findsOneWidget);
      expect(
          find.text(_DelayedBootstrapChatbotService.botReply), findsOneWidget);
    },
  );
}

class _DelayedBootstrapChatbotService extends ChatbotService {
  static const String botReply =
      'هذا رد كامل وطويل من البوت يجب أن يبقى ظاهراً بالكامل بعد انتهاء التهيئة المتأخرة.';

  final Completer<void> _bootstrapCompleter = Completer<void>();

  void completeBootstrap() {
    if (!_bootstrapCompleter.isCompleted) {
      _bootstrapCompleter.complete();
    }
  }

  @override
  Future<List<ChatbotSessionModel>> getSessions() async {
    await _bootstrapCompleter.future;
    return const <ChatbotSessionModel>[];
  }

  @override
  Future<TalkChatResponseModel> sendMessage({
    required String message,
    String? sessionId,
  }) async {
    return TalkChatResponseModel.fromJson(
      <String, dynamic>{
        'sessionId': sessionId ?? 'session-1',
        'message': message,
        'botReply': botReply,
      },
    );
  }
}
