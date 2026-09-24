import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/chat/domain/entities/blocked_user_entity.dart';
import 'package:note_sondage/feature/chat/ui/cubit/blocked_users_cubit.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// The "Blocked users" settings surface — embedded both in the mobile
/// settings bottom sheet and as a web settings tab, mirroring how
/// `SettingsPrivacyWeb` is already shared between the two (plain content
/// widget, no `Scaffold`).
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BlockedUsersCubit>.value(
      value: getIt<BlockedUsersCubit>()..load(),
      child: const _BlockedUsersView(),
    );
  }
}

class _BlockedUsersView extends StatelessWidget {
  const _BlockedUsersView();

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: Color(0xFFF44336),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localization.blockedUsersTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localization.blockedUsersSubtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          BlocConsumer<BlockedUsersCubit, BlockedUsersState>(
            listenWhen: (previous, current) =>
                current.status == BlockedUsersStatus.error &&
                current.errorMessage != null &&
                current.errorMessage != previous.errorMessage,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            },
            builder: (context, state) {
              if (state.status == BlockedUsersStatus.initial ||
                  state.status == BlockedUsersStatus.loading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.blockedUsers.isEmpty) {
                return _BlockedUsersEmptyState(
                  isError: state.status == BlockedUsersStatus.error,
                );
              }
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.homeSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.borderColor!.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < state.blockedUsers.length; i++)
                      _BlockedUserTile(
                        user: state.blockedUsers[i],
                        showDivider: i < state.blockedUsers.length - 1,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BlockedUsersEmptyState extends StatelessWidget {
  const _BlockedUsersEmptyState({required this.isError});

  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.homeSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.borderColor!.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          isError
              ? _localizedText(
                  locale,
                  it: 'Non siamo riusciti a caricare gli utenti bloccati.',
                  en: 'We could not load your blocked users.',
                )
              : _localizedText(
                  locale,
                  it: 'Non hai bloccato nessun utente.',
                  en: 'You have not blocked anyone yet.',
                ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.descriptionColor,
          ),
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({required this.user, required this.showDivider});

  final BlockedUserEntity user;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final displayName = user.displayName.trim().isEmpty
        ? user.userId
        : user.displayName.trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () =>
                    context.read<BlockedUsersCubit>().unblock(user.userId),
                child: Text(
                  _localizedText(locale, it: 'Sblocca', en: 'Unblock'),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: colorScheme.borderColor!.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

String _localizedText(
  String locale, {
  required String it,
  required String en,
}) {
  return locale == 'it' ? it : en;
}
