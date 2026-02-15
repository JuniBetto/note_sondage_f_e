import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
            headerTeamPage(() {}, () {}, () {}),
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
  void Function()? onPressedToList,
  void Function()? onPressedToCard,
  void Function()? onPressedToAdd,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.max,
    children: [
      IconButton.outlined(
        onPressed: onPressedToCard,
        icon: Icon(Icons.window_sharp),
      ),
      IconButton.outlined(onPressed: onPressedToList, icon: Icon(Icons.list)),
      IconButton.outlined(onPressed: onPressedToAdd, icon: Icon(Icons.add)),
    ],
  );
}
