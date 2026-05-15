import 'package:note_sondage/core/utils/app_error_message_resolver.dart';

class AuthUserMessageResolver {
  const AuthUserMessageResolver._();

  static String resolve(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return AppErrorMessageResolver.resolve(error, fallback: fallback);
  }
}
