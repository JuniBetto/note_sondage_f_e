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
    final cached = await localDataSource.getAll();
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

  /// Roles are global in Spring — just return all.
  Future<List<RoleEntity>> getAllByTeamId(String teamId) => getAll();

  // ── CRUD stubs (roles are managed server-side) ───────────────────────────

  @override
  Future<RoleEntity> create(RoleEntity item) =>
      throw UnimplementedError('Roles are managed server-side');

  @override
  Future<void> delete(String id) =>
      throw UnimplementedError('Roles are managed server-side');

  @override
  Future<RoleEntity> getById(String id) =>
      throw UnimplementedError('Use getAll() instead');

  @override
  Future<RoleEntity> update(String id, RoleEntity item) =>
      throw UnimplementedError('Roles are managed server-side');
}
