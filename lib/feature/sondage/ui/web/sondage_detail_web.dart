import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/notification/navigation/notification_navigation.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/navigation/shift_open_intent_controller.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/domain/use_case/sondage_use_case.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_detail_sections.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_pending_reminder_dialog.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_confirmation_dialog.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

class SondageDetailWeb extends StatefulWidget {
  const SondageDetailWeb({super.key, required this.sondageId});
  final String sondageId;

  @override
  State<SondageDetailWeb> createState() => _SondageDetailWebState();
}

class _SondageDetailWebState extends State<SondageDetailWeb> {
  static const Duration _expiryRefreshGrace = Duration(seconds: 1);
  late final SondageBloc _bloc;
  late final SondageUseCase _sondageUseCase;
  late final TeamMemberUseCase _teamMemberUseCase;
  late final ShiftRepository _shiftRepository;
  StreamSubscription<RealtimeNotification>? _subscription;
  Timer? _expiryRefreshTimer;
  String? _loadedTeamId;
  DateTime? _ignoreRealtimeUntil;
  SondageEntity? _pendingVoteRollback;
  final ValueNotifier<SondageEntity?> _sondageNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isRefreshingNotifier = ValueNotifier(true);
  final ValueNotifier<int?> _teamMemberCountNotifier = ValueNotifier(null);
  final ValueNotifier<List<TeamMemberEntity>> _teamMembersNotifier =
      ValueNotifier(const <TeamMemberEntity>[]);
  final ValueNotifier<String?> _loadErrorNotifier = ValueNotifier(null);
  final ValueNotifier<Set<String>> _pendingVoteOptionIdsNotifier =
      ValueNotifier(<String>{});
  bool _hasInitialContent = false;
  bool _refreshRootListAfterMutation = false;

  @override
  void initState() {
    super.initState();
    _sondageUseCase = getIt<SondageUseCase>();
    _teamMemberUseCase = getIt<TeamMemberUseCase>();
    _shiftRepository = getIt<ShiftRepository>();
    // The list screen's root bloc already holds the full entity for the
    // tapped card: paint it immediately instead of waiting on a fresh
    // network round trip for data we already have.
    final cachedSondage = context.read<SondageBloc>().cachedById(
      widget.sondageId,
    );
    if (cachedSondage != null) {
      _sondageNotifier.value = cachedSondage;
      _hasInitialContent = true;
      _ensureTeamMemberCountLoaded(cachedSondage);
      _scheduleExpiryRefreshFor(cachedSondage);
    }
    _bloc = SondageBloc(
      sondageUseCase: getIt<SondageUseCase>(),
      sondageLocalDataSource: getIt(),
    )..add(LoadSondageByIdEvent(widget.sondageId));
    _subscription = getIt<RealtimeNotificationService>().stream.listen((event) {
      if (!mounted || _bloc.isClosed) return;
      if (event.sourceService == 'sondage-service' &&
          event.metadata['sondageId'] == widget.sondageId &&
          !_shouldIgnoreRealtimeRefresh) {
        _bloc.add(LoadSondageByIdEvent(widget.sondageId));
      }
    });
  }

  void _scheduleExpiryRefreshFor(SondageEntity sondage) {
    _expiryRefreshTimer?.cancel();
    final expiry = sondage.expiryDate;
    if (sondage.status != SondageStatus.active || expiry == null) {
      return;
    }

    final delay = expiry.difference(DateTime.now()) + _expiryRefreshGrace;
    final effectiveDelay = delay.isNegative
        ? const Duration(milliseconds: 500)
        : delay;

    _expiryRefreshTimer = Timer(effectiveDelay, () {
      if (!mounted || _bloc.isClosed || _shouldIgnoreRealtimeRefresh) {
        return;
      }
      _bloc.add(LoadSondageByIdEvent(widget.sondageId));
    });
  }

  @override
  void dispose() {
    _expiryRefreshTimer?.cancel();
    _subscription?.cancel();
    _sondageNotifier.dispose();
    _isRefreshingNotifier.dispose();
    _teamMemberCountNotifier.dispose();
    _teamMembersNotifier.dispose();
    _loadErrorNotifier.dispose();
    _pendingVoteOptionIdsNotifier.dispose();
    _bloc.close();
    super.dispose();
  }

