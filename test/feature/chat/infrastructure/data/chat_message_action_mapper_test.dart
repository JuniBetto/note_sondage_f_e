import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/infrastructure/data/chat_message_action_mapper.dart';

void main() {
  group('ChatMessageActionMapper.fromJson', () {
    test('parses a create_sondage draft, preferring workflowMetadata over source', () {
      final result = ChatMessageActionMapper.fromJson(<String, dynamic>{
        'messageActionType': 'create_sondage',
        'resolutionStatus': 'ready',
        'targetEntityType': 'sondage',
        'warnings': <dynamic>[],
        'draft': <String, dynamic>{
          'question': 'Chi è disponibile sabato?',
          'options': <String>['Disponibile', 'Non disponibile'],
          'teamId': 'team-1',
          'allowMultipleResponses': true,
          'expiryDate': '2026-09-01T00:00:00.000Z',
        },
        'source': <String, dynamic>{
          'sourceType': 'CHAT_MESSAGE',
          'conversationId': 'conv-1',
          'messageId': 'msg-1',
        },
        'workflowMetadata': <String, dynamic>{
          'contextType': 'TEAM',
          'contextId': 'team-1',
          'sourceId': 'conv-1-override',
          'sourceMessageId': 'msg-1-override',
        },
      });

      final prefill = result.sondagePrefill;
      expect(prefill, isNotNull);
      expect(prefill!.question, 'Chi è disponibile sabato?');
      expect(prefill.options, <String>['Disponibile', 'Non disponibile']);
      expect(prefill.allowMultipleResponses, isTrue);
      expect(prefill.contextType, 'TEAM');
      expect(prefill.sourceType, 'CHAT_MESSAGE');
      expect(prefill.sourceId, 'conv-1-override');
      expect(prefill.sourceMessageId, 'msg-1-override');
    });

    test('parses a create_task draft with priority and workflow metadata', () {
      final result = ChatMessageActionMapper.fromJson(<String, dynamic>{
        'messageActionType': 'create_task',
        'resolutionStatus': 'partial',
        'targetEntityType': 'task',
        'warnings': <dynamic>[],
        'draft': <String, dynamic>{
          'title': 'Prepare weekly rota',
          'teamId': 'team-1',
          'priority': 'high',
          'dueAt': '2026-09-05T10:00:00.000Z',
        },
        'source': <String, dynamic>{'conversationId': 'conv-2'},
        'workflowMetadata': <String, dynamic>{'sourceMessageId': 'msg-2'},
      });

      final taskDraft = result.taskDraft;
      expect(taskDraft, isNotNull);
      expect(taskDraft!.title, 'Prepare weekly rota');
      expect(taskDraft.teamId, 'team-1');
      expect(taskDraft.workflowMetadata?.sourceId, 'conv-2');
      expect(taskDraft.workflowMetadata?.sourceMessageId, 'msg-2');
      expect(result.isPartial, isTrue);
    });

    test('parses a create_shift draft and its start/end times', () {
      final result = ChatMessageActionMapper.fromJson(<String, dynamic>{
        'messageActionType': 'create_shift',
        'resolutionStatus': 'ready',
        'targetEntityType': 'shift',
        'warnings': <dynamic>[],
        'draft': <String, dynamic>{
          'shiftDate': '2026-09-06T00:00:00.000Z',
          'startTime': '08:30',
          'endTime': '16:00',
          'teamId': 'team-1',
        },
        'source': <String, dynamic>{},
        'workflowMetadata': <String, dynamic>{},
      });

      final shiftDraft = result.shiftDraft;
      expect(shiftDraft, isNotNull);
      expect(shiftDraft!.startTime, const TimeOfDay(hour: 8, minute: 30));
      expect(shiftDraft.endTime, const TimeOfDay(hour: 16, minute: 0));
      expect(shiftDraft.teamId, 'team-1');
    });

    test('parses a create_event draft with participants', () {
      final result = ChatMessageActionMapper.fromJson(<String, dynamic>{
        'messageActionType': 'create_event',
        'resolutionStatus': 'ready',
        'targetEntityType': 'event',
        'warnings': <dynamic>[],
        'draft': <String, dynamic>{
          'title': 'Riunione di squadra',
          'startsAt': '2026-09-07T09:00:00.000Z',
          'participantUserIds': <String>['user-1', 'user-2'],
        },
        'source': <String, dynamic>{},
        'workflowMetadata': <String, dynamic>{},
      });

      final eventDraft = result.eventDraft;
      expect(eventDraft, isNotNull);
      expect(eventDraft!.title, 'Riunione di squadra');
      expect(eventDraft.participantUserIds, <String>['user-1', 'user-2']);
    });

    test('returns null typed drafts and unsupported flag when unresolved', () {
      final result = ChatMessageActionMapper.fromJson(<String, dynamic>{
        'messageActionType': 'create_sondage',
        'resolutionStatus': 'unsupported',
        'targetEntityType': 'sondage',
        'warnings': <dynamic>[
          <String, dynamic>{'code': 'NO_QUESTION', 'message': 'Manca la domanda'},
        ],
        'draft': <String, dynamic>{},
      });

      expect(result.isUnsupported, isTrue);
      expect(result.sondagePrefill, isNull);
      expect(result.primaryMessage, 'Manca la domanda');
    });

    test('primaryMessage prefers the fallback message over warnings', () {
      final result = ChatMessageActionMapper.fromJson(<String, dynamic>{
        'messageActionType': 'create_task',
        'resolutionStatus': 'unsupported',
        'targetEntityType': 'task',
        'warnings': <dynamic>[
          <String, dynamic>{'code': 'W1', 'message': 'warning message'},
        ],
        'fallback': <String, dynamic>{
          'type': 'UNSUPPORTED',
          'reasonCode': 'NO_TITLE',
          'message': 'fallback message',
        },
      });

      expect(result.primaryMessage, 'fallback message');
    });
  });
}
