import 'package:flutter/material.dart';
import 'package:note_sondage/ui/widgets/avatar_app.dart';

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
    children: members.map((member) {
      final name = (member['name'] ?? '') as String;
      final imageUrl = (member['imageUrl'] ?? member['avatarUrl'])?.toString();
      final initials = name.isNotEmpty
          ? name
                .split(' ')
                .where((part) => part.isNotEmpty)
                .map((part) => part[0].toUpperCase())
                .take(2)
                .join()
          : '?';

      return Row(
        children: [
          AvatarApp(
            imageUrl: imageUrl,
            initials: initials,
            size: 40,
            backgroundColor: Colors.grey,
            textColor: Colors.white,
          ),
          SizedBox(width: 8),
          Text(name),
        ],
      );
    }).toList(),
  );
}
