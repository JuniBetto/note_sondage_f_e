import 'package:dio/dio.dart';

abstract class CrudService<T> {
  final Dio dio;
  final String endpoint;

  CrudService(this.dio, this.endpoint);

  /// Converte JSON → Entity
  /*T fromJson(Map<String, dynamic> json);

  /// Converte Entity → JSON
  Map<String, dynamic> toJson(T item);*/

  // ---------------- CRUD ----------------

  Future<List<T>> getAll();

  Future<T> getById(String id);

  Future<T> create(T item);

  Future<T> update(String id, T item);
  Future<void> delete(String id);
}
