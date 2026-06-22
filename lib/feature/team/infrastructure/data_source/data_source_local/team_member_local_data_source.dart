import 'package:hive/hive.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/infrastructure/data/hive_models/team_member_hive_model.dart';

class TeamMemberLocalDataSource {
  static const String _boxName = 'team_members_box';

  Future<Box<TeamMemberHiveModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<TeamMemberHiveModel>(_boxName);
    }
    return await Hive.openBox<TeamMemberHiveModel>(_boxName);
  }

  Future<void> saveAll(List<TeamMemberEntity> members) async {
    final box = await _openBox();
    await box.clear();
    final models = members.map(
      (e) => TeamMemberHiveModel(
        id: e.id,
        userId: e.userId,
        userEmail: e.userEmail,
        teamId: e.teamId,
        status: e.status.value,
        roleId: e.roleId,
        imageUrl: e.imageUrl,
        fileName: e.fileName,
        initialName: e.initialName,
      ),
    );
    await box.addAll(models);
  }

  Future<List<TeamMemberEntity>> getAll() async {
    final box = await _openBox();
    return box.values.map(_fromModel).toList();
  }

  /// Legge i membri filtrati per teamId.
  Future<List<TeamMemberEntity>> getAllByTeamId(String teamId) async {
    final all = await getAll();
    return all.where((m) => m.teamId == teamId).toList();
  }

  Future<void> removeByTeamId(String teamId) async {
    final all = await getAll();
    await saveAll(all.where((member) => member.teamId != teamId).toList());
  }

  TeamMemberEntity _fromModel(TeamMemberHiveModel m) {
    return TeamMemberEntity(
      id: m.id,
      userId: m.userId,
      userEmail: m.userEmail,
      teamId: m.teamId,
      status: UserStatus.values.firstWhere(
        (s) => s.value == m.status,
        orElse: () => UserStatus.pending,
      ),
      roleId: m.roleId,
      imageUrl: m.imageUrl,
      fileName: m.fileName,
      initialName: m.initialName,
    );
  }
}
