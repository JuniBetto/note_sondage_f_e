import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_mapper.dart';

TeamUpdate _update({
  bool workflowAiOnlyUpdate = false,
  bool basicsOnlyUpdate = false,
}) {
  return TeamUpdate(
    false,
    id: 't1',
    name: 'Nuovo nome',
    description: 'Nuova descrizione',
    createdByUserId: null,
    color: '0xFF123456',
    clockingRequired: true,
    workflowAiEnabled: true,
    workflowAiEnabledChanged: true,
    workflowAiOnlyUpdate: workflowAiOnlyUpdate,
    basicsOnlyUpdate: basicsOnlyUpdate,
    listMember: const [],
  );
}

void main() {
  group('TeamMapper.toJsonForUpdate', () {
    test('owner update sends every field', () {
      final json = TeamMapper.toJsonForUpdate(_update());
      expect(json['name'], 'Nuovo nome');
      expect(json['color'], '0xFF123456');
      expect(json['clockingRequired'], isTrue);
      expect(json['workflowAiEnabled'], isTrue);
    });

    test('UPDATE role sends only name and description', () {
      final json = TeamMapper.toJsonForUpdate(_update(basicsOnlyUpdate: true));
      expect(json, {'name': 'Nuovo nome', 'description': 'Nuova descrizione'});
    });

    test('MANAGE role sends only the AI flag', () {
      final json = TeamMapper.toJsonForUpdate(
        _update(workflowAiOnlyUpdate: true),
      );
      expect(json, {'workflowAiEnabled': true});
    });

    test('ADMIN role sends basics and AI flag, never owner fields', () {
      final json = TeamMapper.toJsonForUpdate(
        _update(workflowAiOnlyUpdate: true, basicsOnlyUpdate: true),
      );
      expect(json, {
        'name': 'Nuovo nome',
        'description': 'Nuova descrizione',
        'workflowAiEnabled': true,
      });
    });
  });
}
