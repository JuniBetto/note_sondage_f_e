import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';

void main() {
  group('AppErrorMessageResolver', () {
    test('extracts nested downstream backend messages', () {
      final error = DioException(
        requestOptions: RequestOptions(
          path: '/api/aggregate/shift/assignments',
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(
            path: '/api/aggregate/shift/assignments',
          ),
          statusCode: 400,
          data: <String, dynamic>{
            'errorMessage':
                'Errore downstream : {"status":400,"message":"Questo utente ha gia un turno personale o dello stesso team che si sovrappone nello stesso intervallo."}',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = AppErrorMessageResolver.resolve(
        error,
        fallback: 'fallback',
      );

      expect(
        message,
        'Questo utente ha gia un turno personale o dello stesso team che si sovrappone nello stesso intervallo.',
      );
    });

    test('extracts plain backend errorMessage values', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/aggregate/teams'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/aggregate/teams'),
          statusCode: 500,
          data: <String, dynamic>{
            'errorMessage':
                'Errore generico : Method parameter teamId is invalid.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = AppErrorMessageResolver.resolve(
        error,
        fallback: 'fallback',
      );

      expect(message, 'Method parameter teamId is invalid.');
    });
  });
}
