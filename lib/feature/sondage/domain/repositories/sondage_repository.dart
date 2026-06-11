import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';

abstract class SondageRepository {
  Future<List<SondageEntity>> getAll();

  Future<List<SondageEntity>> getAllByUserId(String userId);

  Future<SondageEntity?> getById(String id);

  Future<SondageEntity> create(SondageEntity sondage);

  Future<SondageEntity> update(SondageEntity sondage);

  Future<bool> delete(String id);

  Future<SondageEntity> publish(String id);

  Future<SondageEntity> close(String id);

  Future<SondageEntity> reopen(String id);

  Future<SondageEntity> vote(String sondageId, String optionId);

  Future<int> remindPendingVoters(
    String sondageId, {
    List<String>? recipientUserIds,
  });
}
