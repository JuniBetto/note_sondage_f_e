import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/notification/realtime/team_realtime_coordinator.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_invitation_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class TeamSectionPermissions {
  const TeamSectionPermissions({
    required this.roleCode,
    required this.canEditTeamBasics,
    required this.canEditTeamColor,
    required this.canManageClockingSettings,
    required this.canInviteMembers,
    required this.canCancelInvitations,
    required this.canRemoveMembers,
    required this.canChangeMemberRoles,
    required this.canManageRoleDefinitions,
    required this.canAccessRoleManager,
  });

  factory TeamSectionPermissions.readOnly() {
    return const TeamSectionPermissions(
      roleCode: 'VIEWER',
      canEditTeamBasics: false,
      canEditTeamColor: false,
      canManageClockingSettings: false,
      canInviteMembers: false,
      canCancelInvitations: false,
      canRemoveMembers: false,
      canChangeMemberRoles: false,
      canManageRoleDefinitions: false,
      canAccessRoleManager: false,
    );
  }

  final String roleCode;
  final bool canEditTeamBasics;
  final bool canEditTeamColor;
  final bool canManageClockingSettings;
  final bool canInviteMembers;
  final bool canCancelInvitations;
  final bool canRemoveMembers;
  final bool canChangeMemberRoles;
  final bool canManageRoleDefinitions;
  final bool canAccessRoleManager;

  bool get isOwner => roleCode == 'OWNER';
  bool get isAdmin => roleCode == 'ADMIN';
  bool get isReadOnly =>
      !canEditTeamBasics &&
      !canInviteMembers &&
      !canRemoveMembers &&
      !canChangeMemberRoles;
}

/// Shared widget used in both mobile and web edit-team pages.
/// Shows active members, pending invitations, and an invite form.
///
/// ⚠️  Creates its OWN private BLoC instances — never uses the singleton —
///     so it is not affected by other widgets firing LoadTeamMembersByTeamIdEvent.
class TeamMembersSection extends StatefulWidget {
  final String teamId;
  final String? ownerUserId;
  final bool forceReadOnly;
  final ValueChanged<TeamSectionPermissions>? onPermissionsChanged;
  const TeamMembersSection({
    super.key,
    required this.teamId,
    this.ownerUserId,
    this.forceReadOnly = false,
    this.onPermissionsChanged,
  });

  @override
  State<TeamMembersSection> createState() => _TeamMembersSectionState();
}

class _TeamMembersSectionState extends State<TeamMembersSection> {
  // ── Private bloc instances (NOT from singleton)
  late final TeamMemberBloc _memberBloc;
  late final TeamMemberBloc
  _inviteBloc; // separate instance for invitations list
  late final RoleBloc _roleBloc;

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _roleCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<RoleEntity> _roles = [];
  List<TeamMemberEntity> _members = [];
  List<TeamInvitationEntity> _invitations = [];
  TeamSectionPermissions _permissions = TeamSectionPermissions.readOnly();

  String? _editingMemberId;
  String? _editingRoleId;
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    // Create fresh instances so they're isolated from the singleton
    _memberBloc = TeamMemberBloc(teamMemberUseCase: getIt<TeamMemberUseCase>());
    _inviteBloc = TeamMemberBloc(teamMemberUseCase: getIt<TeamMemberUseCase>());
    _roleBloc = RoleBloc(roleUseCase: getIt<RoleUseCase>());

