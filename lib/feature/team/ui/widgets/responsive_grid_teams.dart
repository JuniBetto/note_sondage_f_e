import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/utils/extention_color.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_component_card.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_component_row.dart';
import 'package:note_sondage/ui/widgets/archive_view_toggle.dart';

class ResponsiveGridTeams extends StatefulWidget {
  const ResponsiveGridTeams({
    super.key,
    required this.items,
    required this.isRow,
    this.isSelectionMode = false,
    this.shrinkWrapLayout = false,
    this.onTeamSelected,
  });
  final List<Map<String, dynamic>> items;
  final bool isRow;
  final bool isSelectionMode;
  final bool shrinkWrapLayout;
  final void Function(Map<String, dynamic> selectedTeam)? onTeamSelected;

  @override
  State<ResponsiveGridTeams> createState() => _ResponsiveGridTeamsState();
}

class _ResponsiveGridTeamsState extends State<ResponsiveGridTeams> {
  late final TeamBloc _teamBloc;
  late final UserArchiveService _archiveService;
  List<TeamEntityForView> teamsWithMembers = [];
  bool _syncedFromCurrentState = false;
  bool _showArchivedOnly = false;
  Set<String> _archivedTeamIds = <String>{};

  String get _currentUserId => getIt<AuthBloc>().state.user.uid;

  @override
  void initState() {
    super.initState();
    _teamBloc = getIt<TeamBloc>();
    _archiveService = getIt<UserArchiveService>();
    final teamState = _teamBloc.state;
    if (teamState is! TeamsLoaded && teamState is! TeamLoading) {
      _teamBloc.add(LoadTeamsEvent());
    }
    _loadArchivedTeams();
  }

