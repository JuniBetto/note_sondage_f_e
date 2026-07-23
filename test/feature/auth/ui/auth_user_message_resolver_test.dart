import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';

void main() {
  group('AuthUserMessageResolver', () {
    test('maps unauthorized errors to a session-expired message', () {
      final message = AuthUserMessageResolver.resolve(
        Exception('401 unauthorized'),
      );

      expect(message, 'Your session has expired. Please sign in again.');
    });

    test('uses fallback for technical or unreadable errors', () {
      final message = AuthUserMessageResolver.resolve(
        Object(),
        fallback: 'Auth fallback',
      );

      expect(message, 'Auth fallback');
    });
  });
}
