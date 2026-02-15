// core/network/api_response.dart
import 'package:dio/dio.dart';
import 'package:note_sondage/core/error/app_exceptions.dart';
import 'package:note_sondage/core/network/api_error.dart';

class ApiResponse<T> {
  final T? data;
  final ApiError? error;
  final bool isSuccess;

  ApiResponse.success(this.data) : error = null, isSuccess = true;

  ApiResponse.error(this.error) : data = null, isSuccess = false;

  factory ApiResponse.fromHttpResponse(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final T data;

        if (fromJson != null && response.data is Map<String, dynamic>) {
          data = fromJson(response.data as Map<String, dynamic>);
        } else if (response.data is T) {
          data = response.data as T;
        } else {
          return ApiResponse.error(ApiError.parseError(response.data));
        }

        return ApiResponse.success(data);
      } else {
        return ApiResponse.error(
          ApiError.fromGenericApiError(response.data, response.statusCode),
        );
      }
    } on AppException catch (e) {
      return ApiResponse.error(ApiError(appException: e));
    } catch (e) {
      return ApiResponse.error(
        ApiError.fromGenericApiError(e, response.statusCode),
      );
    }
  }

  /// Pattern fold per gestire successo/errore
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(ApiError error) onError,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    } else if (error != null) {
      return onError(error!);
    }
    throw StateError('Invalid ApiResponse state');
  }
}
