import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/domain/repositories/sondage_repository.dart';

class SondageUseCase {
  final SondageRepository repository;
  SondageUseCase(this.repository);

  Future<List<SondageEntity>> getAllSondages() async {
    try {
      return await repository.getAll();
    } catch (e) {
      throw Exception('Failed to fetch sondages: $e');
    }
  }

  Future<List<SondageEntity>> getAllSondagesByUserId(String userId) async {
    try {
      return await repository.getAllByUserId(userId);
    } catch (e) {
      throw Exception('Failed to fetch sondages by user ID: $e');
    }
  }

  Future<SondageEntity?> getSondageById(String id) async {
    try {
      return await repository.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch sondage: $e');
    }
  }

  Future<SondageEntity> createSondage(SondageEntity sondage) async {
    try {
      return await repository.create(sondage);
    } catch (e) {
      throw Exception('Failed to create sondage: $e');
    }
  }

  Future<SondageEntity> updateSondage(SondageEntity sondage) async {
    try {
      return await repository.update(sondage);
    } catch (e) {
      throw Exception('Failed to update sondage: $e');
    }
  }

  Future<bool> deleteSondage(String id) async {
    try {
      return await repository.delete(id);
    } catch (e) {
      throw Exception('Failed to delete sondage: $e');
    }
  }
}
