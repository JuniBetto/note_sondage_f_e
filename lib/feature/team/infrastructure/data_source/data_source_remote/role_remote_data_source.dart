import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/crud_service.dart';
import 'package:note_sondage/feature/team/infrastructure/data/role_mapper.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/role_local_data_source.dart';

class RoleRemoteDataSource extends CrudService<RoleEntity> {
  final RoleLocalDataSource localDataSource;

  RoleRemoteDataSource(this.localDataSource) : super(DioClient().dio, '/roles');

  @override
  Future<RoleEntity> create(RoleEntity item) async {
    try {
      final response = await DioClient().dio.post(
        '$endpoint/create/${item.teamId}',
        data: RoleMapper.toJson(item),
      );
      final data = response.data;
      return RoleMapper.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await DioClient().dio.delete('$endpoint/delete/$id');
    } catch (e) {
      throw Exception('Failed to delete role: $e');
    }
  }

  @override
  Future<List<RoleEntity>> getAll() async {
    try {
      final response = await DioClient().dio.get('$endpoint/all');
      if (response.data == null) return [];
      final data = response.data as List;
      final roles = data
          .where((e) => e != null)
          .map((e) => RoleMapper.fromJson(e as Map<String, dynamic>))
          .toList();
      await localDataSource.saveAll(roles);
      return roles;
    } catch (e) {
      throw Exception('Failed to fetch roles: $e');
    }
  }

  Future<List<RoleEntity>> getAllByTeamId(String teamId) async {
    try {
      final response = await DioClient().dio.get(
        '$endpoint/all_by_team/$teamId',
      );
      if (response.data == null) return [];
      final data = response.data as List;
      return data
          .where((e) => e != null)
          .map((e) => RoleMapper.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch roles by team: $e');
    }
  }

  @override
  Future<RoleEntity> getById(String id) async {
    try {
      final response = await DioClient().dio.get('$endpoint/$id');
      return RoleMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch role: $e');
    }
  }

  @override
  Future<RoleEntity> update(String id, RoleEntity item) async {
    try {
      final newId = id.isEmpty ? item.id : id;
      final jsonData = RoleMapper.toJson(item);
      final response = await DioClient().dio.put(
        '$endpoint/update/$newId',
        data: jsonData,
      );
      return RoleMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }
}
