import 'package:flutter/material.dart';

class TeamCard extends StatelessWidget {
  const TeamCard(
    this.members, {
    super.key,
    required this.teamName,
    required this.focusTeam,
  });
  final String teamName;
  final String focusTeam;
  final List<Map<String, dynamic>>? members;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: []),
          Text(teamName),
          iconTest(Icons.center_focus_strong, focusTeam),
          listTeamMembers(members!),
        ],
      ),
    );
  }
}

Widget iconTest(IconData iconData, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,

    children: [Icon(iconData), SizedBox(width: 8), Text(label)],
  );
}

Widget listTeamMembers(List<Map<String, dynamic>> members) {
  return Column(
    children: members
        .map(
          (member) => Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(member['avatarUrl']!)),
              SizedBox(width: 8),
              Text(member['name']!),
            ],
          ),
        )
        .toList(),
  );
}
