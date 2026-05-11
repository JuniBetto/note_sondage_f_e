import 'package:equatable/equatable.dart';

class MfaFactorHintEntity extends Equatable {
  const MfaFactorHintEntity({
    required this.uid,
    this.displayName,
    this.phoneNumber,
  });

  final String uid;
  final String? displayName;
  final String? phoneNumber;

  String get label {
    final normalizedDisplayName = displayName?.trim();
    if (normalizedDisplayName != null && normalizedDisplayName.isNotEmpty) {
      return normalizedDisplayName;
    }

    final normalizedPhone = phoneNumber?.trim();
    if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
      return normalizedPhone;
    }

    return 'SMS';
  }

  @override
  List<Object?> get props => [uid, displayName, phoneNumber];
}
