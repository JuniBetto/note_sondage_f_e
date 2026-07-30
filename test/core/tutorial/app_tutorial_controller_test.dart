import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class _TutorialHarness extends StatefulWidget {
  const _TutorialHarness();

  @override
  State<_TutorialHarness> createState() => _TutorialHarnessState();
}

class _TutorialHarnessState extends State<_TutorialHarness> {
  final GlobalKey _targetKey = GlobalKey();
  late final ShowcaseView _showcaseView;

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register();
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Column(
              children: [
                Showcase(
                  key: _targetKey,
                  title: 'Tutorial title',
                  description: 'Tutorial description',
                  child: const SizedBox(
                    width: 120,
                    height: 48,
                    child: Text('Target'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppTutorialController.showIfNeeded(
                      context: context,
                      tutorialId: 'mobile-main-0',
                      userId: 'user-1',
                      keys: <GlobalKey>[_targetKey, _targetKey],
                    );
                  },
                  child: const Text('start'),
                ),
                TextButton(
                  onPressed: () {
                    AppTutorialController.replayRegistered(
                      context: context,
                      tutorialId: 'mobile-main-0',
                    );
                  },
                  child: const Text('replay'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 2),
  Duration step = const Duration(milliseconds: 50),
}) async {
  var elapsed = Duration.zero;
  while (finder.evaluate().isEmpty && elapsed < timeout) {
    await tester.pump(step);
    elapsed += step;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppTutorialController.resetForUser('user-1');
  });

  testWidgets(
    'showIfNeeded starts the tutorial and replayRegistered reopens it',
    (tester) async {
      await tester.pumpWidget(const _TutorialHarness());
      await tester.pump();

      await tester.tap(find.text('start'));
      await tester.pump();
      await _pumpUntilVisible(tester, find.text('Tutorial title'));

      expect(ShowcaseView.get().isShowcaseRunning, isTrue);
      expect(find.text('Tutorial title'), findsOneWidget);
      expect(find.text('Tutorial description'), findsOneWidget);

      expect(AppTutorialController.dismissActiveTutorialIfAny(), isTrue);
      await tester.pump();

      expect(ShowcaseView.get().isShowcaseRunning, isFalse);

      await tester.tap(find.text('replay'));
      await tester.pump();
      await _pumpUntilVisible(tester, find.text('Tutorial title'));

      expect(ShowcaseView.get().isShowcaseRunning, isTrue);
      expect(find.text('Tutorial title'), findsOneWidget);
      expect(find.text('Tutorial description'), findsOneWidget);
    },
  );
}
