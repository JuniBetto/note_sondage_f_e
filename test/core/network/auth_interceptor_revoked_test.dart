import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/core/network/auth_interceptor.dart';

/// Registra l'errore passato avanti invece di completare il future interno.
class _RecordingHandler extends ErrorInterceptorHandler {
  DioException? passedOn;

  @override
  void next(DioException err) => passedOn = err;
}

void main() {
  late int revokedCalls;

  setUp(() {
    revokedCalls = 0;
    AuthInterceptor.onAccountRevoked = () => revokedCalls++;
  });

  tearDown(() => AuthInterceptor.onAccountRevoked = null);

  DioException unauthorized(Object? body) {
    final options = RequestOptions(path: '/api/teams');
    return DioException(
      requestOptions: options,
      response: Response<Object?>(
        requestOptions: options,
        statusCode: 401,
        data: body,
      ),
    );
  }

  test('a 401 for a deactivated account triggers the forced logout', () {
    final handler = _RecordingHandler();
    AuthInterceptor().onError(
      unauthorized({'error': 'Account disabled or deactivated'}),
      handler,
    );

    expect(revokedCalls, 1);
    expect(handler.passedOn?.response?.statusCode, 401);
  });

  test('a 401 with a plain-text deactivated body triggers the logout', () {
    AuthInterceptor().onError(
      unauthorized('{"error":"Account disabled or deactivated"}'),
      _RecordingHandler(),
    );

    expect(revokedCalls, 1);
  });

  test('an ordinary 401 does not log the user out', () {
    AuthInterceptor().onError(
      unauthorized({'error': 'Token non valido o scaduto'}),
      _RecordingHandler(),
    );

    expect(revokedCalls, 0);
  });
}
