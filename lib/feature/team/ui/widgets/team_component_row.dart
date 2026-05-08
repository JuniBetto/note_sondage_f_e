import 'package:dart_code_metrics/cli_runner.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/action_on_user.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/avatar_app.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:printing/printing.dart';

class TeamComponentRow extends StatefulWidget {
  const TeamComponentRow({
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

  @override
  State<TeamComponentRow> createState() => _TeamComponentRowState();
}

class _TeamComponentRowState extends State<TeamComponentRow> {
  bool _isHovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Elimina team'),
        content: const Text(
          'Sei sicuro di voler eliminare questo team? L\'azione è irreversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteTap?.call(widget.teamId);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (PointerEnterEvent event) => setState(() => _isHovered = true),
      onExit: (PointerExitEvent event) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Column(
            children: [
              SizedBox(
                //height: 60,
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
                          horizontal: 8.0,
                          vertical: 40.0,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
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
                                      color: colorScheme.selectionColor!
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
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
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          spacing: 8,
                                          children: [
                                            ActionOnUser(
                                              iconSize: 28,
                                              icon: Icons.edit,
                                              color: colorScheme.cursorColor!,
                                              onTap: () {
                                                print('edit team');
                                                context.go(
                                                  RouterPaths.updateTeam,
                                                  extra: widget.teamId,
                                                );
                                              },
                                            ),
                                            ActionOnUser(
                                              iconSize: 28,
                                              icon: widget.isArchived
                                                  ? Icons.unarchive_outlined
                                                  : Icons.archive_outlined,
                                              color: Colors.blueGrey,
                                              onTap: widget.onArchiveTap,
                                            ),
                                            if (widget.isOwner)
                                              ActionOnUser(
                                                iconSize: 28,
                                                icon: Icons
                                                    .delete_forever_outlined,
                                                color: colorScheme.deleteCard!,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.teamName,
                                      style: textTheme.headlineSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      spacing: 8,
                                      children: [
                                        Icon(
                                          Icons.gps_fixed,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        Text(
                                          widget.teamFocus,
                                          style: textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
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
                                      style: textTheme.bodyLarge!.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    buildRowTeamItem(
                                      context,
                                      widget.members ?? [],
                                      memberCount: widget.memberCount,
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
                      left: 32,
                      top: 0,
                      child: CircleAvatar(
                        radius: 32,
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
    );
  }
}

Widget buildTeamItem(List<Map<String, dynamic>> membersAvatar) {
  final visibleMembers = membersAvatar.take(3).toList();
  return Row(
    spacing: 4,
    children: visibleMembers.map((member) {
      final name = (member['name'] ?? '') as String;
      final initials = name.isNotEmpty
          ? name
                .split(' ')
                .where((e) => e.isNotEmpty)
                .map((e) => e[0].toUpperCase())
                .take(2)
                .join()
          : '?';
      return AvatarApp(
        imageUrl: member['imageUrl'],
        initials: initials,
        size: 40,
        backgroundColor: member['color'] ?? Colors.grey,
        textColor: Colors.white,
        onTap: () => print('Tapped on ${member['name']}'),
      );
    }).toList(),
  );
}

Widget buildRowTeamItem(
  BuildContext context,
  List<Map<String, dynamic>> members, {
  int? memberCount,
}) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;
  final colorScheme = theme.colorScheme;
  final localization = AppLocalizations.of(context)!;
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 8,
      children: [
        buildTeamItem(members),

        GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.calendarTextBg!, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 20,
              child: Icon(
                Icons.add,
                size: 32,
                color: colorScheme.calendarTextBg,
              ),
            ),
          ),
        ),
        Text(
          " ${localization.member(memberCount ?? members.length)}",
          style: textTheme.bodyLarge,
        ),
      ],
    ),
  );
}
