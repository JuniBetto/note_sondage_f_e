import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/ui/bloc/app_lifecycle_bloc.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/shift/navigation/shift_open_intent_controller.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/app_keys.dart';

import '../../../core/dependency_injection/dependency_injection.dart';

class NotificationNavigation {
  const NotificationNavigation._();

  static const Duration _navigationRetryDelay = Duration(milliseconds: 120);
  static const int _navigationReadyAttempts = 12;
  static _PendingNotificationNavigationRequest? _pendingRequest;
  static bool _pendingOpenShifts = false;

  static Future<bool> open(
    NotificationCenterItem item, {
    BuildContext? context,
    bool closeOverlays = false,
  }) async {
    try {
      final authBloc = getIt<AuthBloc>();
      if (authBloc.state.status == AuthStatus.unknown ||
          authBloc.state.status == AuthStatus.loading) {
        _pendingRequest = _PendingNotificationNavigationRequest(
          item: item,
          closeOverlays: closeOverlays,
        );
        debugPrint(
          '[NotificationNavigation] Auth not ready for '
          '${item.notificationId} (${item.eventType}); queued for retry.',
        );
        return false;
      }
      final lifecycleBloc = getIt<AppLifecycleBloc>();
      if (lifecycleBloc.state.status != AppLifecycleStatusEnum.active) {
        _pendingRequest = _PendingNotificationNavigationRequest(
          item: item,
          closeOverlays: closeOverlays,
        );
        debugPrint(
          '[NotificationNavigation] App not active for '
          '${item.notificationId} (${item.eventType}); queued for foreground.',
        );
        return false;
      }

      final destination = _resolve(item, armIntents: true);
      if (destination == null) {
        return false;
      }

      final rootNavigatorBeforeAsync = context != null
          ? Navigator.maybeOf(context, rootNavigator: true)
          : null;

      final runtime = await _resolveNavigationRuntime(
        preferredContext: context,
      );
      if (runtime == null) {
        _pendingRequest = _PendingNotificationNavigationRequest(
          item: item,
          closeOverlays: closeOverlays,
        );
        debugPrint(
          '[NotificationNavigation] Router not ready for '
          '${item.notificationId} (${item.eventType}); queued for retry.',
        );
        return false;
      }
      _pendingRequest = null;

      if (closeOverlays) {
        final rootNavigator =
            rootNavigatorBeforeAsync ??
            (runtime.context.mounted
                ? Navigator.of(runtime.context, rootNavigator: true)
                : null);
        if (rootNavigator != null && rootNavigator.canPop()) {
          rootNavigator.pop();
        }
      }

      if (_openInsideMobileMainShell(destination, runtime)) {
        return true;
      }

      switch (destination.kind) {
        case _NotificationDestinationKind.path:
          runtime.router.go(destination.path!);
          return true;
        case _NotificationDestinationKind.named:
          runtime.router.goNamed(
            destination.routeName!,
            extra: destination.extra,
          );
          return true;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[NotificationNavigation] Failed to open notification '
        '${item.notificationId} (${item.eventType}): $error\n$stackTrace',
      );
      _pendingRequest = _PendingNotificationNavigationRequest(
        item: item,
        closeOverlays: closeOverlays,
      );
      return false;
    }
  }

  static Future<bool> drainPending({BuildContext? context}) async {
    final authBloc = getIt<AuthBloc>();
    if (authBloc.state.status == AuthStatus.unknown ||
        authBloc.state.status == AuthStatus.loading) {
      return false;
    }
    final lifecycleBloc = getIt<AppLifecycleBloc>();
    if (lifecycleBloc.state.status != AppLifecycleStatusEnum.active) {
      return false;
    }

    if (_pendingOpenShifts) {
      _pendingOpenShifts = false;
      await openShifts(context: context);
      return true;
    }

    final pendingRequest = _pendingRequest;
    if (pendingRequest == null) {
      return false;
    }

    return open(
      pendingRequest.item,
      context: context,
      closeOverlays: pendingRequest.closeOverlays,
    );
  }

  static String? labelFor(NotificationCenterItem item) {
    try {
      final destination = _resolve(item);
      return destination?.label;
    } catch (error, stackTrace) {
      debugPrint(
        '[NotificationNavigation] Failed to resolve label for '
        '${item.notificationId} (${item.eventType}): $error\n$stackTrace',
      );
      return null;
    }
  }

  static bool _openInsideMobileMainShell(
    _NotificationDestination destination,
    _NavigationRuntime runtime,
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

    final navigationBloc = getIt<NavigationBloc>();
    navigationBloc.add(NavigationPositionChanged(navIndex));
    runtime.router.go(RouterPaths.home);
    return true;
  }

