class TeamInvitationEntity {
  final String id;
  final String teamId;
  final String invitedEmail;
  final String proposedRole;
  final String status; // PENDING, PENDING_REGISTRATION, ACCEPTED, REJECTED
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const TeamInvitationEntity({
    required this.id,
    required this.teamId,
    required this.invitedEmail,
    required this.proposedRole,
    required this.status,
    this.expiresAt,
    this.createdAt,
  });

  bool get isCancellable =>
      status == 'PENDING' || status == 'PENDING_REGISTRATION';
}
