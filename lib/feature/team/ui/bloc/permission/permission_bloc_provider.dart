// permission_bloc_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/team/domain/repositories/permission_repository.dart';
import 'package:note_sondage/feature/team/domain/use_case/permission/permission_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/permission/permission_bloc.dart';

class PermissionBlocProvider extends StatelessWidget {
  final Widget child;
  final PermissionRepository repository;

  const PermissionBlocProvider({
    Key? key,
    required this.child,
    required this.repository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoleBloc>(
      create: (context) =>
          RoleBloc(permissionUseCase: PermissionUseCase(repository)),
      child: child,
    );
  }
}
