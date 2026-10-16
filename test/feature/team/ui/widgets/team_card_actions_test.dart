import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/widgets/responsive_grid_teams.dart';

Map<String, dynamic> _item({
  required String myRole,
  List<RoleEntity> roles = const [],
  String owner = 'owner',
}) {
  return {
    'ownerUserId': owner,
    'members': [
      {'userId': 'me', 'email': 'me@example.com', 'role': myRole},
    ],
    'roles': roles,
  };
}

RoleEntity _role(String code, List<String> permissions) =>
    RoleEntity(code, teamId: 't1', name: code, permissions: permissions);

bool _canEdit(Map<String, dynamic> item) => canManageTeamFromItem(
  item,
  currentUserId: 'me',
  currentUserEmail: 'me@example.com',
);

void main() {
  test('owner always sees the edit icon', () {
    expect(_canEdit(_item(myRole: 'OWNER', owner: 'me')), isTrue);
  });

  test('default ADMIN sees it even before roles are loaded', () {
    expect(_canEdit(_item(myRole: 'ADMIN')), isTrue);
  });

  test('plain member does not see it', () {
    expect(
      _canEdit(
        _item(
          myRole: 'MEMBER',
          roles: [
            _role('MEMBER', ['READ']),
          ],
        ),
      ),
      isFalse,
    );
  });

  test('custom roles: any management permission shows it', () {
    for (final permission in ['UPDATE', 'ADMIN', 'DELETE', 'MANAGE']) {
      final item = _item(
        myRole: 'TEAM_X_CUSTOM',
        roles: [
          _role('TEAM_X_CUSTOM', ['READ', permission]),
        ],
      );
      expect(_canEdit(item), isTrue, reason: permission);
    }
  });

  test('custom role with READ only does not see it', () {
    final item = _item(
      myRole: 'TEAM_X_VIEW',
      roles: [
        _role('TEAM_X_VIEW', ['READ']),
      ],
    );
    expect(_canEdit(item), isFalse);
  });
}
