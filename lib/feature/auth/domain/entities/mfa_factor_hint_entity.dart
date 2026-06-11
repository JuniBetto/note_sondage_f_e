import 'package:equatable/equatable.dart';

enum MfaFactorType { sms, totp }

class MfaFactorHintEntity extends Equatable {
  const MfaFactorHintEntity({
    required this.uid,
    required this.type,
    this.displayName,
    this.phoneNumber,
  });

  final String uid;
  final MfaFactorType type;
  final String? displayName;
  final String? phoneNumber;

  bool get isSms => type == MfaFactorType.sms;
  bool get isTotp => type == MfaFactorType.totp;

  String get label {
    final normalizedDisplayName = displayName?.trim();
    if (normalizedDisplayName != null && normalizedDisplayName.isNotEmpty) {
      return normalizedDisplayName;
    }

    final normalizedPhone = phoneNumber?.trim();
    if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
      return normalizedPhone;
    }

    return isTotp ? 'Authenticator app' : 'SMS';
  }

  String get methodLabel => isTotp ? 'Authenticator app' : 'SMS';

  String get signInPrompt {
    if (isTotp) {
      return 'Open your authenticator app and enter the current verification code.';
    }
    return 'We sent a verification code to $label.';
  }

  @override
  List<Object?> get props => [uid, type, displayName, phoneNumber];
}