  Future<void> _ensureTeamMemberCountLoaded(SondageEntity sondage) async {
    final teamId = sondage.teamId;
    if (teamId == null || teamId.isEmpty || _loadedTeamId == teamId) {
      return;
    }

    _loadedTeamId = teamId;
    try {
      final members = await _teamMemberUseCase.getAllMembersByTeamId(teamId);
      if (!mounted) return;
      final activeMembers = members
          .where((member) => member.status == UserStatus.active)
          .toList(growable: false);
      _teamMembersNotifier.value = activeMembers;
      _teamMemberCountNotifier.value = activeMembers.length;
    } catch (_) {
      if (!mounted) return;
      _teamMembersNotifier.value = const <TeamMemberEntity>[];
      _teamMemberCountNotifier.value = null;
    }
  }

  void _handleBlocState(SondageState state) {
    if (state is SondageLoading) {
      if (_sondageNotifier.value != null) {
        _isRefreshingNotifier.value = true;
      }
      return;
    }

    if (state is SondageLoaded || state is SondageActionSuccess) {
      final sondage = state is SondageLoaded
          ? state.sondage
          : (state as SondageActionSuccess).sondage;
      _pendingVoteRollback = null;
      _pendingVoteOptionIdsNotifier.value = <String>{};
      _sondageNotifier.value = sondage;
      _loadErrorNotifier.value = null;
      _isRefreshingNotifier.value = false;
      _ensureTeamMemberCountLoaded(sondage);
      _scheduleExpiryRefreshFor(sondage);
      if (!_hasInitialContent && mounted) {
        setState(() {
          _hasInitialContent = true;
        });
      }
      return;
    }

    if (state is SondageError) {
      if (_pendingVoteRollback != null) {
        _sondageNotifier.value = _pendingVoteRollback;
        _pendingVoteRollback = null;
        _pendingVoteOptionIdsNotifier.value = <String>{};
      }
      _isRefreshingNotifier.value = false;
      _loadErrorNotifier.value = state.message;
    }
  }

  bool get _shouldIgnoreRealtimeRefresh =>
      _ignoreRealtimeUntil != null &&
      DateTime.now().isBefore(_ignoreRealtimeUntil!);

  void _markLocalMutation() {
    _ignoreRealtimeUntil = DateTime.now().add(const Duration(seconds: 1));
  }

  SondageEntity? _buildOptimisticVoteSondage(
    SondageEntity current,
    String optionId,
  ) {
    if (!current.canVote) {
      return null;
    }

    final hasCurrentSingleVote = (current.currentUserOptionId ?? '')
        .trim()
        .isNotEmpty;
    final hadUserVote =
        hasCurrentSingleVote || current.currentUserOptionIds.isNotEmpty;
    if (current.allowMultipleResponses) {
      final isSelected = current.currentUserOptionIds.contains(optionId);
      final updatedOptionIds = isSelected
          ? current.currentUserOptionIds
                .where((existingId) => existingId != optionId)
                .toList()
          : <String>{...current.currentUserOptionIds, optionId}.toList();
      final updatedOptions = current.options.map((option) {
        if (option.id != optionId) {
          return option;
        }
        final nextCount = isSelected
            ? (option.voteCount > 0 ? option.voteCount - 1 : 0)
            : option.voteCount + 1;
        return option.copyWith(voteCount: nextCount);
      }).toList();
      final hadVoteBefore = current.currentUserOptionIds.isNotEmpty;
      final hasVoteAfter = updatedOptionIds.isNotEmpty;
      final responseDelta = hadVoteBefore == hasVoteAfter
          ? 0
          : (hasVoteAfter ? 1 : -1);
      final totalVoteDelta = isSelected ? -1 : 1;

      return current.copyWith(
        options: updatedOptions,
        totalVotes: totalVoteDelta < 0 && current.totalVotes > 0
            ? current.totalVotes - 1
            : current.totalVotes + totalVoteDelta,
        responses: responseDelta < 0 && current.responses > 0
            ? current.responses - 1
            : current.responses + responseDelta,
        currentUserOptionIds: updatedOptionIds,
        canVote: current.canVote,
      );
    }

    if (current.currentUserOptionId == optionId) {
      return null;
    }

    final previousOptionId = current.currentUserOptionId;
    final updatedOptions = current.options.map((option) {
      if (option.id == optionId) {
        return option.copyWith(voteCount: option.voteCount + 1);
      }
      if (option.id == previousOptionId) {
        return option.copyWith(
          voteCount: option.voteCount > 0 ? option.voteCount - 1 : 0,
        );
      }
      return option;
    }).toList();

    return current.copyWith(
      options: updatedOptions,
      totalVotes: current.totalVotes + (hadUserVote ? 0 : 1),
      responses: hadUserVote ? current.responses : current.responses + 1,
      currentUserOptionId: optionId,
      currentUserOptionIds: <String>[optionId],
      canVote: current.canVote,
    );
  }

