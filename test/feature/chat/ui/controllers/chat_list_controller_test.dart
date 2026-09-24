import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_direct_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_team_conversation_summary_entity.dart';
import 'package:note_sondage/feature/chat/domain/use_case/chat_use_case.dart';
import 'package:note_sondage/feature/chat/ui/controllers/chat_list_controller.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/use_case/team/team_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';

import '../../../../support/team_fixtures.dart';

class _Teams extends Fake implements TeamUseCase {
  Future<List<TeamEntity>> Function() remote = () async => [];
  Future<List<TeamEntity>> Function() local = () async => [];
  @override
  Future<List<TeamEntity>> getAllTeams() => remote();
  @override
  Future<List<TeamEntity>> getLocalTeams() => local();
}

class _Members extends Fake implements TeamMemberUseCase {
  Future<List<TeamMemberEntity>> Function(String) fetch = (_) async => [];
  @override
  Future<List<TeamMemberEntity>> getAllMembersByTeamId(String id) => fetch(id);
}

class _Chat extends Fake implements ChatUseCase {
  final cached = <String, ChatTeamConversationSummaryEntity>{};
  final directCache = <(String, String), ChatDirectConversationSummaryEntity>{};
  Future<ChatTeamConversationSummaryEntity> Function(String) summary =
      (id) async => _summary(id);
  Future<ChatDirectConversationSummaryEntity> Function(String, String) direct =
      (id, uid) async => _direct(id, uid);
  @override
  ChatTeamConversationSummaryEntity? getCachedTeamSummary(String id) =>
      cached[id];
  @override
  ChatDirectConversationSummaryEntity? getCachedDirectSummary(
    String id,
    String uid,
  ) => directCache[(id, uid)];
  @override
  Future<ChatTeamConversationSummaryEntity> getTeamConversationSummary(
    String id,
  ) => summary(id);
  @override
  Future<ChatDirectConversationSummaryEntity> getDirectConversationSummary(
    String id,
    String uid,
  ) => direct(id, uid);
}

ChatTeamConversationSummaryEntity _summary(String id, {int day = 1}) =>
    ChatTeamConversationSummaryEntity(
      teamId: id,
      conversationId: 'chat-$id',
      unreadCount: 2,
      lastMessagePreview: 'Preview $day',
      lastMessageType: 'TEXT',
      lastMessageAt: DateTime.utc(2026, 1, day),
    );
ChatDirectConversationSummaryEntity _direct(
  String id,
  String uid, {
  String? conversationId = 'direct',
  int day = 1,
}) => ChatDirectConversationSummaryEntity(
  teamId: id,
  participantUserId: uid,
  participantDisplayName: uid,
  participantAvatarUrl: null,
  conversationId: conversationId,
  unreadCount: 1,
  lastMessagePreview: 'Direct',
  lastMessageType: 'TEXT',
  lastMessageAt: DateTime.utc(2026, 1, day),
);
TeamMemberEntity _member(String uid) => TeamMemberEntity(
  id: uid,
  userId: uid,
  userEmail: '$uid@example.test',
  teamId: 'team-1',
  roleId: 'role',
  status: UserStatus.active,
);

