import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_message_bubble.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_message_timeline.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

final _t0 = DateTime(2026, 1, 1, 15, 0, 0);

ChatMessageEntity _msg(
  String id,
  int seconds, {
  String sender = 'u1',
  String name = 'Alice',
  bool mine = false,
  int readByOther = 0,
  bool deleted = false,
}) => ChatMessageEntity(
  id: id,
  conversationId: 'c',
  senderUserId: sender,
  senderName: name,
  senderAvatarUrl: null,
  contentText: 'text-$id',
  messageType: 'TEXT',
  attachmentPath: null,
  attachmentOriginalName: null,
  attachmentContentType: null,
  attachmentSizeBytes: null,
  replyTo: null,
  reactions: const [],
  deleted: deleted,
  deletedAt: null,
  createdAt: _t0.add(Duration(seconds: seconds)),
  readByCurrentUser: true,
  readByOtherCount: readByOther,
  mine: mine,
);

Future<void> _pump(WidgetTester tester, List<ChatMessageEntity> messages) async {
  tester.view
    ..physicalSize = const Size(500, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatMessageTimeline(
          messages: messages,
          scrollController: ScrollController(),
          compact: false,
          accentColor: Colors.purple,
          loadingOlderMessages: false,
          hasMoreOlderMessages: false,
        ),
      ),
    ),
  );
  await tester.pump();
}

BorderRadius _radius(WidgetTester tester, String text) {
  final ink = tester.widget<Ink>(
    find.ancestor(of: find.text(text), matching: find.byType(Ink)).first,
  );
  return (ink.decoration! as BoxDecoration).borderRadius! as BorderRadius;
}

void main() {
  group('chatMessagesAreGrouped', () {
    test('same sender under 20 seconds apart', () {
      expect(chatMessagesAreGrouped(_msg('a', 0), _msg('b', 19)), isTrue);
    });
    test('20 seconds or more starts a new group', () {
      expect(chatMessagesAreGrouped(_msg('a', 0), _msg('b', 20)), isFalse);
      expect(chatMessagesAreGrouped(_msg('a', 0), _msg('b', 90)), isFalse);
    });
    test('a different sender never groups', () {
      expect(
        chatMessagesAreGrouped(_msg('a', 0), _msg('b', 2, sender: 'u2')),
        isFalse,
      );
    });
    test('out-of-order timestamps do not group', () {
      expect(chatMessagesAreGrouped(_msg('a', 10), _msg('b', 5)), isFalse);
    });
  });

  testWidgets('a burst shows the sender name once', (tester) async {
    await _pump(tester, [_msg('a', 0), _msg('b', 8), _msg('c', 15)]);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('text-a'), findsOneWidget);
    expect(find.text('text-b'), findsOneWidget);
    expect(find.text('text-c'), findsOneWidget);
  });

  testWidgets('messages 20+ seconds apart each keep their header', (tester) async {
    await _pump(tester, [_msg('a', 0), _msg('b', 30), _msg('c', 65)]);
    expect(find.text('Alice'), findsNWidgets(3));
  });

  testWidgets('another sender in the middle splits the burst', (tester) async {
    await _pump(tester, [
      _msg('a', 0),
      _msg('b', 5, sender: 'u2', name: 'Bob'),
      _msg('c', 10),
    ]);
    expect(find.text('Alice'), findsNWidgets(2));
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('bubbles in a burst stack tightly with joined corners', (tester) async {
    await _pump(tester, [_msg('a', 0), _msg('b', 5), _msg('c', 10)]);

    final first = _radius(tester, 'text-a');
    final middle = _radius(tester, 'text-b');
    final last = _radius(tester, 'text-c');
    // Incoming bubbles join on the left.
    expect(first.topLeft.x, 18);
    expect(first.bottomLeft.x, 4);
    expect(middle.topLeft.x, 4);
    expect(middle.bottomLeft.x, 4);
    expect(last.topLeft.x, 4);
    expect(last.bottomLeft.x, 18); // closes the burst with a full curve
    expect(first.topRight.x, 18);

    final gapAB = tester.getTopLeft(find.text('text-b')).dy -
        tester.getBottomLeft(find.text('text-a')).dy;
    final gapSeparate = () async {
      await _pump(tester, [_msg('a', 0), _msg('b', 60)]);
      return tester.getTopLeft(find.text('text-b')).dy -
          tester.getBottomLeft(find.text('text-a')).dy;
    }();
    expect(gapAB, lessThan(await gapSeparate));
  });

  testWidgets('a lone message keeps its original corners', (tester) async {
    await _pump(tester, [_msg('a', 0)]);
    final r = _radius(tester, 'text-a');
    expect([r.topLeft.x, r.topRight.x, r.bottomLeft.x, r.bottomRight.x], [18, 18, 6, 18]);
  });

  testWidgets('own bursts show the delivery tick once, under the last bubble', (tester) async {
    await _pump(tester, [
      _msg('a', 0, mine: true, name: 'Me', sender: 'me'),
      _msg('b', 5, mine: true, name: 'Me', sender: 'me'),
      _msg('c', 10, mine: true, name: 'Me', sender: 'me'),
    ]);
    expect(find.text('Me'), findsOneWidget);
    expect(find.byIcon(Icons.done_rounded), findsOneWidget);
    final tickY = tester.getTopLeft(find.byIcon(Icons.done_rounded)).dy;
    expect(tickY, greaterThan(tester.getBottomLeft(find.text('text-c')).dy));
  });

  testWidgets('a single own message keeps the tick in its header', (tester) async {
    await _pump(tester, [_msg('a', 0, mine: true, name: 'Me', sender: 'me')]);
    expect(find.byIcon(Icons.done_rounded), findsOneWidget);
    final tickY = tester.getTopLeft(find.byIcon(Icons.done_rounded)).dy;
    expect(tickY, lessThan(tester.getTopLeft(find.text('text-a')).dy));
  });
}
