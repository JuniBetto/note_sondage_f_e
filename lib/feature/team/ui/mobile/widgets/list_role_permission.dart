import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/widgets/role_permission_component.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

  @override
  void initState() {
    super.initState();
    _roleBloc = getIt<RoleBloc>();
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
          // Mostra skeleton durante il caricamento
          if (_isLoading) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  itemCount: 3, // Numero di skeleton items
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
            return const Center(child: Text('Nessun ruolo disponibile'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: rolesList.length,
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
            ),
          );
        },
      ),
    );
  }
}
