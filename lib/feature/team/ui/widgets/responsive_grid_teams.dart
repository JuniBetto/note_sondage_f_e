import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/utils/extention_color.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_component_card.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_component_row.dart';
import 'package:note_sondage/ui/widgets/archive_view_toggle.dart';

class ResponsiveGridTeams extends StatefulWidget {
  const ResponsiveGridTeams({
    super.key,
    required this.items,
    required this.isRow,
    this.searchQuery = '',
    this.isSelectionMode = false,
    this.shrinkWrapLayout = false,
    this.onTeamSelected,
  });
  final List<Map<String, dynamic>> items;
  final bool isRow;
  final String searchQuery;
  final bool isSelectionMode;
  final bool shrinkWrapLayout;
  final void Function(Map<String, dynamic> selectedTeam)? onTeamSelected;

  @override
  State<ResponsiveGridTeams> createState() => _ResponsiveGridTeamsState();
}

class _ResponsiveGridTeamsState extends State<ResponsiveGridTeams> {
  late final TeamBloc _teamBloc;
  late final TeamMemberUseCase _teamMemberUseCase;
  late final RoleUseCase _roleUseCase;
  late final UserArchiveService _archiveService;
  List<TeamEntityForView> teamsWithMembers = [];
  final Map<String, List<RoleEntity>> _rolesByTeamId =
      <String, List<RoleEntity>>{};
  bool _syncedFromCurrentState = false;
  bool _showArchivedOnly = false;
  Set<String> _archivedTeamIds = <String>{};
  int _membersRefreshGeneration = 0;

  String get _currentUserId => getIt<AuthBloc>().state.user.uid;

