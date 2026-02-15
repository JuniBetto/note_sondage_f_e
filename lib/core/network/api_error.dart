import 'package:note_sondage/core/error/app_exceptions.dart';

class ApiError {
  final AppException appException;
  final dynamic data;
  final DateTime timestamp;

  ApiError({required this.appException, this.data, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  factory ApiError.fromApiException(ApiException exception) {
    return ApiError(appException: exception);
  }

  factory ApiError.fromGenericApiError(dynamic error, int? statusCode) {
    return ApiError(
      appException: ApiException(
        "Errore generico",
        statusCode: statusCode,
        responseData: error,
      ),
      data: error,
    );
  }

  factory ApiError.fromNetworkError(String message) {
    return ApiError(appException: NetworkException(message), data: message);
  }

  factory ApiError.parseError(dynamic rawData) {
    return ApiError(
      appException: DatabaseException('Errore nel parsing della risposta'),
      data: rawData,
    );
  }
}
