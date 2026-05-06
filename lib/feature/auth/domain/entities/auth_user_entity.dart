import 'package:equatable/equatable.dart';

/// Entità utente autenticato.
/// Rappresenta l'utente corrente nel sistema di autenticazione.
class AuthUserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final String? phoneNumber;
  final AuthProvider provider;

  const AuthUserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.phoneNumber,
    this.provider = AuthProvider.email,
  });

  /// Utente vuoto (non autenticato)
  static const empty = AuthUserEntity(uid: '', email: '');

  bool get isEmpty => this == AuthUserEntity.empty;
  bool get isNotEmpty => this != AuthUserEntity.empty;

  AuthUserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    String? phoneNumber,
    AuthProvider? provider,
  }) {
    return AuthUserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      provider: provider ?? this.provider,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    emailVerified,
    phoneNumber,
    provider,
  ];
}

/// Provider di autenticazione supportati
enum AuthProvider {
  email('EMAIL'),
  google('GOOGLE'),
  phone('PHONE'),
  apple('APPLE'),
  anonymous('ANONYMOUS');

  final String value;
  const AuthProvider(this.value);

  factory AuthProvider.fromString(String value) {
    return AuthProvider.values.firstWhere(
      (p) => p.value == value.toUpperCase(),
      orElse: () => AuthProvider.email,
    );
  }
}

/// Stati di autenticazione
enum AuthStatus {
  /// Stato iniziale: non sappiamo ancora se l'utente è autenticato
  unknown,

  /// Operazione in corso (login / register / SSO)
  loading,

  /// L'utente è autenticato
  authenticated,

  /// L'utente non è autenticato
  unauthenticated,
}
