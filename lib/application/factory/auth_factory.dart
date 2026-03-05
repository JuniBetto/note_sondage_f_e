import 'package:note_sondage/domain/repositories/interface_auth.dart';

abstract class AuthFactory {
  IAuthRepository createAuthRepository();
}
