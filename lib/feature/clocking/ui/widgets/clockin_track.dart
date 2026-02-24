import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/feature/clocking/domain/entities/user_clock_info.dart';
import 'package:note_sondage/feature/clocking/ui/mobile/widgets/table_component_mobile.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/table_component.dart';

class ClockInTrack extends StatelessWidget {
  final bool isMobile;
  const ClockInTrack({
    super.key,
    required this.title,
    required this.isTeamWithUsers,
    this.isMobile = false,
  });
  final String title;
  final bool isTeamWithUsers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: textTheme.titleMedium),
        SizedBox(height: 2.0),
        Padding(
          padding: EdgeInsets.all(8.0),

          child: isTeamWithUsers
              ? userByTeam(isMobile, listUserClockInfo, listheaderTable)
              : onlyAllUser(isMobile, listUserClockInfo, listheaderTable),
        ),
      ],
    );
  }
}

Widget onlyAllUser(
  bool isMobile,
  List<UserClockInfo> dataTable,
  List<String> headerTable,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text("All users", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      SizedBox(
        height:
            dataTable.length *
            58.0, // Adjust the height based on the number of rows
        width: double.infinity,
        child: isMobile
            ? TableComponentMobile(
                dataTable: dataTable,
                headerTable: headerTable,
              )
            : TableComponent(dataTable: dataTable, headerTable: headerTable),
      ),
    ],
  );
}

Widget userByTeam(
  bool isMobile,
  List<UserClockInfo> dataTable,
  List<String> headerTable,
) {
  List<List<UserClockInfo>> teamsData = [];

  final teams = dataTable
      .map((userClockInfo) => userClockInfo.teamName)
      .toSet()
      .toList(); // Get unique team names

  for (var teamName in teams) {
    final teamData = dataTable
        .where((userClockInfo) => userClockInfo.teamName == teamName)
        .toList();
    teamsData.add(teamData);
  }

  return Column(
    children: [
      ...teamsData.map((teamData) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Text(
                teamData.first.teamName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: teamData.length == 1
                  ? 128.0
                  : teamData.length > 2
                  ? teamData.length * 68.0
                  : teamData.length *
                        86.0, // Adjust height based on number of users in the team
              width: double.infinity,
              child: isMobile
                  ? TableComponentMobile(
                      dataTable: teamData,
                      headerTable: headerTable,
                    )
                  : TableComponent(
                      dataTable: teamData,
                      headerTable: headerTable,
                    ),
            ),
          ],
        );
      }).toList(),
    ],
  );
}

final List<String> listheaderTable = [
  "User",
  "Clock in",
  "Clock out",
  "Time worked",
  "Team",
];

final List<UserClockInfo> listUserClockInfo = [
  UserClockInfo(
    clockInTime: "09:00 AM",
    clockOutTime: "05:00 PM",
    teamName: "Developper",
    user: "User 1",
    timeWorked: "8 hours",
  ),
  UserClockInfo(
    clockInTime: "09:12 AM",
    clockOutTime: "05:00 PM",
    teamName: "Developper",
    user: "User 2",
    timeWorked: "8 hours",
  ),
  UserClockInfo(
    clockInTime: "09:12 AM",
    clockOutTime: "05:00 PM",
    teamName: "Manager",
    user: "User 3",
    timeWorked: "8 hours",
  ),
  UserClockInfo(
    clockInTime: "09:12 AM",
    clockOutTime: "05:00 PM",
    teamName: "Commercial",
    user: "User 4",
    timeWorked: "8 hours",
  ),
  UserClockInfo(
    clockInTime: "09:12 AM",
    clockOutTime: "05:00 PM",
    teamName: "Developper",
    user: "User 5",
    timeWorked: "8 hours",
  ),
  UserClockInfo(
    clockInTime: "09:12 AM",
    clockOutTime: "05:00 PM",
    teamName: "Manager",
    user: "User 6",
    timeWorked: "8 hours",
  ),
  UserClockInfo(
    user: "User 7",
    clockInTime: "09:12 AM",
    clockOutTime: "05:00 PM",
    timeWorked: "8 hours",
    teamName: "Developper",
  ),
  UserClockInfo(
    user: "User 8",
    clockInTime: "09:12 AM",
    clockOutTime: "05:00 PM",
    timeWorked: "8 hours",
    teamName: "Manager",
  ),

  UserClockInfo(
    user: "User 9",
    clockInTime: "09:12 AM",
    clockOutTime: "05:00 PM",
    timeWorked: "8 hours",
    teamName: "Mobile",
  ),
  UserClockInfo(
    user: "User 10",
    clockInTime: "09:12 AM",
    clockOutTime: "05:00 PM",
    timeWorked: "8 hours",
    teamName: "Mobile",
  ),
];
