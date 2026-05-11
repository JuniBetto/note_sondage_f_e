import 'package:equatable/equatable.dart';

class TotpEnrollmentSecretEntity extends Equatable {
  const TotpEnrollmentSecretEntity({
    required this.secretKey,
    required this.qrCodeUrl,
    required this.accountName,
    required this.issuer,
    this.codeLength,
    this.codeIntervalSeconds,
  });

  final String secretKey;
  final String qrCodeUrl;
  final String accountName;
  final String issuer;
  final int? codeLength;
  final int? codeIntervalSeconds;

  @override
  List<Object?> get props => [
    secretKey,
    qrCodeUrl,
    accountName,
    issuer,
    codeLength,
    codeIntervalSeconds,
  ];
}
