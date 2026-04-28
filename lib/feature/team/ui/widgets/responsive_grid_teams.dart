import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/utils/extention_color.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_component_card.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_component_row.dart';

class ResponsiveGridTeams extends StatefulWidget {
  const ResponsiveGridTeams({
    super.key,
    required this.items,
    required this.isRow,
    this.isSelectionMode = false,
    this.onTeamSelected,
  });
  final List<Map<String, dynamic>> items;
  final bool isRow;
  final bool isSelectionMode;
  final void Function(Map<String, dynamic> selectedTeam)? onTeamSelected;

  @override
  State<ResponsiveGridTeams> createState() => _ResponsiveGridTeamsState();
}

class _ResponsiveGridTeamsState extends State<ResponsiveGridTeams> {
  late final TeamBloc _teamBloc;
  late final TeamMemberBloc _teamMemberBloc;
  List<TeamEntityForView> teamsWithMembers = [];
  Map<String, List<TeamMemberforView>> teamMembersMap = {};
  bool _syncedFromCurrentState = false;

  @override
  void initState() {
    super.initState();
    _teamBloc = getIt<TeamBloc>();
    _teamMemberBloc = getIt<TeamMemberBloc>();
    _teamBloc.add(LoadTeamsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listener: (context, state) {
        if (state is TeamsLoaded) {
          debugPrint("✅ TeamsLoaded: ${state.teams.length} teams");
          final newTeams = state.teams
              .map((team) => TeamEntityForView(team: team, members: []))
              .toList();

          // Preserve already-loaded members when teams update
          final updatedTeams = newTeams.map((newTeam) {
            final existing = teamsWithMembers
                .where((t) => t.team.id == newTeam.team.id)
                .firstOrNull;
            if (existing != null && existing.members.isNotEmpty) {
              return newTeam.copyWith(members: existing.members)
                  as TeamEntityForView;
            }
            return newTeam;
          }).toList();

          setState(() {
            teamsWithMembers = updatedTeams;
          });

          // Load members only for teams that don't have members yet
          for (var team in state.teams) {
            final createdTeamId = team.id;
            if (createdTeamId != null &&
                !teamMembersMap.containsKey(createdTeamId)) {
              _teamMemberBloc.add(LoadTeamMembersByTeamIdEvent(createdTeamId));
            }
          }
        }
        if (state is TeamError) {
          debugPrint("❌ TeamError: ${state.message}");
        }
      },
      builder: (context, teamState) {
        // If bloc already has teams loaded (singleton reuse), sync local state
        if (teamState is TeamsLoaded &&
            teamsWithMembers.isEmpty &&
            !_syncedFromCurrentState) {
          _syncedFromCurrentState = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              teamsWithMembers = teamState.teams
                  .map((team) => TeamEntityForView(team: team, members: []))
                  .toList();
            });
            for (var team in teamState.teams) {
              final id = team.id;
              if (id != null) {
                _teamMemberBloc.add(LoadTeamMembersByTeamIdEvent(id));
              }
            }
          });
        }

        // Show loading only on initial load (no teams yet)
        if (teamState is TeamLoading && teamsWithMembers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error only if we have no cached data
        if (teamState is TeamError && teamsWithMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${teamState.message}'),
              ],
            ),
          );
        }

        return BlocConsumer<TeamMemberBloc, TeamMemberState>(
          bloc: _teamMemberBloc,
          listener: (context, memberState) {
            if (memberState is TeamMembersLoaded) {
              debugPrint("Loaded team members: ${memberState.members}");

              // Group members by team_id
              if (memberState.members.isNotEmpty) {
                final teamId = memberState.members.first.teamId;
                setState(() {
                  teamMembersMap[teamId] = memberState.members
                      .map(
                        (member) =>
                            TeamMemberforView(teamMember: member, user: null),
                      )
                      .toList();

                  // Update the corresponding team with its members
                  teamsWithMembers = teamsWithMembers.map((teamView) {
                    if (teamView.team.id == teamId) {
                      return teamView.copyWith(members: teamMembersMap[teamId])
                          as TeamEntityForView;
                    }
                    return teamView;
                  }).toList();
                });
              }
            }

            if (memberState is TeamMemberError) {
              debugPrint("Error loading team members: ${memberState.message}");
            }
          },
          builder: (context, memberState) {
            // If no teams loaded yet, show empty state
            if (teamsWithMembers.isEmpty) {
              debugPrint(
                "⚠️ ResponsiveGridTeams: No teams loaded, showing empty state",
              );
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No teams found', style: TextStyle(fontSize: 18)),
                  ],
                ),
              );
            }

            debugPrint(
              "✅ ResponsiveGridTeams: Building with ${teamsWithMembers.length} teams",
            );

            // Convert teamsWithMembers to the format expected by viewScrollWebMobile
            final currentUserId = getIt<AuthBloc>().state.user.uid;
            final items = teamsWithMembers.map((teamView) {
              return {
                "teamName": teamView.team.name,
                "teamFocus": teamView.team.description,
                "teamId": teamView.team.id ?? '',
                "ownerUserId": teamView.team.createdByUserId,
                "members": teamView.members
                    .map(
                      (m) => {
                        "email": m.teamMember.userEmail,
                        "role": m.teamMember.roleId,
                        "status": m.teamMember.status.toString(),
                        "imageUrl": m.teamMember.imageUrl,
                        "name":
                            m.teamMember.initialName ??
                            m.teamMember.userEmail.split('@').first,
                      },
                    )
                    .toList(),
                "color": teamView.team.color?.toColor() ?? Colors.blue,
              };
            }).toList();

            debugPrint(
              "📦 ResponsiveGridTeams: Converted ${items.length} items for display",
            );
            debugPrint("📱 ResponsiveGridTeams: isRow = ${widget.isRow}");

            return viewScrollWebMobile(
              _teamBloc,
              items,
              widget.isRow,
              widget.isSelectionMode,
              widget.onTeamSelected,
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }
}