  void _voteForOption(String sondageId, String optionId) {
    final current = _sondageNotifier.value;
    if (current == null) {
      return;
    }
    final optimisticSondage = _buildOptimisticVoteSondage(current, optionId);
    if (optimisticSondage == null) {
      return;
    }
    _pendingVoteRollback = current;
    _pendingVoteOptionIdsNotifier.value = <String>{optionId};
    _sondageNotifier.value = optimisticSondage;
    _markLocalMutation();
    _bloc.add(VoteSondageEvent(sondageId, optionId));
  }

  void _publishSondage(String sondageId) {
    _markLocalMutation();
    _refreshRootListAfterMutation = true;
    _bloc.add(PublishSondageEvent(sondageId));
  }

  void _closeSondage(String sondageId) {
    _markLocalMutation();
    _refreshRootListAfterMutation = true;
    _bloc.add(CloseSondageEvent(sondageId));
  }

  void _reopenSondage(String sondageId) {
    _markLocalMutation();
    _refreshRootListAfterMutation = true;
    _bloc.add(ReopenSondageEvent(sondageId));
  }

  List<TeamMemberEntity> _pendingReminderMembers(SondageEntity sondage) {
    final voterUserIds = sondage.voterUserIds.toSet();
    return _teamMembersNotifier.value
        .where((member) {
          final userId = member.userId ?? '';
          return userId.isNotEmpty && !voterUserIds.contains(userId);
        })
        .toList(growable: false);
  }

  Future<void> _openReminderDialog(SondageEntity sondage) async {
    final pendingMembers = _pendingReminderMembers(sondage);
    if (pendingMembers.isEmpty) {
      AppSnackBar.showWarning(
        context,
        _allEligibleMembersAlreadyVotedMessage(),
      );
      return;
    }

    final selectedUserIds = await SondagePendingReminderDialog.show(
      context,
      sondageName: sondage.name,
      pendingMembers: pendingMembers,
    );
    if (!mounted || selectedUserIds == null || selectedUserIds.isEmpty) {
      return;
    }

    try {
      final notifiedCount = await _sondageUseCase.remindPendingVoters(
        sondage.id,
        recipientUserIds: selectedUserIds,
      );
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(context, _reminderSentMessage(notifiedCount));
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showResolvedError(context, error);
    }
  }

  Future<void> _confirmDeleteSondage(SondageEntity sondage) async {
    final shouldDelete = await showAppConfirmationDialog(
      context,
      title: _deleteSurveyTitle(),
      message: _deleteSurveyMessage(),
      confirmLabel: _deleteSurveyAction(),
      destructive: true,
    );

    if (shouldDelete == true) {
      _markLocalMutation();
      _bloc.add(DeleteSondageEvent(sondage.id));
    }
  }

