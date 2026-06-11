import 'package:equatable/equatable.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';

class PhoneSignInStartResult extends Equatable {
  final String? sessionId;
  final bool requiresSmsCode;
  final AuthUserEntity? user;

  const PhoneSignInStartResult({
    this.sessionId,
    required this.requiresSmsCode,
    this.user,
  });

  const PhoneSignInStartResult.codeSent(String sessionId)
    : this(sessionId: sessionId, requiresSmsCode: true);

  const PhoneSignInStartResult.completed(AuthUserEntity user)
    : this(user: user, requiresSmsCode: false);

  @override
  List<Object?> get props => [sessionId, requiresSmsCode, user];
}
