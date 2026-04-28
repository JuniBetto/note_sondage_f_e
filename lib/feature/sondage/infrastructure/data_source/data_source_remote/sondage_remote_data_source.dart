import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data/sondage_mapper.dart';
import 'package:note_sondage/feature/sondage/infrastructure/data_source/data_source_local/sondage_local_data_source.dart';

class SondageRemoteDataSource {
  final SondageLocalDataSource localDataSource;
  static const String _endpoint = '/api/sondage';

  SondageRemoteDataSource(this.localDataSource);

  Future<List<SondageEntity>> getAll() async {
    final myResponse = await DioClient().dio.get('$_endpoint/my');
    final activeResponse = await DioClient().dio.get('$_endpoint/active');

    final merged = <String, SondageEntity>{};
    for (final raw in _extractList(myResponse.data)) {
      final entity = SondageMapper.fromJson(raw);
      merged[entity.id] = entity;
    }
    for (final raw in _extractList(activeResponse.data)) {
      final entity = SondageMapper.fromJson(raw);
      merged[entity.id] = entity;
    }

    final sondages = merged.values.toList()
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    await localDataSource.saveAll(sondages);
    return sondages;
  }

  Future<List<SondageEntity>> getAllByUserId(String userId) async {
    final response = await DioClient().dio.get('$_endpoint/my');
    final sondages = _extractList(response.data)
        .map(SondageMapper.fromJson)
        .toList();
    await localDataSource.saveAll(sondages);
    return sondages;
  }

  Future<SondageEntity?> getById(String id) async {
    final response = await DioClient().dio.get('$_endpoint/$id');
    return SondageMapper.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SondageEntity> create(SondageEntity sondage) async {
    final response = await DioClient().dio.post(
      _endpoint,
      data: SondageMapper.toJson(sondage),
    );
    return SondageMapper.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SondageEntity> update(SondageEntity sondage) async {
    final response = await DioClient().dio.put(
      '$_endpoint/${sondage.id}',
      data: SondageMapper.toJson(sondage),
    );
    return SondageMapper.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await DioClient().dio.delete('$_endpoint/$id');
  }

  Future<SondageEntity> publish(String id) async {
    final response = await DioClient().dio.post('$_endpoint/$id/publish');
    return SondageMapper.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SondageEntity> close(String id) async {
    final response = await DioClient().dio.post('$_endpoint/$id/close');
    return SondageMapper.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SondageEntity> vote(String sondageId, String optionId) async {
    final response = await DioClient().dio.post(
      '$_endpoint/$sondageId/vote',
      data: {'optionId': optionId},
    );
    return SondageMapper.fromJson(response.data as Map<String, dynamic>);
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ))
        .toList();
  }
}