  Future<void> _openLinkedShift(SondageEntity sondage) async {
    final assignmentId = sondage.workflowContext.resolvedAssignmentId;
    if (assignmentId == null || assignmentId.isEmpty) {
      AppSnackBar.showWarning(context, _linkedShiftUnavailableMessage());
      return;
    }

    String? shiftDate;
    try {
      final replacementContext = await _shiftRepository
          .findReplacementCandidates(assignmentId);
      shiftDate = replacementContext.shiftDate.toIso8601String();
    } catch (_) {
      shiftDate = null;
    }

    getIt<ShiftOpenIntentController>().queue(
      assignmentId: assignmentId,
      shiftDate: shiftDate,
      teamId: sondage.workflowContext.resolvedTeamId,
      preferredUserIds: sondage.workflowAvailableResponderUserIds,
      openDialogWhenAssignmentMissing: true,
    );
    if (!mounted) {
      return;
    }
    await NotificationNavigation.openShifts(context: context);
  }

  void _openLinkedConversation(SondageEntity sondage) {
    final teamId =
        sondage.workflowContext.resolvedTeamId ?? sondage.teamId?.trim();
    final conversationId = sondage.workflowContext.resolvedSourceConversationId;
    if (teamId == null ||
        teamId.isEmpty ||
        conversationId == null ||
        conversationId.isEmpty) {
      AppSnackBar.showWarning(context, _linkedConversationUnavailableMessage());
      return;
    }

    final path = Uri(
      path: RouterPaths.chat,
      queryParameters: <String, String>{
        'teamId': teamId,
        'conversationId': conversationId,
        'focus': 'latest',
      },
    ).toString();
    context.go(path);
  }

  Future<void> _autoReplaceLinkedShift(SondageEntity sondage) async {
    final assignmentId = sondage.workflowContext.resolvedAssignmentId;
    if (assignmentId == null || assignmentId.isEmpty) {
      AppSnackBar.showWarning(context, _linkedShiftUnavailableMessage());
      return;
    }
    if (sondage.workflowAvailableResponderUserIds.isEmpty) {
      AppSnackBar.showWarning(context, _noAvailableSurveyResponsesMessage());
      return;
    }

    String? shiftDate;
    try {
      final replacementContext = await _shiftRepository
          .findReplacementCandidates(assignmentId);
      shiftDate = replacementContext.shiftDate.toIso8601String();
    } catch (_) {
      shiftDate = null;
    }

    getIt<ShiftOpenIntentController>().queue(
      assignmentId: assignmentId,
      shiftDate: shiftDate,
      teamId: sondage.workflowContext.resolvedTeamId,
      preferredUserIds: sondage.workflowAvailableResponderUserIds,
      autoReplaceFromWorkflow: true,
      openDialogWhenAssignmentMissing: true,
    );
    if (!mounted) {
      return;
    }
    await NotificationNavigation.openShifts(context: context);
  }