Widget viewScrollWebMobile(
  TeamBloc teamBloc,
  List<Map<String, dynamic>> items,
  bool isRow,
  bool isSelectionMode,
  void Function(Map<String, dynamic> selectedTeam)? onTeamSelected, {
  String currentUserId = '',
}) {
  return Padding(
    padding: const EdgeInsets.all(0.0),
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runSpacing: 4.0,
        spacing: 4.0,
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final teamId = item["teamId"] as String;
          final ownerUserId = (item["ownerUserId"] as String?) ?? '';
          final isOwner = currentUserId.isNotEmpty && currentUserId == ownerUserId;

          return isRow
              ? TeamComponentCard(
                  key: ValueKey('team_card_$teamId'),
                  isActive: false,
                  teamName: item["teamName"],
                  teamFocus: item["teamFocus"],
                  teamId: teamId,
                  members: item["members"],
                  isOwner: isOwner,
                  onTap: isSelectionMode
                      ? () => onTeamSelected?.call(item)
                      : () {},
                  colorTeam: item["color"],
                  onDeleteTap: isSelectionMode
                      ? null
                      : (teamId) {
                          teamBloc.add(DeleteTeamEvent(teamId));
                        },
                )
              : TeamComponentRow(
                  key: ValueKey('team_row_$teamId'),
                  isActive: false,
                  teamName: item["teamName"],
                  teamFocus: item["teamFocus"],
                  members: item["members"],
                  isOwner: isOwner,
                  onTap: isSelectionMode
                      ? () => onTeamSelected?.call(item)
                      : () {},
                  colorTeam: item["color"],
                  teamId: teamId,
                  onDeleteTap: isSelectionMode
                      ? null
                      : (teamId) {
                          teamBloc.add(DeleteTeamEvent(teamId));
                        },
                );
        }).toList(),
      ),
    ),
  );
}
