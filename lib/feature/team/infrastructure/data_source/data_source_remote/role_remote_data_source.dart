import 'dart:developer' as dev;

import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/repositories/crud_service.dart';
import 'package:note_sondage/feature/team/infrastructure/data/role_mapper.dart';
import 'package:note_sondage/feature/team/infrastructure/data_source/data_source_local/role_local_data_source.dart';

class RoleRemoteDataSource extends CrudService<RoleEntity> {
  final RoleLocalDataSource localDataSource;

  RoleRemoteDataSource(this.localDataSource)
    : super(DioClient().dio, '/api/aggregate/teams/roles');

  // ── GET all available roles (with local cache) ──────────────────────────
  // GET /api/aggregate/teams/roles
  @override
  Future<List<RoleEntity>> getAll() async {
    final cached = (await localDataSource.getAll())
        .where((role) => role.teamId.isEmpty)
        .toList();
    if (cached.isNotEmpty) return cached;
    return refreshRoles();
  }

  /// Force-refresh from remote, bypassing cache.
  Future<List<RoleEntity>> refreshRoles() async {
    try {
      final response = await DioClient().dio.get(endpoint);

      dev.log(
        'RoleRemoteDataSource.refreshRoles: status=${response.statusCode} data=${response.data}',
      );

      if (response.data == null) return [];

      List<dynamic> rawList;
      if (response.data is List) {
        rawList = response.data as List;
      } else if (response.data is Map<String, dynamic>) {
        // Handle Spring Page wrapper
        final map = response.data as Map<String, dynamic>;
        rawList = (map['content'] ?? map['data'] ?? map['roles'] ?? []) as List;
      } else {
        return [];
      }

      final roles = rawList
          .where((e) => e != null)
          .map((e) => RoleMapper.fromJson(e as Map<String, dynamic>))
          .toList();
      await localDataSource.saveAll(roles);
      return roles;
    } catch (e) {
      dev.log('RoleRemoteDataSource.refreshRoles ERROR: $e');
      throw Exception('Failed to refresh roles: $e');
    }
  }

  Future<List<RoleEntity>> getAllByTeamId(String teamId) async {
    try {
      final response = await DioClient().dio.get('/api/aggregate/teams/$teamId/roles');
      if (response.data == null) return [];

      final rawList = response.data is List
          ? response.data as List
          : ((response.data as Map<String, dynamic>)['content'] ?? []) as List;

      final roles = rawList
          .where((e) => e != null)
          .map((e) => RoleMapper.fromJson(e as Map<String, dynamic>))
          .toList();
      await localDataSource.saveAll(roles);
      return roles;
    } catch (e) {
      dev.log('RoleRemoteDataSource.getAllByTeamId ERROR: $e');
      final cached = await localDataSource.getAllByTeamId(teamId);
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to fetch team roles: $e');
    }
  }

  @override
  Future<RoleEntity> create(RoleEntity item) async {
    final response = await DioClient().dio.post(
      '/api/aggregate/teams/${item.teamId}/roles',
      data: RoleMapper.toJson(item),
    );
    return RoleMapper.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    final roles = await localDataSource.getAll();
    final role = roles.where((item) => item.id == id).firstOrNull;
    if (role == null || role.teamId.isEmpty) {
      throw Exception('Role team scope not found for delete');
    }
    await DioClient().dio.delete('/api/aggregate/teams/${role.teamId}/roles/$id');
  }

  @override
  Future<RoleEntity> getById(String id) async {
    final roles = await localDataSource.getAll();
    return roles.firstWhere((role) => role.id == id);
  }

  @override
  Future<RoleEntity> update(String id, RoleEntity item) async {
    final response = await DioClient().dio.put(
      '/api/aggregate/teams/${item.teamId}/roles/$id',
      data: RoleMapper.toJson(item),
    );
    return RoleMapper.fromJson(response.data as Map<String, dynamic>);
  }
}
