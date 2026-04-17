import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/team_card.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});
  final List<Map<String, dynamic>> teamMembers = const [
    {
      'name': 'Alice Johnson',
      'avatarUrl': 'https://example.com/alice.jpg',
      'focusTeam': 'Team C',
    },
    {
      'name': 'Bob Smith',
      'avatarUrl': 'https://example.com/bob.jpg',
      'focusTeam': 'Team A',
    },
    {
      'name': 'Charlie Brown',
      'avatarUrl': 'https://example.com/charlie.jpg',
      'focusTeam': 'Team B',
    },
  ];

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Visibility(
              visible: !kIsWeb,
              child: Text('This is the Team page for Mobile'),
            ),
            headerTeamPage(context, () {}, () {}, () {}),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: ColoredBox(
                  color: Colors.grey[200]!,
                  child: widget.teamMembers.isEmpty
                      ? Center(child: Text('No team members found.'))
                      : TeamCard(
                          widget.teamMembers,
                          teamName: 'name',
                          focusTeam: 'focusTeam',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget headerTeamPage(
  BuildContext context,
  void Function()? onPressedToList,
  void Function()? onPressedToCard,
  void Function()? onPressedToAdd,
) {
  final localization = AppLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;

  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.max,
    children: [
      IconButton.outlined(
        onPressed: onPressedToCard,
        icon: Icon(Icons.window_sharp),
      ),
      IconButton.outlined(onPressed: onPressedToList, icon: Icon(Icons.list)),
      const SizedBox(width: 8),
      // ── Beautiful "Create Team" button ──
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressedToAdd,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.secondary,
                  colorScheme.secondary.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.group_add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  localization.createNewTeam,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