    _memberBloc.add(LoadTeamMembersByTeamIdEvent(widget.teamId));
    _inviteBloc.add(LoadTeamInvitationsEvent(widget.teamId));
    _roleBloc.add(LoadRolesEventByTeamId(widget.teamId));
    getIt<TeamRealtimeCoordinator>().activateTeamContext(widget.teamId);
    _realtimeSubscription = getIt<RealtimeNotificationService>().stream.listen(
      _handleRealtimeNotification,
    );
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    getIt<TeamRealtimeCoordinator>().deactivateTeamContext(widget.teamId);
    _memberBloc.close();
    _inviteBloc.close();
    _roleBloc.close();
    _emailCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TeamMembersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerUserId != widget.ownerUserId && _members.isNotEmpty) {
      _updatePermissions(_members);
    }
  }

  void _reload() {
    _memberBloc.add(LoadTeamMembersByTeamIdEvent(widget.teamId));
    _inviteBloc.add(LoadTeamInvitationsEvent(widget.teamId));
  }

  void _handleRealtimeNotification(RealtimeNotification notification) {
    final decision = getIt<TeamRealtimeCoordinator>().resolveScreenDecision(
      notification,
      teamId: widget.teamId,
      currentUserId: getIt<AuthBloc>().state.user.uid,
    );

    if (notification.sourceService == 'team-service' &&
        notification.metadata['teamId'] == widget.teamId &&
        (notification.eventType == 'TEAM_ROLE_CREATED' ||
            notification.eventType == 'TEAM_ROLE_UPDATED' ||
            notification.eventType == 'TEAM_ROLE_DELETED')) {
      _roleBloc.add(LoadRolesEventByTeamId(widget.teamId));
    }

    if (decision.needsReload) {
      _reload();
    }
  }

  void _invite() {
    if (_formKey.currentState?.validate() ?? false) {
      _memberBloc.add(
        InviteTeamMemberEvent(
          teamId: widget.teamId,
          email: _emailCtrl.text.trim(),
          roleId: _roleCtrl.text.trim(),
        ),
      );
      _emailCtrl.clear();
      _roleCtrl.clear();
      _formKey.currentState?.reset();
    }
  }

  List<RoleEntity> get _assignableRoles =>
      _roles.where((role) => !_isOwnerRole(role.id)).toList();

  bool _isOwnerRole(String? roleCode) =>
      (roleCode ?? '').trim().toUpperCase() == 'OWNER';

  void _deleteMember(String memberId) {
    _memberBloc.add(
      DeleteTeamMemberEvent(
        '${widget.teamId}/$memberId',
        teamId: widget.teamId,
      ),
    );
  }

  void _updatePermissions(List<TeamMemberEntity> members) {
    if (widget.forceReadOnly) {
      const readOnlyPermissions = TeamSectionPermissions(
        roleCode: 'VIEWER',
        canEditTeamBasics: false,
        canEditTeamColor: false,
        canManageClockingSettings: false,
        canInviteMembers: false,
        canCancelInvitations: false,
        canRemoveMembers: false,
        canChangeMemberRoles: false,
        canManageRoleDefinitions: false,
        canAccessRoleManager: false,
      );
      if (!_hasSamePermissions(_permissions, readOnlyPermissions)) {
        _permissions = readOnlyPermissions;
        widget.onPermissionsChanged?.call(readOnlyPermissions);
      }
      return;
    }

    final currentUserId = getIt<AuthBloc>().state.user.uid.trim();
    if (widget.ownerUserId != null &&
        widget.ownerUserId!.trim().isNotEmpty &&
        widget.ownerUserId!.trim() == currentUserId) {
      const ownerPermissions = TeamSectionPermissions(
        roleCode: 'OWNER',
        canEditTeamBasics: true,
        canEditTeamColor: true,
        canManageClockingSettings: true,
        canInviteMembers: true,
        canCancelInvitations: true,
        canRemoveMembers: true,
        canChangeMemberRoles: true,
        canManageRoleDefinitions: true,
        canAccessRoleManager: true,
      );
      if (!_hasSamePermissions(_permissions, ownerPermissions)) {
        _permissions = ownerPermissions;
        widget.onPermissionsChanged?.call(ownerPermissions);
      }
      return;
    }

    final currentEmail = getIt<AuthBloc>().state.user.email
        .trim()
        .toLowerCase();
    final currentMember =
        members
            .where(
              (member) =>
                  (member.userId?.trim().isNotEmpty ?? false) &&
                  member.userId!.trim() == currentUserId,
            )
            .firstOrNull ??
        members
            .where(
              (member) => member.userEmail.trim().toLowerCase() == currentEmail,
            )
            .firstOrNull;
    final roleCode = (currentMember?.roleId ?? 'VIEWER').trim().toUpperCase();
    final role = _roles.where((item) => item.id == roleCode).firstOrNull;
    final normalizedPermissions = _normalizePermissions(
      roleCode,
      role?.permissions,
    );
    final isOwner = roleCode == 'OWNER';
    final isAdmin = roleCode == 'ADMIN';
    final hasAdminPermission = normalizedPermissions.contains('ADMIN');
    final hasManagePermission = normalizedPermissions.contains('MANAGE');
    final nextPermissions = TeamSectionPermissions(
      roleCode: roleCode,
      canEditTeamBasics:
          isOwner ||
          normalizedPermissions.contains('UPDATE') ||
          hasAdminPermission,
      canEditTeamColor: isOwner,
      canManageClockingSettings: isOwner,
      canInviteMembers: isOwner || hasAdminPermission,
      canCancelInvitations: isOwner || hasAdminPermission,
      canRemoveMembers:
          isOwner ||
          hasAdminPermission ||
          normalizedPermissions.contains('DELETE'),
      canChangeMemberRoles: isOwner || hasManagePermission,
      canManageRoleDefinitions: isOwner,
      canAccessRoleManager:
          isOwner || isAdmin || hasAdminPermission || hasManagePermission,
    );

    if (_hasSamePermissions(_permissions, nextPermissions)) {
      return;
    }

    _permissions = nextPermissions;
    widget.onPermissionsChanged?.call(nextPermissions);
  }

  void _saveRoleEdit(String memberId, TeamMemberEntity original) {
    if (_editingRoleId == null || _editingRoleId!.isEmpty) return;
    final updated = original.copyWith(roleId: _editingRoleId);
    _memberBloc.add(UpdateTeamMemberEvent(updated, teamId: widget.teamId));
    setState(() {
      _editingMemberId = null;
      _editingRoleId = null;
    });
  }

  void _cancelInvitation(String invitationId) {
    _inviteBloc.add(
      CancelTeamInvitationEvent(
        teamId: widget.teamId,
        invitationId: invitationId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TeamMemberBloc, TeamMemberState>(
          bloc: _memberBloc,
          listener: (context, state) {
            if (state is TeamMembersLoaded) {
              setState(() => _members = state.members);
              _updatePermissions(state.members);
            }
            if (state is TeamMemberInvited) {
              _reload();
              AppSnackBar.showSuccess(
                context,
                AppLocalizations.of(context)!.invitationSent,
              );
            }
            if (state is TeamMemberDeleted || state is TeamMemberUpdated) {
              _memberBloc.add(LoadTeamMembersByTeamIdEvent(widget.teamId));
            }
            if (state is TeamMemberError) {
              AppSnackBar.showError(context, state.message);
            }
          },
        ),
        BlocListener<TeamMemberBloc, TeamMemberState>(
          bloc: _inviteBloc,
          listener: (context, state) {
            if (state is TeamInvitationsLoaded) {
              setState(
                () => _invitations = List<TeamInvitationEntity>.from(
                  state.invitations,
                ),
              );
            }
            if (state is TeamInvitationCancelled) {
              _inviteBloc.add(LoadTeamInvitationsEvent(widget.teamId));
            }
            if (state is TeamMemberError) {
              AppSnackBar.showError(context, state.message);
            }
          },
        ),
        BlocListener<RoleBloc, RoleState>(
          bloc: _roleBloc,
          listener: (context, state) {
            if (state is RolesLoaded) {
              setState(() => _roles = state.roles);
              _updatePermissions(_members);
            }
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Active members ────────────────────────────────────────────────
          BlocBuilder<TeamMemberBloc, TeamMemberState>(
            bloc: _memberBloc,
            builder: (context, state) {
              if (state is TeamMemberLoading && _members.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (_members.isEmpty) {
                return _EmptyPlaceholder(
                  icon: Icons.group_outlined,
                  label: AppLocalizations.of(context)!.noActiveMembersYet,
                );
              }
              return _MembersList(
                members: _members,
                roles: _roles,
                permissions: _permissions,
                editingMemberId: _editingMemberId,
                editingRoleId: _editingRoleId,
                onDelete: _deleteMember,
                onEditStart: (m) => setState(() {
                  _editingMemberId = m.id;
                  _editingRoleId = m.roleId;
                }),
                onEditCancel: () => setState(() {
                  _editingMemberId = null;
                  _editingRoleId = null;
                }),
                onEditSave: _saveRoleEdit,
                onRoleChanged: (r) => setState(() => _editingRoleId = r),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Pending invitations ───────────────────────────────────────────
          BlocBuilder<TeamMemberBloc, TeamMemberState>(
            bloc: _inviteBloc,
            builder: (context, state) {
              if (_invitations.isEmpty) return const SizedBox.shrink();
              return _InvitationsSection(
                invitations: _invitations,
                canCancelInvitations: _permissions.canCancelInvitations,
                onCancel: _cancelInvitation,
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── Invite form ───────────────────────────────────────────────────
          if (_permissions.canInviteMembers)
            _InviteForm(
              formKey: _formKey,
              emailController: _emailCtrl,
              roleController: _roleCtrl,
              roles: _assignableRoles,
              onInvite: _invite,
            )
          else
            _EmptyPlaceholder(
              icon: Icons.lock_outline_rounded,
              label:
                  'Inviti e gestione membri non disponibili per il tuo ruolo',
            ),
        ],
      ),
    );
  }

  Set<String> _normalizePermissions(
    String roleCode,
    List<String>? permissions,
  ) {
    if (permissions == null || permissions.isEmpty) {
      return switch (roleCode) {
        'OWNER' => {'READ', 'UPDATE', 'ADMIN', 'DELETE', 'MANAGE'},
        'ADMIN' => {'READ', 'UPDATE', 'ADMIN', 'DELETE'},
        _ => {'READ'},
      };
    }
    return permissions
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  bool _hasSamePermissions(
    TeamSectionPermissions current,
    TeamSectionPermissions next,
  ) {
    return current.roleCode == next.roleCode &&
        current.canEditTeamBasics == next.canEditTeamBasics &&
        current.canEditTeamColor == next.canEditTeamColor &&
        current.canManageClockingSettings == next.canManageClockingSettings &&
        current.canInviteMembers == next.canInviteMembers &&
        current.canCancelInvitations == next.canCancelInvitations &&
        current.canRemoveMembers == next.canRemoveMembers &&
        current.canChangeMemberRoles == next.canChangeMemberRoles &&
        current.canManageRoleDefinitions == next.canManageRoleDefinitions &&
        current.canAccessRoleManager == next.canAccessRoleManager;
  }
}

// ─────────────────────────────────────────────────────────────
// Active members list
// ─────────────────────────────────────────────────────────────
class _MembersList extends StatelessWidget {
  final List<TeamMemberEntity> members;
  final List<RoleEntity> roles;
  final TeamSectionPermissions permissions;
  final String? editingMemberId;
  final String? editingRoleId;
  final void Function(String) onDelete;
  final void Function(TeamMemberEntity) onEditStart;
  final VoidCallback onEditCancel;
  final void Function(String, TeamMemberEntity) onEditSave;
  final void Function(String) onRoleChanged;

  const _MembersList({
    required this.members,
    required this.roles,
    required this.permissions,
    required this.editingMemberId,
    required this.editingRoleId,
    required this.onDelete,
    required this.onEditStart,
    required this.onEditCancel,
    required this.onEditSave,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.tableHeaderUserTeam,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context)!;
              return Row(
                children: [
                  Expanded(flex: 3, child: _HeaderText(loc.email)),
                  Expanded(flex: 2, child: _HeaderText(loc.role)),
                  Expanded(flex: 2, child: _HeaderText(loc.status)),
                  const SizedBox(width: 72),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        ...members.map(
          (m) => _MemberRow(
            member: m,
            roles: roles,
            permissions: permissions,
            isEditing: editingMemberId == m.id,
            editingRoleId: editingRoleId,
            onDelete: () => onDelete(m.id ?? ''),
            onEditStart: () => onEditStart(m),
            onEditCancel: onEditCancel,
            onEditSave: () => onEditSave(m.id ?? '', m),
            onRoleChanged: onRoleChanged,
          ),
        ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.textInvertedColor,
    ),
    overflow: TextOverflow.ellipsis,
  );
}

class _MemberRow extends StatelessWidget {
  final TeamMemberEntity member;
  final List<RoleEntity> roles;
  final TeamSectionPermissions permissions;
  final bool isEditing;
  final String? editingRoleId;
  final VoidCallback onDelete;
  final VoidCallback onEditStart;
  final VoidCallback onEditCancel;
  final VoidCallback onEditSave;
  final void Function(String) onRoleChanged;

  const _MemberRow({
    required this.member,
    required this.roles,
    required this.permissions,
    required this.isEditing,
    required this.editingRoleId,
    required this.onDelete,
    required this.onEditStart,
    required this.onEditCancel,
    required this.onEditSave,
    required this.onRoleChanged,
  });

  List<RoleEntity> get _editableRoles =>
      roles.where((role) => !_isOwnerRole(role.id)).toList();

  bool _isOwnerRole(String? roleCode) =>
      (roleCode ?? '').trim().toUpperCase() == 'OWNER';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleName =
        roles.where((r) => r.id == member.roleId).firstOrNull?.name ??
        member.roleId.toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.tableBodyUserTeam,
        borderRadius: BorderRadius.circular(10),
        border: isEditing
            ? Border.all(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
      ),
      child: isEditing ? _editingRow(context) : _displayRow(context, roleName),
    );
  }

  Widget _displayRow(BuildContext context, String roleName) {
    final colorScheme = Theme.of(context).colorScheme;
    final memberRole = member.roleId.trim().toUpperCase();
    final targetPermissions = _permissionsForRole(memberRole);
    final targetIsProtected =
        memberRole == 'ADMIN' ||
        targetPermissions.contains('ADMIN') ||
        targetPermissions.contains('MANAGE');
    final canEdit =
        permissions.canChangeMemberRoles &&
        member.status == UserStatus.active &&
        memberRole != 'OWNER';
    final canDelete =
        permissions.canRemoveMembers &&
        member.status == UserStatus.active &&
        memberRole != 'OWNER' &&
        (permissions.isOwner || !targetIsProtected);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            member.userEmail.isEmpty ? '—' : member.userEmail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.textInvertedColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            roleName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.textInvertedColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(flex: 2, child: _StatusChip(status: member.status)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit) ...[
              _ActionIcon(
                icon: Icons.edit_rounded,
                color: const Color(0xFF7C4DFF),
                tooltip: AppLocalizations.of(context)!.editRoleTooltip,
                onTap: onEditStart,
              ),
              const SizedBox(width: 4),
            ],
            if (canDelete)
              _ActionIcon(
                icon: Icons.delete_rounded,
                color: colorScheme.deleteCard ?? Colors.red,
                tooltip: AppLocalizations.of(context)!.removeAction,
                onTap: onDelete,
              ),
          ],
        ),
      ],
    );
  }

  Widget _editingRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            member.userEmail.isEmpty ? '—' : member.userEmail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.textInvertedColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 4,
          child: GenericDropdownFormField<RoleEntity>(
            label: '',
            style: Theme.of(context).textTheme.bodySmall,
            isDense: true,
            items: _editableRoles,
            value: _editableRoles
                .where((r) => r.id == (editingRoleId ?? member.roleId))
                .firstOrNull,
            displayText: (r) => r.name,
            valueGetter: (r) => r,
            onChanged: (r) => onRoleChanged(r?.id ?? ''),
            hintText: AppLocalizations.of(context)!.selectRole,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionIcon(
              icon: Icons.check_rounded,
              color: Colors.green,
              tooltip: AppLocalizations.of(context)!.save,
              onTap: onEditSave,
            ),
            const SizedBox(width: 4),
            _ActionIcon(
              icon: Icons.close_rounded,
              color: Colors.grey,
              tooltip: AppLocalizations.of(context)!.cancel,
              onTap: onEditCancel,
            ),
          ],
        ),
      ],
    );
  }

  Set<String> _permissionsForRole(String roleCode) {
    final role = roles.where((item) => item.id == roleCode).firstOrNull;
    final permissionsList = role?.permissions ?? const <String>[];
    if (permissionsList.isEmpty) {
      return switch (roleCode) {
        'OWNER' => {'READ', 'UPDATE', 'ADMIN', 'DELETE', 'MANAGE'},
        'ADMIN' => {'READ', 'UPDATE', 'ADMIN', 'DELETE'},
        _ => {'READ'},
      };
    }
    return permissionsList
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }
}

