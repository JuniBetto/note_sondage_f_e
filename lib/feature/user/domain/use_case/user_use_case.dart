import 'package:note_sondage/feature/team/domain/entities/user_entity.dart';
import 'package:note_sondage/feature/user/domain/repositories/user_repository.dart';

class UserUseCase {
  final UserRepository repository;
  UserUseCase(this.repository);

  Future<List<UserEntity>> getAllUsers() async {
    try {
      return await repository.getAll();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<UserEntity?> getUserById(String id) async {
    try {
      return await repository.getById(id);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<UserEntity?> getUserByEmail(String email) async {
    try {
      return await repository.getByEmail(email);
    } catch (e) {
      throw Exception('Failed to fetch user by email: $e');
    }
  }

  /// Trova un utente per email, se non esiste lo crea con is_active = false
  Future<UserEntity> getOrCreateUserByEmail(String email) async {
    try {
      // Prima cerca se l'utente esiste già
      final existingUser = await repository.getByEmail(email);
      if (existingUser != null) {
        return existingUser;
      }
      // Se non esiste, crea un nuovo utente inattivo
      return await repository.createInactive(email);
    } catch (e) {
      throw Exception('Failed to get or create user: $e');
    }
  }

  Future<UserEntity> createUser(UserEntity user) async {
    try {
      return await repository.create(user);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserEntity> createInactiveUser(String email) async {
    try {
      return await repository.createInactive(email);
    } catch (e) {
      throw Exception('Failed to create inactive user: $e');
    }
  }

  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      return await repository.update(user);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      return await repository.delete(id);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
