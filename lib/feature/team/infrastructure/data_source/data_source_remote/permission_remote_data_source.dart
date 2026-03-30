import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/crud_service.dart';
import 'package:note_sondage/feature/team/infrastructure/data/permission_mapper.dart';

class PermissionRemoteDataSource extends CrudService<PermissionEntity> {
  PermissionRemoteDataSource() : super(DioClient().dio, '/permissions');

  @override
  Future<List<PermissionEntity>> getAll() async {
    try {
      final response = await DioClient().dio.get('$endpoint/all');
      final data = response.data as List;
      return data
          .map((e) => PermissionMapper.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch permissions: $e');
    }
  }

  @override
  Future<PermissionEntity> getById(String id) async {
    final response = await DioClient().dio.get('$endpoint/$id');
    return PermissionMapper.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PermissionEntity> create(PermissionEntity entity) async {
    final response = await DioClient().dio.post(
      endpoint,
      data: PermissionMapper.toJson(entity),
    );
    return PermissionMapper.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PermissionEntity> update(String id, PermissionEntity entity) async {
    final response = await DioClient().dio.put(
      '$endpoint/$id',
      data: PermissionMapper.toJson(entity),
    );
    return PermissionMapper.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await DioClient().dio.delete('$endpoint/$id');
  }
}
