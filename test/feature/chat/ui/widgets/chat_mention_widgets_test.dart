import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/chat_mentions.dart';
import 'package:note_sondage/feature/chat/infrastructure/data_source/chat_remote_data_source.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_composer.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_mention_widgets.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

const _members = [
  ChatMentionCandidate(userId: 'me', displayName: 'Arthur'),
  ChatMentionCandidate(
    userId: 'u-anna',
    displayName: 'Anna Rossi',
    secondaryLabel: 'anna@example.com',
  ),
  ChatMentionCandidate(userId: 'u-luca', displayName: 'Luca'),
];

Widget _app(Widget child, {bool enabled = true}) {
  return MaterialApp(
    locale: const Locale('it'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: ChatMentionScope(
        enabled: enabled,
        candidates: _members,
        currentUserId: 'me',
        child: child,
      ),
    ),
  );
}

Widget _composer(TextEditingController controller) => ChatComposer(
  messageController: controller,
  compact: true,
  sending: false,
  accentColor: Colors.indigo,
  onPickImagePressed: () async => false,
  onPickDocumentPressed: () async => false,
  onClearAttachmentPressed: () {},
  onSendPressed: () {},
);

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode({'id': 'm1', 'conversationId': 'c1'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ChatComposer mention autocomplete', () {
    testWidgets('typing @ shows @tutti and members except me', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_composer(controller)));

      await tester.enterText(find.byType(TextField), '@');
      await tester.pump();

      expect(find.byKey(const Key('chat_mention_all')), findsOneWidget);
      expect(find.text('@tutti'), findsOneWidget);
      expect(find.byKey(const Key('chat_mention_u-anna')), findsOneWidget);
      expect(find.byKey(const Key('chat_mention_u-luca')), findsOneWidget);
      expect(find.byKey(const Key('chat_mention_me')), findsNothing);
    });

    testWidgets('filters and inserts the selected member', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_composer(controller)));

      await tester.enterText(find.byType(TextField), 'ciao @ann');
      await tester.pump();
      expect(find.byKey(const Key('chat_mention_u-luca')), findsNothing);

      await tester.tap(find.byKey(const Key('chat_mention_u-anna')));
      await tester.pump();

      expect(controller.text, 'ciao @Anna Rossi ');
      expect(find.byKey(const Key('chat_mention_u-anna')), findsNothing);
    });

    testWidgets('inserts the localized @tutti', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_composer(controller)));

      await tester.enterText(find.byType(TextField), '@tu');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat_mention_all')));
      await tester.pump();

      expect(controller.text, '@tutti ');
    });

    testWidgets('no suggestions in direct chats (scope disabled)', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_composer(controller), enabled: false));

      await tester.enterText(find.byType(TextField), '@');
      await tester.pump();

      expect(find.byType(ChatMentionSuggestions), findsNothing);
    });
  });

  group('ChatMentionText', () {
    List<TextSpan> mentionSpans(WidgetTester tester) {
      final rich = tester.widget<Text>(find.byType(Text)).textSpan!;
      return (rich as TextSpan).children!
          .whereType<TextSpan>()
          .where((s) => s.style?.fontWeight == FontWeight.w800)
          .toList();
    }

    testWidgets('highlights a mention of me more strongly', (tester) async {
      await tester.pumpWidget(
        _app(const ChatMentionText('@Arthur e @Luca guardate')),
      );

      final spans = mentionSpans(tester);
      expect(spans.map((s) => s.text), ['@Arthur', '@Luca']);
      expect(
        spans[0].style!.backgroundColor,
        isNot(spans[1].style!.backgroundColor),
      );
    });

    testWidgets('plain text when there are no mentions', (tester) async {
      await tester.pumpWidget(_app(const ChatMentionText('ciao a tutti')));

      expect(tester.widget<Text>(find.byType(Text)).data, 'ciao a tutti');
    });
  });

  group('ChatRemoteDataSource sends mentions', () {
    late _CapturingAdapter adapter;
    late ChatRemoteDataSource dataSource;

    setUp(() {
      adapter = _CapturingAdapter();
      dataSource = ChatRemoteDataSource(
        dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..httpClientAdapter = adapter,
      );
    });

    test('includes mentionedUserIds and mentionAll in the JSON body', () async {
      await dataSource.sendMessage(
        'c1',
        '@Luca @tutti',
        mentions: const ChatMentions(userIds: ['u-luca'], all: true),
      );

      expect(adapter.lastRequest!.data, {
        'content': '@Luca @tutti',
        'mentionedUserIds': ['u-luca'],
        'mentionAll': true,
      });
    });

    test('omits mention fields when there are none', () async {
      await dataSource.sendMessage('c1', 'ciao');

      expect(adapter.lastRequest!.data, {'content': 'ciao'});
    });

    test('multipart repeats mentionedUserIds as plain fields', () async {
      await dataSource.sendAttachmentMessage(
        'c1',
        bytes: const [1, 2, 3],
        fileName: 'a.png',
        contentType: 'image/png',
        mentions: const ChatMentions(userIds: ['u-1', 'u-2']),
      );

      final form = adapter.lastRequest!.data as FormData;
      final ids = form.fields
          .where((f) => f.key == 'mentionedUserIds')
          .map((f) => f.value)
          .toList();
      expect(ids, ['u-1', 'u-2']);
      expect(form.fields.any((f) => f.key == 'mentionAll'), isFalse);
    });
  });
}
