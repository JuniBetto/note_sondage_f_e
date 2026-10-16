import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/navigation/notification_navigation.dart';

const _currentUserId = 'me';

NotificationCenterItem _chatItem({
  String eventType = 'CHAT_MESSAGE_CREATED',
  Map<String, String> metadata = const <String, String>{},
}) {
  return NotificationCenterItem(
    notificationId: 'n1',
    eventType: eventType,
    sourceService: 'chat-service',
    title: 'Nuovo messaggio',
    body: 'Ciao',
    occurredAt: DateTime(2026, 10, 16),
    metadata: metadata,
  );
}

Uri _resolvedUri(NotificationCenterItem item) {
  final path = NotificationNavigation.destinationPathFor(
    item,
    currentUserId: _currentUserId,
  );
  expect(path, isNotNull);
  return Uri.parse(path!);
}

void main() {
  group('chat notification → destination path (mobile)', () {
    test('team chat opens /team/chat/conversation with teamId', () {
      final uri = _resolvedUri(
        _chatItem(metadata: const {'teamId': 't1', 'conversationId': 'c1'}),
      );

      expect(uri.path, RouterPaths.teamChatConversation);
      expect(uri.queryParameters, {
        'teamId': 't1',
        'conversationId': 'c1',
        'focus': 'latest',
      });
    });

    test('direct chat targets the other participant', () {
      final uri = _resolvedUri(
        _chatItem(
          metadata: const {
            'teamId': 't1',
            'chatType': 'DIRECT',
            'participantAUserId': _currentUserId,
            'participantBUserId': 'other',
          },
        ),
      );

      expect(uri.path, RouterPaths.teamChatConversation);
      expect(uri.queryParameters['memberUserId'], 'other');
    });

    test('conversationId alone is enough to route to chat', () {
      final uri = _resolvedUri(
        _chatItem(
          eventType: 'SOMETHING_ELSE',
          metadata: const {'conversationId': 'c1'},
        ),
      );

      expect(uri.path, RouterPaths.teamChatConversation);
      expect(uri.queryParameters.containsKey('teamId'), isFalse);
    });

    test('never resolves to the legacy /sondage/chat paths', () {
      final uri = _resolvedUri(_chatItem(metadata: const {'teamId': 't1'}));

      expect(uri.path, isNot(startsWith('/sondage/chat')));
    });
  });

  group('mobileShellTargetFor', () {
    test('conversation WITH teamId opens standalone (own Scaffold)', () {
      expect(
        NotificationNavigation.mobileShellTargetFor(
          '/team/chat/conversation?teamId=t1&focus=latest',
        ),
        isNull,
      );
    });

    test('conversation WITHOUT teamId goes to Team shell on Chat tab', () {
      expect(
        NotificationNavigation.mobileShellTargetFor(
          '/team/chat/conversation?focus=latest',
        ),
        (navIndex: 1, openTeamChat: true),
      );
    });

    test('blank teamId is treated as missing', () {
      expect(
        NotificationNavigation.mobileShellTargetFor(
          '/team/chat/conversation?teamId=%20%20',
        ),
        (navIndex: 1, openTeamChat: true),
      );
    });

    test('/team/chat goes to Team shell on Chat tab', () {
      expect(
        NotificationNavigation.mobileShellTargetFor('/team/chat?teamId=t1'),
        (navIndex: 1, openTeamChat: true),
      );
    });

    test('legacy /sondage/chat is mapped to Team chat, not Sondage', () {
      expect(
        NotificationNavigation.mobileShellTargetFor(RouterPaths.sondageChat),
        (navIndex: 1, openTeamChat: true),
      );
    });

    test('legacy conversation without teamId → Team chat tab', () {
      expect(
        NotificationNavigation.mobileShellTargetFor(
          '/sondage/chat/conversation?focus=latest',
        ),
        (navIndex: 1, openTeamChat: true),
      );
    });

    test('legacy conversation with teamId opens standalone', () {
      expect(
        NotificationNavigation.mobileShellTargetFor(
          '/sondage/chat/conversation?teamId=t1',
        ),
        isNull,
      );
    });

    test('plain shell sections keep their tab and do not force Chat', () {
      expect(NotificationNavigation.mobileShellTargetFor(RouterPaths.team), (
        navIndex: 1,
        openTeamChat: false,
      ));
      expect(NotificationNavigation.mobileShellTargetFor(RouterPaths.sondage), (
        navIndex: 4,
        openTeamChat: false,
      ));
      expect(NotificationNavigation.mobileShellTargetFor(RouterPaths.home), (
        navIndex: 0,
        openTeamChat: false,
      ));
    });

    test('resolved chat notification with teamId is opened standalone', () {
      final path = NotificationNavigation.destinationPathFor(
        _chatItem(metadata: const {'teamId': 't1'}),
        currentUserId: _currentUserId,
      )!;
      expect(NotificationNavigation.mobileShellTargetFor(path), isNull);
    });

    test('resolved chat notification without teamId uses the shell', () {
      final path = NotificationNavigation.destinationPathFor(
        _chatItem(metadata: const {'conversationId': 'c1'}),
        currentUserId: _currentUserId,
      )!;
      expect(NotificationNavigation.mobileShellTargetFor(path), (
        navIndex: 1,
        openTeamChat: true,
      ));
    });
  });

  group('RouterPaths.isChatPath (_isChatRouteOpen)', () {
    test('recognises new, web and legacy chat paths', () {
      for (final path in [
        RouterPaths.chat,
        RouterPaths.teamChat,
        RouterPaths.teamChatConversation,
        RouterPaths.sondageChat,
        RouterPaths.sondageChatConversation,
        ' /team/chat/conversation ',
      ]) {
        expect(RouterPaths.isChatPath(path), isTrue, reason: path);
      }
    });

    test('rejects non-chat paths', () {
      for (final path in [
        null,
        '',
        RouterPaths.home,
        RouterPaths.team,
        RouterPaths.sondage,
        '/team/chatx',
      ]) {
        expect(RouterPaths.isChatPath(path), isFalse, reason: '$path');
      }
    });
  });

  testWidgets(
    'resolved chat path lands on the conversation route via GoRouter',
    (tester) async {
      final path = NotificationNavigation.destinationPathFor(
        _chatItem(metadata: const {'teamId': 't1', 'conversationId': 'c1'}),
        currentUserId: _currentUserId,
      )!;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: RouterPaths.teamChatConversation,
            builder: (_, state) => Text(
              'conversation:${state.uri.queryParameters['teamId']}'
              ':${state.uri.queryParameters['conversationId']}',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go(path);
      await tester.pumpAndSettle();

      expect(find.text('conversation:t1:c1'), findsOneWidget);
    },
  );
}
