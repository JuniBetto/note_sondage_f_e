class UserDeviceEntity {
  const UserDeviceEntity({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.clientApp,
    required this.pushProvider,
    required this.deviceFingerprint,
    required this.lastIpAddress,
    required this.lastSeenAt,
    required this.trusted,
    required this.revoked,
    required this.createdAt,
  });

  final String id;
  final String? deviceName;
  final String? platform;
  final String? clientApp;
  final String? pushProvider;
  final String? deviceFingerprint;
  final String? lastIpAddress;
  final DateTime? lastSeenAt;
  final bool trusted;
  final bool revoked;
  final DateTime? createdAt;

  factory UserDeviceEntity.fromJson(Map<String, dynamic> json) {
    return UserDeviceEntity(
      id: json['id']?.toString() ?? '',
      deviceName: json['deviceName']?.toString(),
      platform: json['platform']?.toString(),
      clientApp: json['clientApp']?.toString(),
      pushProvider: json['pushProvider']?.toString(),
      deviceFingerprint: json['deviceFingerprint']?.toString(),
      lastIpAddress: json['lastIpAddress']?.toString(),
      lastSeenAt: DateTime.tryParse(json['lastSeenAt']?.toString() ?? ''),
      trusted: json['trusted'] == true,
      revoked: json['revoked'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
