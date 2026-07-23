import 'package:flutter/material.dart';

bool isSelfTeamInviteBlocked({
  required bool currentUserIsOwner,
  required String currentUserEmail,
  required String invitedEmail,
  Iterable<String> activeTeamMemberEmails = const <String>[],
}) {
  final normalizedInvitedEmail = invitedEmail.trim().toLowerCase();
  if (normalizedInvitedEmail.isEmpty) {
    return false;
  }

  final normalizedCurrentEmail = currentUserEmail.trim().toLowerCase();
  if (currentUserIsOwner &&
      normalizedCurrentEmail.isNotEmpty &&
      normalizedCurrentEmail == normalizedInvitedEmail) {
    return true;
  }

  return activeTeamMemberEmails
      .map((email) => email.trim().toLowerCase())
      .where((email) => email.isNotEmpty)
      .contains(normalizedInvitedEmail);
}

String selfTeamInviteBlockedMessage(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  switch (code) {
    case 'it':
      return 'L\'utente fa gia parte del team.';
    case 'fr':
      return "L'utilisateur fait deja partie de l'equipe.";
    case 'es':
      return 'El usuario ya forma parte del equipo.';
    default:
      return 'The user is already part of the team.';
  }
}
