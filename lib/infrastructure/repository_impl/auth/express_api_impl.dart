import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/api_config.dart';
import 'package:note_sondage/core/network/api_response.dart';
import 'package:note_sondage/core/utils/interface/api_interceptor.dart';
import 'package:note_sondage/domain/repositories/interface_api_service.dart';

class ExpressApiImpl implements IApiService {
  final Dio dio;
  final ApiConfig config;
  ExpressApiImpl({required this.dio, required this.config});

  @override
  void addInterceptor(ApiInterceptor interceptor) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          interceptor.onRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          interceptor.onResponse(response);
          handler.next(response);
        },
        onError: (error, handler) {
          interceptor.onError(error);
          handler.next(error);
        },
      ),
    );
  }

  @override
  void clearInterceptors() {
    dio.interceptors.clear();
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic> p1)? fromJson,
  }) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(Map<String, dynamic> p1)? fromJson,
  }) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    data,
    Map<String, String>? headers,
    T Function(Map<String, dynamic> p1)? fromJson,
  }) {
    // TODO: implement post
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    data,
    Map<String, String>? headers,
    T Function(Map<String, dynamic> p1)? fromJson,
  }) {
    // TODO: implement put
    throw UnimplementedError();
  }
}
