import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/assistant/domain/entities/assistant_reply_entity.dart';
import 'package:note_sondage/feature/assistant/infrastructure/data_source/assistant_remote_data_source.dart';
import 'package:note_sondage/feature/assistant/ui/assistant_dialog.dart';
import 'package:note_sondage/feature/assistant/ui/assistant_session.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class _FakeRemote extends AssistantRemoteDataSource {
  _FakeRemote(this._answer);

  final Future<AssistantReplyEntity> Function(String message, String? id)
  _answer;
  final List<String?> conversationIds = <String?>[];
  final List<String> deleted = <String>[];

  @override
  Future<AssistantReplyEntity> sendMessage({
    required String message,
    String? conversationId,
  }) {
    conversationIds.add(conversationId);
    return _answer(message, conversationId);
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    deleted.add(conversationId);
  }
}

Widget _host(AssistantSession session) {
  return MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: AssistantDialog(session: session)),
  );
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('assistant_input')), text);
  await tester.tap(find.byKey(const Key('assistant_send')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'sends the message and shows the reply, keeping the conversation',
    (tester) async {
      final remote = _FakeRemote(
        (message, id) async => const AssistantReplyEntity(
          conversationId: 'conv-1',
          reply: 'Fatto: ho creato il team pipooo.',
          executedTools: ['create_team'],
        ),
      );
      final session = AssistantSession(remote: remote);
      await tester.pumpWidget(_host(session));

      expect(find.textContaining('Chiedimi qualsiasi cosa'), findsOneWidget);

      await _type(tester, 'Crea un team pipooo');
      expect(find.text('Crea un team pipooo'), findsOneWidget);
      expect(find.text('Fatto: ho creato il team pipooo.'), findsOneWidget);

      await _type(tester, 'invita pipo1@gmail.com');
      expect(remote.conversationIds, [null, 'conv-1']);
    },
  );

  testWidgets('shows a dedicated message when the assistant is disabled', (
    tester,
  ) async {
    final session = AssistantSession(
      remote: _FakeRemote(
        (_, _) async => throw const AssistantUnavailableException(),
      ),
    );
    await tester.pumpWidget(_host(session));

    await _type(tester, 'ciao');

    expect(
      find.text("L'assistente non è disponibile in questo momento."),
      findsOneWidget,
    );
  });

  test('a different user never sees the previous conversation', () async {
    final remote = _FakeRemote(
      (_, _) async => const AssistantReplyEntity(
        conversationId: 'conv-1',
        reply: 'ok',
        executedTools: [],
      ),
    );
    final session = AssistantSession(remote: remote)..bindUser('laura');
    await session.send('timbra');
    expect(session.messages, hasLength(2));

    session.bindUser('laura');
    expect(session.messages, hasLength(2));

    session.bindUser('marco');
    expect(session.messages, isEmpty);
    await session.send('ciao');
    expect(remote.conversationIds.last, isNull);
  });
}
