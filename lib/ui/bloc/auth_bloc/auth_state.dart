import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

//class AuthInitial extends AuthState {}

class AuthUnknown extends AuthState {}

class AuthAuthenticated extends AuthState {} // Utente loggato

class AuthUnauthenticated extends AuthState {} // Utente non loggato