  Future<void> _loadArchivedTeams() async {
    final archived = await _archiveService.loadArchivedIds(
      userId: _currentUserId,
      bucket: ArchiveBuckets.teams,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _archivedTeamIds = archived;
    });
  }

  Future<void> _toggleArchive(String teamId) async {
    await _archiveService.toggleArchived(
      userId: _currentUserId,
      bucket: ArchiveBuckets.teams,
      itemId: teamId,
    );
    await _loadArchivedTeams();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthBloc>().state.user;
    final currentUserEmail = authUser.email.trim();
    final currentUserPhotoUrl = authUser.photoUrl?.trim();

    return BlocConsumer<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listener: (context, state) {
        if (state is TeamError) {
          AppSnackBar.showError(context, state.message);
        }

        if (state is TeamsLoaded) {
          setState(() {
            teamsWithMembers = state.teams
                .map((team) => TeamEntityForView(team: team, members: const []))
                .toList();
          });
        }
      },
      builder: (context, teamState) {
        if (teamState is TeamsLoaded &&
            teamsWithMembers.isEmpty &&
            !_syncedFromCurrentState) {
          _syncedFromCurrentState = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              teamsWithMembers = teamState.teams
                  .map(
                    (team) => TeamEntityForView(team: team, members: const []),
                  )
                  .toList();
            });
          });
        }

        if (teamState is TeamLoading && teamsWithMembers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

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

        final items = teamsWithMembers.map((teamView) {
          return {
            "teamName": teamView.team.name,
            "teamFocus": teamView.team.description,
            "teamId": teamView.team.id ?? '',
            "ownerUserId": teamView.team.createdByUserId,
            "memberCount": teamView.team.memberCount,
            "isSyncing": _teamBloc.syncingTeamIds.contains(
              teamView.team.id ?? '',
            ),
            "members": teamView.members
                .map(
                  (m) => {
                    "email": m.teamMember.userEmail,
                    "userId": m.teamMember.userId,
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

        final foregroundItems = items
            .where(
              (item) =>
                  !_archivedTeamIds.contains((item['teamId'] ?? '') as String),
            )
            .toList();
        final archivedItems = items
            .where(
              (item) =>
                  _archivedTeamIds.contains((item['teamId'] ?? '') as String),
            )
            .toList();
        final displayedItems = _showArchivedOnly
            ? archivedItems
            : foregroundItems;

        if (items.isEmpty) {
          return const Center(
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

        final content = displayedItems.isEmpty
            ? Center(
                child: Text(
                  _showArchivedOnly
                      ? 'Nessun team archiviato.'
                      : 'Nessun team in primo piano.',
                ),
              )
            : viewScrollWebMobile(
                context,
                _teamBloc,
                displayedItems,
                widget.isRow,
                widget.isSelectionMode,
                widget.onTeamSelected,
                currentUserId: _currentUserId,
                currentUserEmail: currentUserEmail,
                currentUserPhotoUrl: currentUserPhotoUrl,
                archivedTeamIds: _archivedTeamIds,
                onArchiveToggle: _toggleArchive,
                wrapInScrollView: !widget.isSelectionMode,
              );

        if (widget.isSelectionMode) {
          return content;
        }

        if (widget.shrinkWrapLayout) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ArchiveViewToggle(
                    showArchivedOnly: _showArchivedOnly,
                    primaryCount: foregroundItems.length,
                    archivedCount: archivedItems.length,
                    onChanged: (value) {
                      setState(() => _showArchivedOnly = value);
                    },
                  ),
                ),
              ),
              content,
            ],
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ArchiveViewToggle(
                  showArchivedOnly: _showArchivedOnly,
                  primaryCount: foregroundItems.length,
                  archivedCount: archivedItems.length,
                  onChanged: (value) {
                    setState(() => _showArchivedOnly = value);
                  },
                ),
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

Widget viewScrollWebMobile(
  BuildContext context,
  TeamBloc teamBloc,
  List<Map<String, dynamic>> items,
  bool isRow,
  bool isSelectionMode,
  void Function(Map<String, dynamic> selectedTeam)? onTeamSelected, {
  bool wrapInScrollView = true,
  String currentUserId = '',
  String currentUserEmail = '',
  String? currentUserPhotoUrl,
  Set<String> archivedTeamIds = const <String>{},
  required ValueChanged<String> onArchiveToggle,
}) {
  final content = Wrap(
    alignment: WrapAlignment.spaceAround,
    runSpacing: 4.0,
    spacing: 4.0,
    children: items.asMap().entries.map((entry) {
      final item = entry.value;
      final teamId = item["teamId"] as String;
      final ownerUserId = (item["ownerUserId"] as String?) ?? '';
      final isOwner = currentUserId.isNotEmpty && currentUserId == ownerUserId;
      final isArchived = archivedTeamIds.contains(teamId);

      return isRow
          ? TeamComponentCard(
              key: ValueKey('team_card_$teamId'),
              isActive: false,
              teamName: item["teamName"],
              teamFocus: item["teamFocus"],
              teamId: teamId,
              members: item["members"],
              memberCount: item["memberCount"] as int?,
              isSyncing: item["isSyncing"] as bool? ?? false,
              isOwner: isOwner,
              isArchived: isArchived,
              currentUserId: currentUserId,
              currentUserEmail: currentUserEmail,
              currentUserPhotoUrl: currentUserPhotoUrl,
              onTap: isSelectionMode
                  ? () => onTeamSelected?.call(item)
                  : () => context.go(RouterPaths.teamDetail, extra: teamId),
              colorTeam: item["color"],
              onArchiveTap: isSelectionMode
                  ? null
                  : () => onArchiveToggle(teamId),
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
              memberCount: item["memberCount"] as int?,
              isSyncing: item["isSyncing"] as bool? ?? false,
              isOwner: isOwner,
              isArchived: isArchived,
              currentUserId: currentUserId,
              currentUserEmail: currentUserEmail,
              currentUserPhotoUrl: currentUserPhotoUrl,
              onTap: isSelectionMode
                  ? () => onTeamSelected?.call(item)
                  : () => context.go(RouterPaths.teamDetail, extra: teamId),
              colorTeam: item["color"],
              teamId: teamId,
              onArchiveTap: isSelectionMode
                  ? null
                  : () => onArchiveToggle(teamId),
              onDeleteTap: isSelectionMode
                  ? null
                  : (teamId) {
                      teamBloc.add(DeleteTeamEvent(teamId));
                    },
            );
    }).toList(),
  );

  return Padding(
    padding: const EdgeInsets.all(0.0),
    child: wrapInScrollView
        ? SingleChildScrollView(scrollDirection: Axis.vertical, child: content)
        : content,
  );
}
