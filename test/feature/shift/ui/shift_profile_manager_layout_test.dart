import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_profile_manager.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class _FakeShiftBloc extends Fake implements ShiftBloc {
  @override
  ShiftState get state => ShiftInitial();

  @override
  Stream<ShiftState> get stream => const Stream<ShiftState>.empty();

  @override
  Future<void> close() async {}
}

const _profile = ShiftProfileEntity(
  id: 'sys-1',
  name: 'Reperibilità Domenica',
  startTime: TimeOfDay(hour: 0, minute: 0),
  endTime: TimeOfDay(hour: 0, minute: 0),
  overnight: false,
  isSystem: true,
  alarmOffsets: [],
);

// Nei test il font e' Ahem (ogni glifo e' un quadrato largo quanto il corpo),
// quindi le larghezze sono molto superiori a quelle reali: contano solo i
// rapporti tra le tre situazioni (spazio ampio, medio, insufficiente).
void main() {
  Future<void> pumpManager(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width + 64, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: 700,
              child: BlocProvider<ShiftBloc>.value(
                value: _FakeShiftBloc(),
                child: const ShiftProfileManager(profiles: [_profile]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('name and time share one line when the panel is wide', (
    tester,
  ) async {
    await pumpManager(tester, 900);
    final name = tester.getRect(find.text('Reperibilità Domenica'));
    final time = tester.getRect(find.text('00:00 – 00:00'));
    expect(name.height, lessThan(24), reason: 'name must not wrap');
    expect((name.center.dy - time.center.dy).abs(), lessThan(6));
    expect(find.byType(Scrollbar), findsNothing);
  });

  testWidgets('time moves below the name when the line does not fit', (
    tester,
  ) async {
    await pumpManager(tester, 650);
    final name = tester.getRect(find.text('Reperibilità Domenica'));
    final time = tester.getRect(find.text('00:00 – 00:00'));
    expect(name.height, lessThan(24), reason: 'name must not wrap');
    expect(time.top, greaterThanOrEqualTo(name.bottom - 1));
    expect(find.byType(Scrollbar), findsNothing);
  });

  testWidgets('scrolls horizontally when even the name does not fit', (
    tester,
  ) async {
    await pumpManager(tester, 300);
    expect(find.byType(Scrollbar), findsOneWidget);
    final name = tester.getRect(find.text('Reperibilità Domenica'));
    expect(name.height, lessThan(24), reason: 'name must not wrap');

    // The copy icon is out of view until the user scrolls to the end.
    final copyFinder = find.byIcon(Icons.content_copy_outlined);
    expect(
      tester.getRect(copyFinder).right,
      greaterThan(tester.getRect(find.byType(ShiftProfileManager)).right),
    );
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(copyFinder).right,
      lessThanOrEqualTo(
        tester.getRect(find.byType(ShiftProfileManager)).right + 1,
      ),
    );
  });
}