  @override
  void initState() {
    super.initState();
    _teamBloc = getIt<TeamBloc>();
    _teamMemberUseCase = getIt<TeamMemberUseCase>();
    _roleUseCase = getIt<RoleUseCase>();
    _archiveService = getIt<UserArchiveService>();
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
    final localization = AppLocalizations.of(context)!;
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
            teamsWithMembers = _mergeWithExistingMembers(state.teams);
          });
          unawaited(_refreshMembersForTeams(state.teams));
          unawaited(_refreshRolesForTeams(state.teams));
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
              teamsWithMembers = _mergeWithExistingMembers(teamState.teams);
            });
            unawaited(_refreshMembersForTeams(teamState.teams));
            unawaited(_refreshRolesForTeams(teamState.teams));
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
                Text('${localization.errorPrefix} ${teamState.message}'),
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
            "roles":
                _rolesByTeamId[teamView.team.id ?? ''] ?? const <RoleEntity>[],
            "color": teamView.team.color?.toColor() ?? Colors.blue,
          };
        }).toList();

        final normalizedSearch = widget.searchQuery.trim().toLowerCase();
        final filteredItems = normalizedSearch.isEmpty
            ? items
            : items.where((item) {
                final teamName = (item['teamName'] ?? '').toString();
                final teamFocus = (item['teamFocus'] ?? '').toString();
                final members = (item['members'] as List<dynamic>? ?? const [])
                    .cast<Map<String, dynamic>>();
                final memberText = members
                    .map(
                      (member) =>
                          '${member['name'] ?? ''} ${member['email'] ?? ''}',
                    )
                    .join(' ');
                final searchable = '$teamName $teamFocus $memberText'
                    .toLowerCase();
                return searchable.contains(normalizedSearch);
              }).toList();

        final foregroundItems = filteredItems
            .where(
              (item) =>
                  !_archivedTeamIds.contains((item['teamId'] ?? '') as String),
            )
            .toList();
        final archivedItems = filteredItems
            .where(
              (item) =>
                  _archivedTeamIds.contains((item['teamId'] ?? '') as String),
            )
            .toList();
        final displayedItems = _showArchivedOnly
            ? archivedItems
            : foregroundItems;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  localization.noTeamsFound,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        final content = displayedItems.isEmpty
            ? Center(
                child: Text(
                  normalizedSearch.isNotEmpty
                      ? localization.noTeamsMatchingSearch
                      : _showArchivedOnly
                      ? localization.noArchivedTeams
                      : localization.noVisibleTeams,
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

  List<TeamEntityForView> _mergeWithExistingMembers(List<TeamEntity> teams) {
    final existingById = {
      for (final teamView in teamsWithMembers)
        if ((teamView.team.id ?? '').isNotEmpty) teamView.team.id!: teamView,
    };

    return teams.map((team) {
      final existing = existingById[team.id ?? ''];
      return TeamEntityForView(team: team, members: existing?.members ?? []);
    }).toList();
  }

  Future<void> _refreshMembersForTeams(List<TeamEntity> teams) async {
    final generation = ++_membersRefreshGeneration;
    final teamIds = teams
        .map((team) => team.id ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    if (teamIds.isEmpty) {
      return;
    }

    final membersByTeamId = <String, List<TeamMemberforView>>{};
    await Future.wait(
      teamIds.map((teamId) async {
        try {
          final members = await _teamMemberUseCase.getAllMembersByTeamId(
            teamId,
          );
          membersByTeamId[teamId] = members
              .map((member) => TeamMemberforView(teamMember: member))
              .toList();
        } catch (_) {
          // Preserve the last successfully rendered data if this refresh fails.
        }
      }),
    );

    if (!mounted || generation != _membersRefreshGeneration) {
      return;
    }

    if (membersByTeamId.isEmpty) {
      return;
    }

    setState(() {
      teamsWithMembers = teamsWithMembers.map((teamView) {
        final teamId = teamView.team.id ?? '';
        final refreshedMembers = membersByTeamId[teamId];
        if (refreshedMembers == null) {
          return teamView;
        }

        return TeamEntityForView(
          team: _teamWithMemberCount(teamView.team, refreshedMembers.length),
          members: refreshedMembers,
        );
      }).toList();
    });
  }

  Future<void> _refreshRolesForTeams(List<TeamEntity> teams) async {
    final teamIds = teams
        .map((team) => team.id ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    if (teamIds.isEmpty) {
      return;
    }

    final rolesByTeamId = <String, List<RoleEntity>>{};
    await Future.wait(
      teamIds.map((teamId) async {
        try {
          final roles = await _roleUseCase.getAllRolesByTeamId(teamId);
          rolesByTeamId[teamId] = roles
              .where(
                (role) =>
                    _normalizeRoleCode(role.id) != 'VIEWER' &&
                    _normalizeRoleCode(role.name) != 'VIEWER',
              )
              .toList(growable: false);
        } catch (_) {
          // Preserve last successfully rendered roles if refresh fails.
        }
      }),
    );

    if (!mounted || rolesByTeamId.isEmpty) {
      return;
    }

    setState(() {
      _rolesByTeamId.addAll(rolesByTeamId);
    });
  }

  TeamEntity _teamWithMemberCount(TeamEntity team, int memberCount) {
    return TeamEntity(
      team.id,
      team.color,
      team.pendingInvitations,
      name: team.name,
      description: team.description,
      createdByUserId: team.createdByUserId,
      memberCount: memberCount,
      createdAt: team.createdAt,
    );
  }
}

String _normalizeRoleCode(String? roleCode) {
  final normalized = (roleCode ?? '').trim().toUpperCase();
  if (normalized.isEmpty) {
    return 'MEMBER';
  }
  return normalized == 'VIEWER' ? 'MEMBER' : normalized;
}

bool _canManageTeamFromItem(
  Map<String, dynamic> item, {
  required String currentUserId,
  required String currentUserEmail,
}) {
  final ownerUserId = (item['ownerUserId'] as String?) ?? '';
  if (currentUserId.isNotEmpty && currentUserId == ownerUserId) {
    return true;
  }

  final members = (item['members'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  final currentMember =
      members
          .where(
            (member) =>
                ((member['userId'] ?? '') as String).trim().isNotEmpty &&
                ((member['userId'] ?? '') as String).trim() == currentUserId,
          )
          .firstOrNull ??
      members
          .where(
            (member) =>
                ((member['email'] ?? '') as String).trim().toLowerCase() ==
                currentUserEmail.trim().toLowerCase(),
          )
          .firstOrNull;

  final roleCode = _normalizeRoleCode(currentMember?['role']?.toString());
  final roles = (item['roles'] as List<dynamic>? ?? const [])
      .whereType<RoleEntity>()
      .toList(growable: false);
  final role = roles
      .where((item) => _normalizeRoleCode(item.id) == roleCode)
      .firstOrNull;
  final permissions = (role?.permissions ?? const <String>[])
      .map((permission) => permission.trim().toUpperCase())
      .where((permission) => permission.isNotEmpty)
      .toSet();

  if (permissions.isEmpty) {
    return roleCode == 'ADMIN';
  }

  return permissions.contains('ADMIN') || permissions.contains('MANAGE');
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
      final canManageTeam = _canManageTeamFromItem(
        item,
        currentUserId: currentUserId,
        currentUserEmail: currentUserEmail,
      );
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
              canManageTeam: canManageTeam,
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
              canManageTeam: canManageTeam,
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
