import 'package:equatable/equatable.dart';
import 'package:note_sondage/ui/bloc/auth_bloc/auth_state.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthStatusChanged extends AuthEvent {
  final AuthState status;
  const AuthStatusChanged(this.status);
  @override
  List<Object> get props => [status];
}

class AuthLogoutRequested extends AuthEvent {}
