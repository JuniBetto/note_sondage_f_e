import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/action_on_user.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/avatar_app.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class TeamComponentCard extends StatelessWidget {
  const TeamComponentCard({
    super.key,
    required this.colorTeam,
    required this.isActive,
    this.onTap,
    required this.teamName,
    required this.teamFocus,
    required this.teamId,
    this.members,
    this.onDeleteTap,
  });
  final Color colorTeam;
  final String teamName;
  final String teamFocus;
  final String teamId;
  final bool isActive;
  final List<Map<String, dynamic>>? members;
  final void Function()? onTap;
  final void Function(String id)? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Column(
          children: [
            SizedBox(
              width: 180,
              //height: 60,
              child: Stack(
                alignment: Alignment.topLeft,
                clipBehavior: Clip.none,
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 20.0,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.bgColor,
                            borderRadius: BorderRadius.circular(30),
                            border: isActive
                                ? Border.all(
                                    color: colorScheme.selectionColor!,
                                    width: 3,
                                  )
                                : null,
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
                                        borderRadius: BorderRadius.circular(30),
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
                                                print('Edit team');
                                                context.go(
                                                  RouterPaths.updateTeam,
                                                  extra: teamId,
                                                );
                                              },
                                            ),
                                            ActionOnUser(
                                              iconSize: 18,
                                              icon:
                                                  Icons.delete_forever_outlined,
                                              color: colorScheme.deleteCard!,
                                              onTap: () {
                                                onDeleteTap?.call(teamId);
                                              },
                                            ),

                                            /* DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .selectionColor!
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color:
                                                      colorScheme.cursorColor!,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4.0,
                                                ),
                                                child: Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                  color:
                                                      colorScheme.cursorColor!,
                                                ),
                                              ),
                                            ),*/
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
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        teamName,
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
                                        Icon(
                                          Icons.gps_fixed,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            teamFocus,
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
                                      style: textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    buildRowTeamItem(context, members ?? []),
                                  ],
                                ),
                              ],
                            ),
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
                      backgroundColor: Color(colorTeam.toARGB32()),
                      child: null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildTeamItem(List<Map<String, dynamic>> membersAvatar) {
  final visibleMembers = membersAvatar.take(2).toList();
  return Row(
    spacing: 2,
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
        size: 24,
        backgroundColor: member['color'] ?? Colors.grey,
        textColor: Colors.white,
        onTap: () => print('Tapped on ${member['name']}'),
      );
    }).toList(),
  );
}

Widget buildRowTeamItem(
  BuildContext context,
  List<Map<String, dynamic>> members,
) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;
  final colorScheme = theme.colorScheme;
  final localization = AppLocalizations.of(context)!;
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 4,
      children: [
        buildTeamItem(members),

        GestureDetector(
          onTap: () {
            print('Tapped on add member');
          },
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
        SizedBox(
          width: 30,
          child: Text(
            " ${localization.member(members.length)}",
            style: textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: true,
          ),
        ),
      ],
    ),
  );
}
