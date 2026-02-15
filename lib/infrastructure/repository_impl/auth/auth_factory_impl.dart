import 'package:note_sondage/application/factory/auth_factory.dart';
import 'package:note_sondage/domain/entities/all_enum.dart';
import 'package:note_sondage/domain/repositories/interface_auth.dart';

class AuthFactoryImpl implements AuthFactory {
  final IAuthRepository _repository;
  AuthFactoryImpl(this._repository);

  @override
  IAuthRepository createAuthRepository() {
    return _repository;
  }
}
