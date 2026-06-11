import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';

class AuthMfaRequiredException implements Exception {
  const AuthMfaRequiredException({
    required this.factors,
    this.message = 'A second verification step is required.',
  });

  final List<MfaFactorHintEntity> factors;
  final String message;

  @override
  String toString() => message;
}