  /// Naviga direttamente alla pagina dei turni (usato per allarmi locali).
  static Future<void> openShifts({BuildContext? context}) async {
    try {
      final lifecycleBloc = getIt<AppLifecycleBloc>();
      if (lifecycleBloc.state.status != AppLifecycleStatusEnum.active) {
        _pendingOpenShifts = true;
        debugPrint(
          '[NotificationNavigation] App not active for shifts; queued for foreground.',
        );
        return;
      }
      final runtime = await _resolveNavigationRuntime(
        preferredContext: context,
      );
      if (runtime == null) {
        _pendingOpenShifts = true;
        debugPrint('[NotificationNavigation] Router not ready for shifts.');
        return;
      }
      _pendingOpenShifts = false;
      runtime.router.go(RouterPaths.shifts);
    } catch (error, stackTrace) {
      debugPrint(
        '[NotificationNavigation] Failed to open shifts: '
        '$error\n$stackTrace',
      );
    }
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
    final workflowContext = item.workflowContext;
    final eventType = item.eventType.toUpperCase();
    final currentUserId = getIt<AuthBloc>().state.user.uid;
    final teamId = workflowContext.resolvedTeamId;

    if (workflowContext.pointsToChat ||
        eventType.contains('CHAT') ||
        metadata.containsKey('conversationId')) {
      final chatType = metadata['chatType']?.trim().toUpperCase() ?? '';
      final participantAUserId = metadata['participantAUserId']?.trim() ?? '';
      final participantBUserId = metadata['participantBUserId']?.trim() ?? '';
      final conversationId = workflowContext.resolvedConversationId;
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
        if (conversationId?.isNotEmpty ?? false)
          'conversationId': conversationId!,
        'focus': 'latest',
      };
      final path = queryParameters.isEmpty
          ? basePath
          : Uri(path: basePath, queryParameters: queryParameters).toString();
      return _NotificationDestination.path(path: path, label: 'Apri chat');
    }

    final sondageId = workflowContext.resolvedSondageId;
    if ((sondageId?.isNotEmpty ?? false) ||
        workflowContext.pointsToSondage ||
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

    if (workflowContext.pointsToShift ||
        eventType.contains('SHIFT') ||
        metadata.containsKey('shiftId') ||
        metadata.containsKey('assignmentId')) {
      final assignmentId = workflowContext.resolvedAssignmentId;
      final shiftDate = metadata['shiftDate']?.trim();
      final teamId = workflowContext.resolvedTeamId;
      final targetUserId = metadata['targetUserId']?.trim();
      final isPublic = metadata['isPublic']?.trim();
      final profileName = metadata['profileName']?.trim();
      final startTime = metadata['startTime']?.trim();
      final endTime = metadata['endTime']?.trim();
      final shouldArmShiftIntent =
          armIntents &&
          _shouldArmShiftOpenIntent(
            eventType: eventType,
            assignmentId: assignmentId,
            shiftDate: shiftDate,
          );
      if (shouldArmShiftIntent) {
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

    if (item.supportsImpactedShiftNavigation) {
      final requestedDate = item.requestedDate?.trim();
      final requesterUserId = item.requesterUserId?.trim();
      final requestTeamId = item.metadata['teamId']?.trim();
      if (armIntents) {
        getIt<ShiftOpenIntentController>().queue(
          shiftDate: requestedDate,
          teamId: requestTeamId,
          targetUserId: requesterUserId,
          openDayEntriesWhenAssignmentMissing: true,
        );
      }
      return _NotificationDestination.path(
        path: RouterPaths.shifts,
        label: 'Vedi turni impattati',
      );
    }

    if (workflowContext.pointsToClocking ||
        eventType.contains('CLOCK') ||
        eventType.contains('TIMBR')) {
      return _NotificationDestination.path(
        path: RouterPaths.clocking,
        label: 'Apri timbrature',
      );
    }

    if (workflowContext.pointsToTeam ||
        (teamId?.isNotEmpty ?? false) ||
        eventType.startsWith('TEAM_')) {
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

  static bool _shouldArmShiftOpenIntent({
    required String eventType,
    required String? assignmentId,
    required String? shiftDate,
  }) {
    final normalizedEventType = eventType.trim().toUpperCase();
    final hasTarget =
        (assignmentId?.isNotEmpty ?? false) || (shiftDate?.isNotEmpty ?? false);
    if (!hasTarget) {
      return false;
    }

    if (normalizedEventType.contains('DELETED') ||
        normalizedEventType.contains('REMOVED')) {
      return false;
    }

    return true;
  }
}

class _PendingNotificationNavigationRequest {
  const _PendingNotificationNavigationRequest({
    required this.item,
    required this.closeOverlays,
  });

  final NotificationCenterItem item;
  final bool closeOverlays;
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
