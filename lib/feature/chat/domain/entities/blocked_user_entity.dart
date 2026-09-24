class BlockedUserEntity {
  const BlockedUserEntity({
    required this.userId,
    required this.displayName,
    required this.blockedAt,
  });

  final String userId;
  final String displayName;
  final DateTime blockedAt;
}
