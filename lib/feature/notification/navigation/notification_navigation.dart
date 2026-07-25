import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/shift/navigation/shift_open_intent_controller.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/app_keys.dart';

class NotificationNavigation {
  const NotificationNavigation._();

  static const Duration _navigationRetryDelay = Duration(milliseconds: 120);
  static const int _navigationReadyAttempts = 12;

  static Future<void> open(
    NotificationCenterItem item, {
    BuildContext? context,
    bool closeOverlays = false,
  }) async {
    final destination = _resolve(item, armIntents: true);
    if (destination == null) {
      return;
    }

    final runtime = await _resolveNavigationRuntime(preferredContext: context);
    if (runtime == null) {
      debugPrint(
        '[NotificationNavigation] Router not ready for '
        '${item.notificationId} (${item.eventType}).',
      );
      return;
    }

    if (closeOverlays) {
      final rootNavigator = Navigator.of(runtime.context, rootNavigator: true);
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }

    if (_openInsideMobileMainShell(destination, runtime.router)) {
      return;
    }

    switch (destination.kind) {
      case _NotificationDestinationKind.path:
        runtime.router.go(destination.path!);
        return;
      case _NotificationDestinationKind.named:
        runtime.router.goNamed(
          destination.routeName!,
          extra: destination.extra,
        );
        return;
    }
  }

  static String? labelFor(NotificationCenterItem item) {
    final destination = _resolve(item);
    return destination?.label;
  }

  static bool _openInsideMobileMainShell(
    _NotificationDestination destination,
    GoRouter router,
  ) {
    if (kIsWeb || destination.kind != _NotificationDestinationKind.path) {
      return false;
    }

    final navIndex = switch (destination.path) {
      RouterPaths.home => 0,
      RouterPaths.team => 1,
      RouterPaths.clocking => 3,
      RouterPaths.sondage => 4,
      _ => null,
    };
    if (navIndex == null) {
      return false;
    }

    getIt<NavigationBloc>().add(NavigationPositionChanged(navIndex));
    router.go(RouterPaths.home);
    return true;
  }

  /// Naviga direttamente alla pagina dei turni (usato per allarmi locali).
  static Future<void> openShifts({BuildContext? context}) async {
    final runtime = await _resolveNavigationRuntime(preferredContext: context);
    if (runtime == null) {
      debugPrint('[NotificationNavigation] Router not ready for shifts.');
      return;
    }
    runtime.router.go(RouterPaths.shifts);
  }

  static Future<_NavigationRuntime?> _resolveNavigationRuntime({
    BuildContext? preferredContext,
  }) async {
    for (var attempt = 0; attempt < _navigationReadyAttempts; attempt++) {
      await SchedulerBinding.instance.endOfFrame;

      final navigationContext = navigatorKey.currentContext;
      if (navigationContext != null && navigationContext.mounted) {
        final router = GoRouter.maybeOf(navigationContext);
        if (router != null) {
          return _NavigationRuntime(navigationContext, router);
        }
      }

      if (preferredContext != null && preferredContext.mounted) {
        final router = GoRouter.maybeOf(preferredContext);
        if (router != null) {
          return _NavigationRuntime(preferredContext, router);
        }
      }

      await Future<void>.delayed(_navigationRetryDelay);
    }
    return null;
  }

  static _NotificationDestination? _resolve(
    NotificationCenterItem item, {
    bool armIntents = false,
  }) {
    final metadata = item.metadata;
    final eventType = item.eventType.toUpperCase();
    final currentUserId = getIt<AuthBloc>().state.user.uid;
    final teamId = metadata['teamId']?.trim();

    if (eventType.contains('CHAT') || metadata.containsKey('conversationId')) {
      final chatType = metadata['chatType']?.trim().toUpperCase() ?? '';
      final participantAUserId = metadata['participantAUserId']?.trim() ?? '';
      final participantBUserId = metadata['participantBUserId']?.trim() ?? '';
      final directMemberUserId = chatType == 'DIRECT'
          ? (participantAUserId == currentUserId
                ? participantBUserId
                : participantAUserId)
          : '';
      final basePath = kIsWeb
          ? RouterPaths.chat
          : RouterPaths.sondageChatConversation;
      final queryParameters = <String, String>{
        if (teamId?.isNotEmpty ?? false) 'teamId': teamId!,
        if (directMemberUserId.isNotEmpty) 'memberUserId': directMemberUserId,
        'focus': 'latest',
      };
      final path = queryParameters.isEmpty
          ? basePath
          : Uri(path: basePath, queryParameters: queryParameters).toString();
      return _NotificationDestination.path(path: path, label: 'Apri chat');
    }

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

class _NavigationRuntime {
  const _NavigationRuntime(this.context, this.router);

  final BuildContext context;
  final GoRouter router;
}
