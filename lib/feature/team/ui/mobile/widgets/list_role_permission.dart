import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/widgets/role_permission_component.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:async';

class ListRolePermission extends StatefulWidget {
  const ListRolePermission({
    super.key,
    this.isMobile = true,
    required this.teamId,
  });
  final bool isMobile;
  final String teamId;

  @override
  State<ListRolePermission> createState() => _ListRolePermissionState();
}

class _ListRolePermissionState extends State<ListRolePermission> {
  late final RoleBloc _roleBloc;
  List<RoleEntity> rolesList = [];
  Set<String> selectedIds = {};
  bool _isLoading = true;
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _roleBloc = getIt<RoleBloc>();
    _roleBloc.add(LoadRolesEventByTeamId(widget.teamId));
    _realtimeSubscription = getIt<RealtimeNotificationService>().stream.listen(
      _handleRealtimeNotification,
    );
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _handleRealtimeNotification(RealtimeNotification notification) {
    if (notification.sourceService != 'team-service') return;
    if (notification.metadata['teamId'] != widget.teamId) return;
    if (notification.eventType != 'TEAM_ROLE_CREATED' &&
        notification.eventType != 'TEAM_ROLE_UPDATED' &&
        notification.eventType != 'TEAM_ROLE_DELETED') {
      return;
    }
    _roleBloc.add(LoadRolesEventByTeamId(widget.teamId));
  }

  void toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void _deleteRole(String? id) {
    if (id != null) {
      _roleBloc.add(DeleteRoleEvent(id, teamId: widget.teamId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider.value(
      value: _roleBloc,
      child: BlocConsumer<RoleBloc, RoleState>(
        listener: (context, state) {
          if (state is RolesLoaded) {
            setState(() {
              rolesList = state.roles;
              _isLoading = false;
            });
          }
          if (state is RoleLoading) {
            setState(() {
              _isLoading = true;
            });
          }
          if (state is RoleError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (_isLoading) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Skeletonizer(
                enabled: true,
                child: ListView.separated(
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return RolePermissionComponent(
                      teamId: '',
                      isMobile: widget.isMobile,
                      id: 'skeleton-$index',
                      code: 'Loading role name here',
                      description:
                          'This is a placeholder description for the skeleton loading state',
                      isSelected: false,
                      onTap: (_) {},
                    );
                  },
                ),
              ),
            );
          }

          if (rolesList.isEmpty) {
            final localization = AppLocalizations.of(context)!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 32,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localization.noRolesAvailable,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Swipe to create a new role',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rolesList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final role = rolesList[index];
              final isSelected = selectedIds.contains(role.id);

              return RolePermissionComponent(
                isMobile: widget.isMobile,
                id: role.id,
                code: role.name,
                permissions: [...role.permissions],
                description: role.description ?? '',
                teamId: role.teamId,
                isSelected: isSelected,
                onTap: (id) {
                  if (id != null) {
                    toggleSelection(id);
                  }
                },
                onDelete: _deleteRole,
              );
            },
          );
        },
      ),
    );
  }
}
