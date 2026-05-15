import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/domain/use_case/sondage_use_case.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_detail_sections.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

class SondageDetailWeb extends StatefulWidget {
  const SondageDetailWeb({super.key, required this.sondageId});
  final String sondageId;

  @override
  State<SondageDetailWeb> createState() => _SondageDetailWebState();
}

class _SondageDetailWebState extends State<SondageDetailWeb> {
  late final SondageBloc _bloc;
  late final TeamMemberUseCase _teamMemberUseCase;
  StreamSubscription<RealtimeNotification>? _subscription;
  String? _loadedTeamId;
  DateTime? _ignoreRealtimeUntil;
  SondageEntity? _pendingVoteRollback;
  final ValueNotifier<SondageEntity?> _sondageNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isRefreshingNotifier = ValueNotifier(true);
  final ValueNotifier<int?> _teamMemberCountNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _loadErrorNotifier = ValueNotifier(null);
  final ValueNotifier<Set<String>> _pendingVoteOptionIdsNotifier =
      ValueNotifier(<String>{});
  bool _hasInitialContent = false;

  @override
  void initState() {
    super.initState();
    _teamMemberUseCase = getIt<TeamMemberUseCase>();
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

  @override
  void dispose() {
    _subscription?.cancel();
    _sondageNotifier.dispose();
    _isRefreshingNotifier.dispose();
    _teamMemberCountNotifier.dispose();
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
      _teamMemberCountNotifier.value = members.length;
    } catch (_) {
      if (!mounted) return;
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
    _bloc.add(PublishSondageEvent(sondageId));
  }

  void _closeSondage(String sondageId) {
    _markLocalMutation();
    _bloc.add(CloseSondageEvent(sondageId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<SondageBloc, SondageState>(
        listener: (context, state) {
          if (!mounted) {
            return;
          }
          _handleBlocState(state);
          if (state is SondageError && context.mounted) {
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
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}