// ─────────────────────────────────────────────────────────────
// Pending invitations section
// ─────────────────────────────────────────────────────────────
class _InvitationsSection extends StatelessWidget {
  final List<TeamInvitationEntity> invitations;
  final bool canCancelInvitations;
  final void Function(String invitationId) onCancel;

  const _InvitationsSection({
    required this.invitations,
    required this.canCancelInvitations,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.mail_outline_rounded,
                size: 14,
                color: colorScheme.descriptionColor,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.pendingInvitations.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: colorScheme.descriptionColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.tableHeaderUserTeam,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context)!;
              return Row(
                children: [
                  Expanded(flex: 3, child: _HeaderText(loc.email)),
                  Expanded(flex: 2, child: _HeaderText(loc.role)),
                  Expanded(flex: 2, child: _HeaderText(loc.status)),
                  const SizedBox(width: 40),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        ...invitations.map(
          (inv) => _InvitationRow(
            invitation: inv,
            canCancel: canCancelInvitations,
            onCancel: () => onCancel(inv.id),
          ),
        ),
      ],
    );
  }
}

class _InvitationRow extends StatelessWidget {
  final TeamInvitationEntity invitation;
  final bool canCancel;
  final VoidCallback onCancel;

  const _InvitationRow({
    required this.invitation,
    required this.canCancel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.tableBodyUserTeam,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              invitation.invitedEmail.isEmpty ? '—' : invitation.invitedEmail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.textInvertedColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              invitation.proposedRole.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.textInvertedColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: _InviteStatusChip(status: invitation.status),
          ),
          if (invitation.isCancellable && canCancel)
            _ActionIcon(
              icon: Icons.cancel_outlined,
              color: Colors.orange,
              tooltip: AppLocalizations.of(context)!.cancelInvitation,
              onTap: onCancel,
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _InviteStatusChip extends StatelessWidget {
  final String status;
  const _InviteStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final (label, color) = switch (status.toUpperCase()) {
      'ACCEPTED' => (loc.inviteStatusAccepted, const Color(0xFF1B8C4A)),
      'REJECTED' => (loc.inviteStatusRejected, const Color(0xFFE74C3C)),
      'PENDING_REGISTRATION' => (
        loc.inviteStatusUnregistered,
        const Color(0xFF9B59B6),
      ),
      _ => (loc.inviteStatusPending, const Color(0xFFE67E22)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final UserStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final (label, color) = switch (status) {
      UserStatus.active => (loc.statusActive, const Color(0xFF1B8C4A)),
      UserStatus.pending => (loc.memberStatusInvited, const Color(0xFFE67E22)),
      UserStatus.banned => (loc.inviteStatusPending, const Color(0xFF3498DB)),
      UserStatus.deactivated => (loc.memberStatusInactive, Colors.grey),
      UserStatus.deleted => (
        loc.memberStatusSuspended,
        const Color(0xFFE74C3C),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyPlaceholder({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Icon(icon, color: colorScheme.descriptionColor, size: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              label,
              textAlign: TextAlign.center,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.descriptionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Invite form
// ─────────────────────────────────────────────────────────────
class _InviteForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController roleController;
  final List<RoleEntity> roles;
  final VoidCallback onInvite;

  const _InviteForm({
    required this.formKey,
    required this.emailController,
    required this.roleController,
    required this.roles,
    required this.onInvite,
  });

  bool _isOwnerRole(String? roleCode) =>
      (roleCode ?? '').trim().toUpperCase() == 'OWNER';

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_add_rounded,
                size: 16,
                color: theme.colorScheme.descriptionColor,
              ),
              const SizedBox(width: 6),
              Text(
                localization.addUser.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.descriptionColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomInputField(
            hintText: localization.email,
            controller: emailController,
            validator: emailValidator,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final roleFieldWidth = constraints.maxWidth < 420
                  ? constraints.maxWidth
                  : 320.0;
              return SizedBox(
                width: roleFieldWidth,
                child: GenericDropdownFormField<RoleEntity>(
                  label: '',
                  style: theme.textTheme.bodyMedium,
                  prefixIcon: Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 18,
                    color: theme.colorScheme.cursorColor,
                  ),
                  items: roles.where((role) => !_isOwnerRole(role.id)).toList(),
                  value: roleController.text.isEmpty
                      ? null
                      : roles
                            .where(
                              (role) =>
                                  !_isOwnerRole(role.id) &&
                                  role.id == roleController.text,
                            )
                            .firstOrNull,
                  displayText: (r) => r.name,
                  valueGetter: (r) => r,
                  onChanged: (r) => roleController.text = r?.id ?? '',
                  hintText: localization.role,
                  validator: (value) =>
                      value == null ? localization.selectRole : null,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(localization.addUser),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
