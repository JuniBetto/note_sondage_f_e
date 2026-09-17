import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/ui/widgets/scroll_overflow_hint.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(height: 400, child: child)),
  );
}

// The chevrons are always present in the tree (AnimatedOpacity fades them),
// so `find.byIcon` alone can't tell "visible" from "hidden" — read the
// opacity instead.
double _opacityFor(WidgetTester tester, IconData icon) {
  final opacityFinder = find.ancestor(
    of: find.byIcon(icon),
    matching: find.byType(AnimatedOpacity),
  );
  return tester.widget<AnimatedOpacity>(opacityFinder).opacity;
}

void main() {
  testWidgets('shows bottom hint only, scrolled to top with overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ScrollOverflowHint(
          child: ListView(
            children: List.generate(
              20,
              (i) => SizedBox(height: 60, child: Text('item $i')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_opacityFor(tester, Icons.keyboard_arrow_up_rounded), 0);
    expect(_opacityFor(tester, Icons.keyboard_arrow_down_rounded), 1);
  });

  testWidgets('shows both hints when scrolled to the middle', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ScrollOverflowHint(
          child: ListView(
            children: List.generate(
              20,
              (i) => SizedBox(height: 60, child: Text('item $i')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(_opacityFor(tester, Icons.keyboard_arrow_up_rounded), 1);
    expect(_opacityFor(tester, Icons.keyboard_arrow_down_rounded), 1);
  });

  testWidgets(
    'bottom hint appears when content grows AFTER user scrolled to the old bottom',
    (tester) async {
      final controller = ScrollController();
      var itemCount = 5;
      late StateSetter setInnerState;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              setInnerState = setState;
              return ScrollOverflowHint(
                child: ListView(
                  controller: controller,
                  children: List.generate(
                    itemCount,
                    (i) => SizedBox(height: 60, child: Text('item $i')),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 5 items * 60 = 300, viewport 400 -> no overflow yet.
      expect(_opacityFor(tester, Icons.keyboard_arrow_down_rounded), 0);

      // Scroll to the (current) bottom, matching a user scrolling down.
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(_opacityFor(tester, Icons.keyboard_arrow_down_rounded), 0);

      // Now simulate async data arriving and growing the list — pixels stay
      // where they were (Flutter doesn't auto-scroll), but maxScrollExtent
      // grows, so there IS more content below now.
      setInnerState(() {
        itemCount = 20;
      });
      await tester.pumpAndSettle();

      expect(
        _opacityFor(tester, Icons.keyboard_arrow_down_rounded),
        1,
        reason: 'content grew below the current scroll position',
      );
    },
  );

  testWidgets(
    'hints reflect the real scroll position after the widget is rebuilt as a new instance mid-list',
    (tester) async {
      final controller = ScrollController();
      var loading = false;
      late StateSetter setInnerState;
      Widget buildContent() {
        return ListView(
          controller: controller,
          children: List.generate(
            20,
            (i) => SizedBox(height: 60, child: Text('item $i')),
          ),
        );
      }

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              setInnerState = setState;
              // Mirrors chat_mobile_team_list_page.dart's `_loading ? X : Y`
              // shape: a conditional ABOVE ScrollOverflowHint that could
              // change the tree shape and force a fresh State.
              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return ScrollOverflowHint(child: buildContent());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.jumpTo(200); // scroll into the middle, overflow both sides
      await tester.pumpAndSettle();
      expect(_opacityFor(tester, Icons.keyboard_arrow_down_rounded), 1);
      expect(_opacityFor(tester, Icons.keyboard_arrow_up_rounded), 1);

      // Simulate a refresh cycle that flips `_loading` true then false,
      // like `_loadTeams()` does around its network call, rebuilding
      // ScrollOverflowHint as a brand-new element/state.
      setInnerState(() => loading = true);
      await tester.pump();
      setInnerState(() => loading = false);
      await tester.pumpAndSettle();

      // A fresh (unkeyed) ScrollController resets to offset 0 when its
      // Scrollable is torn down and recreated — Flutter's own behavior, not
      // this widget's. So after the remount we're genuinely back at the
      // top: no "more above" hint, but still a "more below" hint since the
      // list has far more content than the 400px viewport.
      expect(controller.offset, 0);
      expect(_opacityFor(tester, Icons.keyboard_arrow_down_rounded), 1);
      expect(_opacityFor(tester, Icons.keyboard_arrow_up_rounded), 0);
    },
  );
}
