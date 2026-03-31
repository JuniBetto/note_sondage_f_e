import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';

abstract class SondageRepository {
  Future<List<SondageEntity>> getAll();

  Future<List<SondageEntity>> getAllByUserId(String userId);

  Future<SondageEntity?> getById(String id);

  Future<SondageEntity> create(SondageEntity sondage);

  Future<SondageEntity> update(SondageEntity sondage);

  Future<bool> delete(String id);
}
