import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/shift/navigation/shift_open_intent_controller.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/ui/app_keys.dart';

class NotificationNavigation {
  const NotificationNavigation._();

  static Future<void> open(
    NotificationCenterItem item, {
    BuildContext? context,
    bool closeOverlays = false,
  }) async {
    final destination = _resolve(item, armIntents: true);
    if (destination == null) {
      return;
    }

    final sourceContext = context ?? navigatorKey.currentContext;
    if (sourceContext == null || !sourceContext.mounted) {
      return;
    }

    if (closeOverlays) {
      final rootNavigator = Navigator.of(sourceContext, rootNavigator: true);
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }

    await SchedulerBinding.instance.endOfFrame;
    final navigationContext = navigatorKey.currentContext ?? sourceContext;
    if (!navigationContext.mounted) {
      return;
    }
    final router = GoRouter.of(navigationContext);

    switch (destination.kind) {
      case _NotificationDestinationKind.path:
        router.go(destination.path!);
        return;
      case _NotificationDestinationKind.named:
        router.goNamed(destination.routeName!, extra: destination.extra);
        return;
    }
  }

  static String? labelFor(NotificationCenterItem item) {
    final destination = _resolve(item);
    return destination?.label;
  }

  /// Naviga direttamente alla pagina dei turni (usato per allarmi locali).
  static Future<void> openShifts({BuildContext? context}) async {
    final sourceContext = context ?? navigatorKey.currentContext;
    if (sourceContext == null || !sourceContext.mounted) return;
    await SchedulerBinding.instance.endOfFrame;
    final navigationContext = navigatorKey.currentContext ?? sourceContext;
    if (!navigationContext.mounted) {
      return;
    }
    GoRouter.of(navigationContext).go(RouterPaths.shifts);
  }

  static _NotificationDestination? _resolve(
    NotificationCenterItem item, {
    bool armIntents = false,
  }) {
    final metadata = item.metadata;
    final eventType = item.eventType.toUpperCase();
    final currentUserId = getIt<AuthBloc>().state.user.uid;

    final sondageId = metadata['sondageId']?.trim();
    if ((sondageId?.isNotEmpty ?? false) ||
        eventType.contains('SONDAGE') ||
        eventType.contains('SURVEY')) {
      if (sondageId?.isNotEmpty ?? false) {
        return _NotificationDestination.named(
          routeName: RouterPaths.sondageDetail,
          extra: sondageId,
          label: 'Apri sondaggio',
        );
      }
      return _NotificationDestination.path(
        path: RouterPaths.sondage,
        label: 'Apri sondaggio',
      );
    }

    if (eventType.contains('SHIFT') ||
        metadata.containsKey('shiftId') ||
        metadata.containsKey('assignmentId')) {
      final assignmentId = metadata['assignmentId']?.trim();
      final shiftDate = metadata['shiftDate']?.trim();
      final teamId = metadata['teamId']?.trim();
      final targetUserId = metadata['targetUserId']?.trim();
      final isPublic = metadata['isPublic']?.trim();
      final profileName = metadata['profileName']?.trim();
      final startTime = metadata['startTime']?.trim();
      final endTime = metadata['endTime']?.trim();
      if (armIntents &&
          ((assignmentId?.isNotEmpty ?? false) ||
              (shiftDate?.isNotEmpty ?? false))) {
        getIt<ShiftOpenIntentController>().queue(
          assignmentId: assignmentId,
          shiftDate: shiftDate,
          teamId: teamId,
          targetUserId: targetUserId,
          isPublic: isPublic,
          profileName: profileName,
          startTime: startTime,
          endTime: endTime,
        );
      }
      return _NotificationDestination.path(
        path: RouterPaths.shifts,
        label: (assignmentId?.isNotEmpty ?? false)
            ? 'Apri turno'
            : 'Apri turni',
      );
    }

    if (eventType.contains('CLOCK') || eventType.contains('TIMBR')) {
      return _NotificationDestination.path(
        path: RouterPaths.clocking,
        label: 'Apri timbrature',
      );
    }

    final teamId = metadata['teamId']?.trim();
    if ((teamId?.isNotEmpty ?? false) || eventType.startsWith('TEAM_')) {
      if (item.hidesTeamDetailFor(currentUserId)) {
        return _NotificationDestination.path(
          path: RouterPaths.team,
          label: null,
        );
      }
      if (teamId?.isNotEmpty ?? false) {
        return _NotificationDestination.named(
          routeName: RouterPaths.updateTeam,
          extra: teamId,
          label: 'Apri team',
        );
      }
      return _NotificationDestination.path(
        path: RouterPaths.team,
        label: 'Apri team',
      );
    }

    return null;
  }
}

enum _NotificationDestinationKind { path, named }

class _NotificationDestination {
  const _NotificationDestination.path({required this.path, required this.label})
    : kind = _NotificationDestinationKind.path,
      routeName = null,
      extra = null;

  const _NotificationDestination.named({
    required this.routeName,
    required this.extra,
    required this.label,
  }) : kind = _NotificationDestinationKind.named,
       path = null;

  final _NotificationDestinationKind kind;
  final String? path;
  final String? routeName;
  final Object? extra;
  final String? label;
}
