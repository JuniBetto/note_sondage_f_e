import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/team_display.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../support/test_app.dart';

class _AuthBloc extends Mock implements AuthBloc {
  @override
  AuthState get state => const AuthState.unauthenticated();

  @override
  Stream<AuthState> get stream => const Stream.empty();
}

class _TeamBloc extends Mock implements TeamBloc {
  @override
  TeamState get state => TeamInitial();

  @override
  Stream<TeamState> get stream => const Stream.empty();
}

class _TeamMemberUseCase extends Mock implements TeamMemberUseCase {}

class _RoleUseCase extends Mock implements RoleUseCase {}

void main() {
  test('all tutorial messages are present in every supported catalog', () {
    Map<String, dynamic> catalog(String language) =>
        jsonDecode(
              File('lib/languages/l10n/app_$language.arb').readAsStringSync(),
            )
            as Map<String, dynamic>;

    final english = catalog('en');
    final keys = english.keys.where((key) => key.startsWith('tutorial'));
    expect(keys, isNotEmpty);
    for (final language in ['it', 'fr', 'es']) {
      final localized = catalog(language);
      for (final key in keys) {
        expect(
          localized[key],
          isA<String>(),
          reason: '$language: $key missing',
        );
        expect(
          (localized[key] as String).trim(),
          isNotEmpty,
          reason: '$language: $key empty',
        );
      }
    }
  });

  testWidgets('team tutorial follows locale changes in the mounted page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'app_tutorial_seen::anonymous::mobile-team-list': true,
    });
    final showcase = ShowcaseView.register();
    addTearDown(() {
      AppTutorialController.unregisterTutorial('mobile-team-list');
      showcase.unregister();
    });
    final auth = _AuthBloc();
    getIt.registerSingleton<AuthBloc>(auth);
    getIt.registerSingleton<TeamBloc>(_TeamBloc());
    getIt.registerSingleton<TeamMemberUseCase>(_TeamMemberUseCase());
    getIt.registerSingleton<RoleUseCase>(_RoleUseCase());
    getIt.registerSingleton<UserArchiveService>(UserArchiveService());
    addTearDown(() => getIt.reset());
    const teamsKey = ValueKey('teams');
    Object? originalState;

    for (final entry in {
      'it': ['Elenco squadre', 'Vista team'],
      'en': ['Team list', 'Team layout'],
      'fr': ['Liste des équipes', 'Affichage des équipes'],
      'es': ['Lista de equipos', 'Vista de equipos'],
    }.entries) {
      await tester.pumpWidget(
        buildTestApp(
          locale: Locale(entry.key),
          child: BlocProvider<AuthBloc>.value(
            value: auth,
            child: TeamsDisplay(
              key: teamsKey,
              teams: const [],
              onViewChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final currentState = tester.state(find.byKey(teamsKey));
      originalState ??= currentState;
      expect(currentState, same(originalState));
      final targets = tester.widgetList<Showcase>(find.byType(Showcase));
      expect(
        targets.map((target) => target.title),
        unorderedEquals(entry.value),
      );
      expect(
        targets.every((target) => target.description?.isNotEmpty ?? false),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
