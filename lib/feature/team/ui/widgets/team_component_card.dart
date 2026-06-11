import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/action_on_user.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/avatar_app.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_confirmation_dialog.dart';

class TeamComponentCard extends StatefulWidget {
  const TeamComponentCard({
    super.key,
    required this.colorTeam,
    required this.isActive,
    this.onTap,
    required this.teamName,
    required this.teamFocus,
    required this.teamId,
    this.members,
    this.memberCount,
    this.onDeleteTap,
    this.onArchiveTap,
    this.isOwner = false,
    this.isArchived = false,
    this.isSyncing = false,
    this.currentUserId,
    this.currentUserEmail,
    this.currentUserPhotoUrl,
  });
  final Color colorTeam;
  final String teamName;
  final String teamFocus;
  final String teamId;
  final bool isActive;
  final List<Map<String, dynamic>>? members;
  final int? memberCount;
  final void Function()? onTap;
  final void Function(String id)? onDeleteTap;
  final VoidCallback? onArchiveTap;
  final bool isOwner;
  final bool isArchived;
  final bool isSyncing;
  final String? currentUserId;
  final String? currentUserEmail;
  final String? currentUserPhotoUrl;

  @override
  State<TeamComponentCard> createState() => _TeamComponentCardState();
}

class _TeamComponentCardState extends State<TeamComponentCard> {
  bool _isHovered = false;

  Future<void> _confirmDelete(BuildContext context) async {
    final localization = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmationDialog(
      context,
      title: localization.deleteTeamTitle,
      message: localization.deleteTeamMessage,
      confirmLabel: localization.deleteAction,
      destructive: true,
    );
    if (confirmed) {
      widget.onDeleteTap?.call(widget.teamId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Opacity(
          opacity: widget.isSyncing ? 0.78 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Column(
              children: [
                SizedBox(
                  width: _isHovered ? 180 : 160,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 20.0,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: colorScheme.bgColor,
                              borderRadius: BorderRadius.circular(30),
                              border: (widget.isActive || _isHovered)
                                  ? Border.all(
                                      color: colorScheme.selectionColor!,
                                      width: 3,
                                    )
                                  : null,
                              boxShadow: _isHovered
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: colorScheme.avatarTextColor!,
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6.0,
                                            horizontal: 8,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            spacing: 8,
                                            children: [
                                              ActionOnUser(
                                                iconSize: 18,
                                                icon: Icons.edit,
                                                color: colorScheme.cursorColor!,
                                                onTap: () {
                                                  context.go(
                                                    RouterPaths.updateTeam,
                                                    extra: widget.teamId,
                                                  );
                                                },
                                              ),
                                              ActionOnUser(
                                                iconSize: 18,
                                                icon: widget.isArchived
                                                    ? Icons.unarchive_outlined
                                                    : Icons.archive_outlined,
                                                color: Colors.blueGrey,
                                                onTap: widget.onArchiveTap,
                                              ),
                                              if (widget.isOwner)
                                                ActionOnUser(
                                                  iconSize: 18,
                                                  icon: Icons
                                                      .delete_forever_outlined,
                                                  color:
                                                      colorScheme.deleteCard!,
                                                  onTap: () {
                                                    _confirmDelete(context);
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.isSyncing)
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 6),
                                          child: _SyncBadge(),
                                        ),
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          widget.teamName,
                                          style: textTheme.bodySmall!.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          softWrap: true,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        spacing: 4,
                                        children: [
                                          const Icon(
                                            Icons.gps_fixed,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              widget.teamFocus,
                                              style: textTheme.labelMedium,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 3,
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: const [
                                          Expanded(
                                            child: Divider(
                                              height: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        localization.teamMember,
                                        style: textTheme.labelMedium!.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      buildRowTeamItem(
                                        context,
                                        widget.members ?? [],
                                        memberCount: widget.memberCount,
                                        currentUserId: widget.currentUserId,
                                        currentUserEmail:
                                            widget.currentUserEmail,
                                        currentUserPhotoUrl:
                                            widget.currentUserPhotoUrl,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        top: 0,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(widget.colorTeam.toARGB32()),
                          child: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF1C972)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 6),
          Text(
            'Syncing',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A5A00),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildTeamItem(
  List<Map<String, dynamic>> membersAvatar, {
  int? memberCount,
  String? currentUserId,
  String? currentUserEmail,
  String? currentUserPhotoUrl,
}) {
  final visibleMembers = membersAvatar.take(2).toList();
  if (visibleMembers.isEmpty && (memberCount ?? 0) > 0) {
    final placeholders = (memberCount! >= 2 ? 2 : 1);
    return Row(
      spacing: 2,
      children: List.generate(
        placeholders,
        (index) => AvatarApp(
          initials: '?',
          size: 24,
          backgroundColor: Colors.grey.shade400,
          textColor: Colors.white,
        ),
      ),
    );
  }
  return Row(
    spacing: 2,
    children: visibleMembers.map((member) {
      final name = (member['name'] ?? '') as String;
      final memberUserId = member['userId']?.toString().trim();
      final memberEmail = member['email']?.toString().trim().toLowerCase();
      final normalizedCurrentEmail = currentUserEmail?.trim().toLowerCase();
      final fallbackImageUrl =
          currentUserPhotoUrl != null &&
              currentUserPhotoUrl.isNotEmpty &&
              ((currentUserId != null &&
                      currentUserId.isNotEmpty &&
                      memberUserId == currentUserId) ||
                  (normalizedCurrentEmail != null &&
                      normalizedCurrentEmail.isNotEmpty &&
                      memberEmail == normalizedCurrentEmail))
          ? currentUserPhotoUrl
          : null;
      final initials = name.isNotEmpty
          ? name
                .split(' ')
                .where((e) => e.isNotEmpty)
                .map((e) => e[0].toUpperCase())
                .take(2)
                .join()
          : '?';
      return AvatarApp(
        imageUrl: (member['imageUrl'] ?? fallbackImageUrl)?.toString(),
        initials: initials,
        size: 24,
        backgroundColor: member['color'] ?? Colors.grey,
        textColor: Colors.white,
      );
    }).toList(),
  );
}

Widget buildRowTeamItem(
  BuildContext context,
  List<Map<String, dynamic>> members, {
  int? memberCount,
  String? currentUserId,
  String? currentUserEmail,
  String? currentUserPhotoUrl,
}) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;
  final colorScheme = theme.colorScheme;
  final localization = AppLocalizations.of(context)!;
  final totalMembers = memberCount ?? members.length;
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: buildTeamItem(
            members,
            memberCount: memberCount,
            currentUserId: currentUserId,
            currentUserEmail: currentUserEmail,
            currentUserPhotoUrl: currentUserPhotoUrl,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.calendarTextBg!, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 12,
              child: Icon(
                Icons.add,
                size: 20,
                color: colorScheme.calendarTextBg,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: localization.member(totalMembers),
          child: Text(
            '$totalMembers',
            style: textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.fade,
          ),
        ),
      ],
    ),
  );
}
