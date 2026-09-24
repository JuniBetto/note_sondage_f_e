// Firebase platform interfaces are supplied by the app's locked Firebase SDK.
// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_conversation_entity.dart';
import 'package:note_sondage/feature/chat/domain/entities/chat_message_entity.dart';

const chatCacheBoxName = 'chat_cache_box';
const cacheUserId = 'cache-user-a';

/// Only authentication is faked; ChatLocalDataSource and Hive remain real.
class CacheTestAuth extends FirebaseAuthPlatform {
  UserPlatform? _user;

  void signInAs(String? uid) {
    _user = uid == null ? null : _CacheUser(this, uid);
  }

  @override
  UserPlatform? get currentUser => _user;

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) => this;
}

class _CacheMultiFactor extends MultiFactorPlatform {
  _CacheMultiFactor(super.auth);
}

class _CacheUser extends UserPlatform {
  _CacheUser(FirebaseAuthPlatform auth, String uid)
    : super(
        auth,
        _CacheMultiFactor(auth),
        PigeonUserDetails(
          userInfo: PigeonUserInfo(
            uid: uid,
            isAnonymous: false,
            isEmailVerified: true,
          ),
          providerData: [],
        ),
      );
}

Future<CacheTestAuth> initializeCacheTestAuth() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  await Firebase.initializeApp();
  final auth = CacheTestAuth()..signInAs(cacheUserId);
  FirebaseAuthPlatform.instance = auth;
  return auth;
}

ChatConversationEntity cacheConversation({int index = 0}) =>
    ChatConversationEntity(
      id: 'conversation-$index',
      teamId: 'team-$index',
      type: 'TEAM',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      lastMessageAt: DateTime.utc(2026, 1, 2),
    );

ChatMessageEntity cacheMessage({
  int index = 0,
  String conversationId = 'conversation-0',
  String content = 'Messaggio di prova',
}) => ChatMessageEntity(
  id: '$conversationId-message-$index',
  conversationId: conversationId,
  senderUserId: 'sender',
  senderName: 'Test User',
  senderAvatarUrl: null,
  contentText: content,
  messageType: 'TEXT',
  attachmentPath: null,
  attachmentOriginalName: null,
  attachmentContentType: null,
  attachmentSizeBytes: null,
  replyTo: null,
  reactions: const [],
  deleted: false,
  deletedAt: null,
  createdAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: index)),
  readByCurrentUser: true,
  mine: false,
);

/// Frozen legacy fixture, independent of the production serializer. Retain it
/// for migration tests when the on-disk format changes. No real user data.
Future<int> seedLegacyChatCache(
  Box<String> box, {
  required int conversations,
  int messagesPerConversation = 50,
  String scope = cacheUserId,
}) async {
  final messages = <String, Object?>{};
  final teams = <Map<String, Object?>>[];
  for (var chat = 0; chat < conversations; chat++) {
    final id = 'conversation-$chat';
    teams.add({
      'id': id,
      'teamId': 'team-$chat',
      'type': 'TEAM',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-02T00:00:00.000Z',
      'lastMessageAt': '2026-01-02T00:00:00.000Z',
    });
    messages[id] = List.generate(
      messagesPerConversation,
      (index) => {
        'id': '$id-message-$index',
        'conversationId': id,
        'senderUserId': 'sender',
        'senderName': 'Test User',
        'contentText': List.filled(
          8,
          'Messaggio sintetico per benchmark.',
        ).join(' '),
        'messageType': 'TEXT',
        'reactions': [],
        'deleted': false,
        'createdAt': DateTime.utc(
          2026,
          1,
          1,
        ).add(Duration(seconds: index)).toIso8601String(),
        'readByCurrentUser': true,
        'deliveredByOtherCount': 1,
        'readByOtherCount': 0,
        'mine': false,
      },
    );
  }
  final payloads = {
    'conversations::$scope': jsonEncode(teams),
    'messages::$scope': jsonEncode(messages),
  };
  await box.putAll(payloads);
  await box.flush();
  return payloads.values.fold<int>(
    0,
    (bytes, value) => bytes + utf8.encode(value).length,
  );
}