void main() {
  late _Teams teams;
  late _Members members;
  late _Chat chat;
  late ChatListController controller;
  late ChatListSessionCache cache;
  String? user;
  ChatListController create() => ChatListController(
    teamUseCase: teams,
    memberUseCase: members,
    chatUseCase: chat,
    currentUserId: () => user,
    sessionCache: cache,
  );
  setUp(() {
    teams = _Teams();
    members = _Members();
    chat = _Chat();
    cache = ChatListSessionCache();
    user = 'self';
    controller = create();
  });
  tearDown(() => controller.dispose());

  testWidgets('21 detail calls of 450 ms complete in four bounded waves', (
    tester,
  ) async {
    teams.remote = () async =>
        List.generate(8, (i) => buildTeam(id: 'team-$i'));
    var calls = 0;
    Future<void> latency() async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }

    chat.summary = (id) async {
      await latency();
      return _summary(id);
    };
    members.fetch = (id) async {
      await latency();
      return int.parse(id.split('-').last) < 5 ? [_member('other')] : [];
    };
    chat.direct = (id, uid) async {
      await latency();
      return _direct(id, uid);
    };
    var completed = false;
    final load = controller.load().then((_) => completed = true);
    await tester.pump();
    expect(calls, 6);
    for (var wave = 0; wave < 3; wave++) {
      await tester.pump(const Duration(milliseconds: 450));
    }
    expect(completed, isFalse);
    await tester.pump(const Duration(milliseconds: 450));
    expect(completed, isTrue);
    await load;
    expect(calls, 21);
    expect(controller.directEntries, hasLength(5));
  });

  test(
    'returning from a chat during team loading does not discard the fresh team list',
    () async {
      teams.local = () async => [buildTeam(id: 'cached')];
      final remote = Completer<List<TeamEntity>>();
      teams.remote = () => remote.future;
      final loading = controller.load();
      await pumpEventQueue();
      await controller.refreshDetails();
      remote.complete([buildTeam(id: 'fresh')]);
      await loading;
      expect(controller.teams.single.id, 'fresh');
      expect(controller.summaries.keys, ['fresh']);
    },
  );

  test(
    'disposing stops queued network work and ignores active responses',
    () async {
      teams.remote = () async =>
          List.generate(8, (i) => buildTeam(id: 'team-$i'));
      final gate = Completer<void>();
      var calls = 0;
      chat.summary = (id) async {
        calls++;
        await gate.future;
        return _summary(id);
      };
      members.fetch = (_) async {
        calls++;
        await gate.future;
        return [];
      };
      final closed = create();
      final loading = closed.load();
      await pumpEventQueue();
      expect(calls, 6);
      closed.dispose();
      gate.complete();
      await loading;
      expect(calls, 6);
    },
  );

  test(
    'shows local teams and summaries while the remote team list is pending',
    () async {
      final response = Completer<List<TeamEntity>>();
      teams.remote = () => response.future;
      teams.local = () async => [buildTeam()];
      chat.cached['team-1'] = _summary('team-1', day: 2);
      final loading = controller.load();
      await pumpEventQueue();
      expect(controller.loading, isFalse);
      expect(controller.summaries['team-1']?.lastMessagePreview, 'Preview 2');
      response.complete([]);
      await loading;
      expect(controller.teams, isEmpty);
      expect(controller.summaries, isEmpty);
    },
  );

  test(
    'late local teams cannot overwrite an authoritative empty remote list',
    () async {
      final cached = Completer<List<TeamEntity>>();
      teams.local = () => cached.future;
      await controller.load();
      cached.complete([buildTeam()]);
      await pumpEventQueue();
      expect(controller.teams, isEmpty);
    },
  );

  test(
    'eight teams load concurrently with at most six active requests, including directs',
    () async {
      teams.remote = () async =>
          List.generate(8, (i) => buildTeam(id: 'team-$i'));
      var active = 0;
      var maximum = 0;
      var calls = 0;
      final gates = <Completer<void>>[];
      Future<void> request() async {
        active++;
        calls++;
        if (active > maximum) maximum = active;
        final gate = Completer<void>();
        gates.add(gate);
        await gate.future;
        active--;
      }

      chat.summary = (id) async {
        await request();
        return _summary(id);
      };
      members.fetch = (id) async {
        await request();
        return [_member('self'), _member('other')];
      };
      chat.direct = (id, uid) async {
        await request();
        return _direct(id, uid);
      };
      final loading = controller.load();
      await pumpEventQueue();
      expect(active, 6);
      // Complete each wave. If the implementation serializes requests or
      // exceeds the bound these assertions fail without timing thresholds.
      while (gates.any((gate) => !gate.isCompleted)) {
        for (final gate in List.of(gates).where((gate) => !gate.isCompleted)) {
          gate.complete();
        }
        await pumpEventQueue();
        expect(active, lessThanOrEqualTo(6));
      }
      await loading;
      expect(calls, 24);
      expect(maximum, 6);
      expect(controller.directEntries, hasLength(8));
    },
  );

  test(
    'publishes members and cached directs before blocked team/direct summaries finish',
    () async {
      final summary = Completer<ChatTeamConversationSummaryEntity>();
      final direct = Completer<ChatDirectConversationSummaryEntity>();
      teams.remote = () async => [buildTeam(workflowAiEnabled: true)];
      members.fetch = (_) async => [
        _member('self'),
        _member('other'),
        _member('other'),
      ];
      chat.summary = (_) => summary.future;
      chat.directCache[('team-1', 'other')] = _direct('team-1', 'other');
      var directCalls = 0;
      chat.direct = (_, _) {
        directCalls++;
        return direct.future;
      };
      final loading = controller.load();
      await pumpEventQueue();
      expect(controller.directEntries, hasLength(1));
      expect(controller.teams.single.memberCount, 2);
      expect(controller.teams.single.workflowAiEnabled, isTrue);
      expect(directCalls, 1);
      summary.complete(_summary('team-1', day: 3));
      await pumpEventQueue();
      expect(controller.summaries['team-1']?.lastMessagePreview, 'Preview 3');
      direct.complete(_direct('team-1', 'other', conversationId: null));
      await loading;
      expect(controller.directEntries, isEmpty);
    },
  );

  test(
    'partial failures preserve cached summary and known member count',
    () async {
      teams.remote = () async => [buildTeam(memberCount: 9)];
      chat.cached['team-1'] = _summary('team-1');
      chat.summary = (_) async => throw StateError('offline');
      members.fetch = (_) async => throw StateError('offline');
      await controller.load();
      expect(controller.teams.single.memberCount, 9);
      expect(controller.summaries['team-1'], isNotNull);
    },
  );

  test(
    'session cache is immediate for the same user and empty for a different user',
    () async {
      teams.remote = () async => [buildTeam()];
      members.fetch = (_) async => [_member('other')];
      chat.directCache[('team-1', 'other')] = _direct('team-1', 'other');
      await controller.load();
      final restored = create();
      expect(restored.loading, isFalse);
      expect(restored.directEntries, hasLength(1));
      restored.dispose();
      user = 'different';
      final different = create();
      expect(different.teams, isEmpty);
      expect(different.directEntries, isEmpty);
      different.dispose();
    },
  );

  test(
    'old refresh and deleted-team responses cannot repopulate the list',
    () async {
      teams.remote = () async => [buildTeam()];
      final old = Completer<ChatTeamConversationSummaryEntity>();
      chat.summary = (_) => old.future;
      final first = controller.load();
      await pumpEventQueue();
      chat.summary = (_) async => _summary('team-1', day: 4);
      await controller.refreshDetails();
      old.complete(_summary('team-1'));
      await first;
      expect(controller.summaries['team-1']?.lastMessagePreview, 'Preview 4');

      final removed = Completer<ChatTeamConversationSummaryEntity>();
      chat.summary = (_) => removed.future;
      final refresh = controller.refreshDetails();
      await pumpEventQueue();
      controller.removeTeam('team-1');
      removed.complete(_summary('team-1'));
      await refresh;
      expect(controller.teams, isEmpty);
      expect(controller.summaries, isEmpty);
    },
  );

  test(
    'account switch discards pending responses and clears the visible list',
    () async {
      teams.remote = () async => [buildTeam()];
      final old = Completer<ChatTeamConversationSummaryEntity>();
      chat.summary = (_) => old.future;
      final first = controller.load();
      await pumpEventQueue();
      user = 'new-user';
      teams.remote = () async => [];
      await controller.load();
      old.complete(_summary('team-1'));
      await first;
      expect(controller.teams, isEmpty);
      expect(controller.summaries, isEmpty);
    },
  );

  test(
    'sorts by latest activity and rejects a mismatched direct participant',
    () async {
      teams.remote = () async => [buildTeam(id: 'old'), buildTeam(id: 'new')];
      members.fetch = (_) async => [_member('other')];
      chat.summary = (id) async => _summary(id, day: id == 'new' ? 3 : 1);
      chat.direct = (id, _) async =>
          _direct(id, id == 'old' ? 'wrong-user' : 'other');
      await controller.load();
      expect(controller.teams.map((team) => team.id), ['new', 'old']);
      expect(controller.directEntries.single.team.id, 'new');
    },
  );
}
