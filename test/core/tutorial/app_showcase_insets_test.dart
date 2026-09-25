import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';

const _navigationBarInset = 48.0;

class _Harness extends StatefulWidget {
  const _Harness({required this.useAppShowcase});
  final bool useAppShowcase;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final GlobalKey _key = GlobalKey();
  late final ShowcaseView _view;

  @override
  void initState() {
    super.initState();
    _view = ShowcaseView.register(
      globalTooltipActions: [
        TooltipActionButton(type: TooltipDefaultActionType.skip, name: 'Skip'),
        TooltipActionButton(type: TooltipDefaultActionType.previous, name: 'Back'),
        TooltipActionButton(type: TooltipDefaultActionType.next, name: 'Next'),
      ],
      globalTooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.spaceBetween,
        position: TooltipActionPosition.inside,
      ),
    );
  }

  @override
  void dispose() {
    _view.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const target = SizedBox(width: 200, height: 48, child: Text('Target'));
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Stack(
            children: [
              // Target sits near the bottom edge, so the tooltip is pushed
              // against it — the case that hid the buttons on device.
              Positioned(
                left: 20,
                right: 20,
                bottom: 150,
                child: widget.useAppShowcase
                    ? appShowcase(key: _key, title: 'Title', description: 'Description', tooltipPosition: TooltipPosition.bottom, child: target)
                    : Showcase(key: _key, title: 'Title', description: 'Description', tooltipPosition: TooltipPosition.bottom, child: target),
              ),
              Positioned(
                top: 0,
                child: TextButton(
                  onPressed: () => _view.startShowCase([_key]),
                  child: const Text('start'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<double> _lowestButtonBottom(WidgetTester tester, {required bool useAppShowcase}) async {
  tester.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1
    ..viewPadding = const FakeViewPadding(bottom: _navigationBarInset)
    ..padding = const FakeViewPadding(bottom: _navigationBarInset);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_Harness(useAppShowcase: useAppShowcase));
  await tester.tap(find.text('start'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));

  return ['Skip', 'Back', 'Next']
      .map((label) => tester.getBottomLeft(find.text(label)).dy)
      .reduce((a, b) => a > b ? a : b);
}

void main() {
  testWidgets('tooltip buttons stay above the system navigation bar', (tester) async {
    final bottom = await _lowestButtonBottom(tester, useAppShowcase: true);
    expect(bottom, lessThanOrEqualTo(800 - _navigationBarInset));
  });

  testWidgets('control: the plain package Showcase lets them reach under it', (tester) async {
    final bottom = await _lowestButtonBottom(tester, useAppShowcase: false);
    expect(bottom, greaterThan(800 - _navigationBarInset));
  });
}