  String _reminderSentMessage(int count) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Promemoria inviato a $count membro/i.',
      'fr' => 'Rappel envoye a $count membre(s).',
      'es' => 'Recordatorio enviado a $count miembro(s).',
      _ => 'Reminder sent to $count member(s).',
    };
  }

  String _linkedShiftUnavailableMessage() {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Questo sondaggio non ha un turno collegato apribile.',
      'fr' => 'Ce sondage n a pas de quart lie ouvrable.',
      'es' => 'Esta encuesta no tiene un turno vinculado que se pueda abrir.',
      _ => 'This survey does not have a linked shift to open.',
    };
  }

  String _linkedConversationUnavailableMessage() {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Questo sondaggio non ha una conversazione collegata apribile.',
      'fr' => 'Ce sondage n a pas de conversation liee ouvrable.',
      'es' =>
        'Esta encuesta no tiene una conversacion vinculada que se pueda abrir.',
      _ => 'This survey does not have a linked conversation to open.',
    };
  }

  String _noAvailableSurveyResponsesMessage() {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Nessun collega ha ancora risposto disponibile nel sondaggio.',
      'fr' => 'Aucun collegue n a encore repondu disponible dans le sondage.',
      'es' =>
        'Ningun companero ha respondido todavia como disponible en la encuesta.',
      _ => 'No teammate has replied available in the survey yet.',
    };
  }

  String _allEligibleMembersAlreadyVotedMessage() {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Tutti i membri idonei hanno gia votato.',
      'fr' => 'Tous les membres eligibles ont deja vote.',
      'es' => 'Todos los miembros elegibles ya han votado.',
      _ => 'All eligible members have already voted.',
    };
  }

  String _deleteSurveyTitle() {
    return AppLocalizations.of(context)!.deleteSurveyTitle;
  }

  String _deleteSurveyMessage() {
    return AppLocalizations.of(context)!.deleteSurveyMessage;
  }

  String _deleteSurveyAction() {
    return AppLocalizations.of(context)!.deleteAction;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;
    final rootSondageBloc = context.read<SondageBloc>();

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<SondageBloc, SondageState>(
        listener: (context, state) {
          if (!mounted) {
            return;
          }
          final shouldRefreshRootList =
              state is SondageActionSuccess && _refreshRootListAfterMutation;
          _handleBlocState(state);
          if (state is SondageLoaded || state is SondageActionSuccess) {
            final sondage = state is SondageLoaded
                ? state.sondage
                : (state as SondageActionSuccess).sondage;
            if (!rootSondageBloc.isClosed) {
              rootSondageBloc.add(SyncCachedSondageEvent(sondage));
              if (shouldRefreshRootList) {
                rootSondageBloc.add(LoadSondagesEvent());
              }
            }
            if (state is SondageActionSuccess) {
              _refreshRootListAfterMutation = false;
            }
          }
          if (state is SondageDeleted && context.mounted) {
            if (!rootSondageBloc.isClosed) {
              rootSondageBloc.add(RemoveCachedSondageEvent(widget.sondageId));
            }
            AppSnackBar.showSuccess(context, localization.surveyDeleted);
            context.go(RouterPaths.sondage);
            return;
          }
          if (state is SondageError && context.mounted) {
            _refreshRootListAfterMutation = false;
            AppSnackBar.showError(context, state.message);
          }
        },
        child: !_hasInitialContent
            ? ValueListenableBuilder<bool>(
                valueListenable: _isRefreshingNotifier,
                builder: (context, isRefreshing, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: _loadErrorNotifier,
                    builder: (context, errorMessage, _) {
                      if (isRefreshing) {
                        return Scaffold(
                          backgroundColor: colorScheme.homePrimary,
                          body: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return Scaffold(
                        backgroundColor: colorScheme.homePrimary,
                        body: Center(
                          child: Text(
                            errorMessage ?? localization.surveyNotFound,
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            : Scaffold(
                backgroundColor: colorScheme.homePrimary,
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: _isRefreshingNotifier,
                            builder: (context, isRefreshing, _) {
                              if (!isRefreshing) {
                                return const SizedBox.shrink();
                              }
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: LinearProgressIndicator(minHeight: 2),
                              );
                            },
                          ),
                          ValueListenableBuilder<SondageEntity?>(
                            valueListenable: _sondageNotifier,
                            builder: (context, sondage, _) {
                              if (sondage == null) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.bgNavbarSurface,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          context.go(RouterPaths.sondage),
                                      icon: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: colorScheme.iconLabel,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sondage.name,
                                            style: textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.iconLabel,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            sondage.teamName ?? '-',
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SondageStatusChip(
                                      status: sondage.status.name,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 900;
                              final infoSection = AnimatedBuilder(
                                animation: Listenable.merge([
                                  _sondageNotifier,
                                  _teamMemberCountNotifier,
                                ]),
                                builder: (context, _) {
                                  final sondage = _sondageNotifier.value;
                                  if (sondage == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return SondageDetailInfoSection(
                                    sondage: sondage,
                                    formatDate: _formatDate,
                                    colorScheme: colorScheme,
                                    textTheme: textTheme,
                                    onOpenLinkedConversation:
                                        RuntimeConfig.enableWorkflowActions &&
                                            sondage
                                                    .workflowContext
                                                    .resolvedSourceConversationId !=
                                                null
                                        ? () => _openLinkedConversation(sondage)
                                        : null,
                                    onOpenLinkedShift:
                                        RuntimeConfig.enableWorkflowActions &&
                                            sondage
                                                    .workflowContext
                                                    .resolvedAssignmentId !=
                                                null
                                        ? () => _openLinkedShift(sondage)
                                        : null,
                                  );
                                },
                              );
                              final progressSection = AnimatedBuilder(
                                animation: Listenable.merge([
                                  _sondageNotifier,
                                  _teamMemberCountNotifier,
                                ]),
                                builder: (context, _) {
                                  final sondage = _sondageNotifier.value;
                                  if (sondage == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return SondageDetailProgressSection(
                                    sondage: sondage,
                                    teamMemberCount:
                                        _teamMemberCountNotifier.value,
                                    colorScheme: colorScheme,
                                    textTheme: textTheme,
                                  );
                                },
                              );
                              final voteSection = AnimatedBuilder(
                                animation: Listenable.merge([
                                  _sondageNotifier,
                                  _pendingVoteOptionIdsNotifier,
                                ]),
                                builder: (context, _) {
                                  final sondage = _sondageNotifier.value;
                                  if (sondage == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return SondageVoteSection(
                                    sondage: sondage,
                                    pendingOptionIds:
                                        _pendingVoteOptionIdsNotifier.value,
                                    onVote: (optionId) =>
                                        _voteForOption(sondage.id, optionId),
                                    colorScheme: colorScheme,
                                    textTheme: textTheme,
                                    compactPadding: const EdgeInsets.all(18),
                                  );
                                },
                              );
                              final actionsSection =
                                  ValueListenableBuilder<SondageEntity?>(
                                    valueListenable: _sondageNotifier,
                                    builder: (context, sondage, _) {
                                      if (sondage == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return SondageOwnerActionsSection(
                                        sondage: sondage,
                                        onPublish: () =>
                                            _publishSondage(sondage.id),
                                        onClose: () =>
                                            _closeSondage(sondage.id),
                                        onReopen: sondage.canReopen
                                            ? () => _reopenSondage(sondage.id)
                                            : null,
                                        onDelete: sondage.canDelete
                                            ? () =>
                                                  _confirmDeleteSondage(sondage)
                                            : null,
                                        onRemind: _canRemindForSurvey(sondage)
                                            ? () => _openReminderDialog(sondage)
                                            : null,
                                        onOpenLinkedConversation:
                                            RuntimeConfig
                                                    .enableWorkflowActions &&
                                                sondage
                                                        .workflowContext
                                                        .resolvedSourceConversationId !=
                                                    null
                                            ? () => _openLinkedConversation(
                                                sondage,
                                              )
                                            : null,
                                        onOpenLinkedShift:
                                            RuntimeConfig
                                                    .enableWorkflowActions &&
                                                sondage
                                                        .workflowContext
                                                        .resolvedAssignmentId !=
                                                    null
                                            ? () => _openLinkedShift(sondage)
                                            : null,
                                        onAutoReplaceLinkedShift:
                                            RuntimeConfig
                                                    .enableWorkflowActions &&
                                                _canRemindForSurvey(sondage) &&
                                                sondage
                                                        .workflowContext
                                                        .resolvedAssignmentId !=
                                                    null &&
                                                sondage
                                                    .workflowAvailableResponderUserIds
                                                    .isNotEmpty
                                            ? () => _autoReplaceLinkedShift(
                                                sondage,
                                              )
                                            : null,
                                      );
                                    },
                                  );

                              if (isCompact) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    infoSection,
                                    const SizedBox(height: 18),
                                    progressSection,
                                    const SizedBox(height: 18),
                                    voteSection,
                                    const SizedBox(height: 18),
                                    actionsSection,
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: infoSection),
                                      const SizedBox(width: 20),
                                      Expanded(child: progressSection),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  voteSection,
                                  const SizedBox(height: 20),
                                  actionsSection,
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return DateFormat(
      'dd/MM/yyyy HH:mm',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(value);
  }

  bool _canRemindForSurvey(SondageEntity sondage) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCreator =
        currentUserId != null && sondage.createdByUserId == currentUserId;
    return sondage.status == SondageStatus.active &&
        (isCreator || sondage.canEdit || sondage.canDelete || sondage.canClose);
  }
}
