import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/team/domain/entities/user_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/user_mapper.dart';

class UserRemoteDataSource {
  final String endpoint = '/users';

  Future<List<UserEntity>> getAll() async {
    try {
      final response = await DioClient().dio.get('$endpoint/all');

      if (response.data == null) {
        return [];
      }

      final data = response.data as List;
      return data
          .where((e) => e != null)
          .map((e) => UserMapper.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<UserEntity?> getById(String id) async {
    try {
      final response = await DioClient().dio.get('$endpoint/$id');
      if (response.data == null) return null;
      return UserMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<UserEntity?> getByEmail(String email) async {
    try {
      final response = await DioClient().dio.get('$endpoint/by-email/$email');
      if (response.data == null) return null;
      return UserMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      // Se l'utente non esiste, ritorna null invece di lanciare un'eccezione
      return null;
    }
  }

  Future<UserEntity> create(UserEntity user) async {
    try {
      final response = await DioClient().dio.post(
        '$endpoint/create',
        data: UserMapper.toJson(user),
      );
      return UserMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Crea un utente inattivo con solo email (per inviti)
  Future<UserEntity> createInactive(String email) async {
    try {
      final response = await DioClient().dio.post(
        '$endpoint/create-inactive',
        data: UserMapper.toJsonForInactiveUser(email),
      );
      return UserMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create inactive user: $e');
    }
  }

  Future<UserEntity> update(UserEntity user) async {
    try {
      final response = await DioClient().dio.put(
        '$endpoint/update/${user.id}',
        data: UserMapper.toJson(user),
      );
      return UserMapper.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await DioClient().dio.delete('$endpoint/delete/$id');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<List<UserEntityForUpdate>> getAllByTeamId(String teamId) async {
    try {
      final response = await DioClient().dio.get(
        '$endpoint/list_on_team/$teamId',
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data as List;
      return data
          .where((e) => e != null)
          .map((e) => UserMapper.fromJsonUpdate(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users by team: $e');
    }
  }
}
