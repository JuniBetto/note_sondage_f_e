import 'package:note_sondage/core/network/api_response.dart';
import 'package:note_sondage/core/utils/interface/api_interceptor.dart';

abstract class IApiService {
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  });

  void addInterceptor(ApiInterceptor interceptor);
  void clearInterceptors();
}
