import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_slide_transition.dart';

const _listKey = ValueKey<String>('list');

Widget _list() => const SizedBox.expand(key: _listKey, child: Text('list'));
Widget _conversation([String label = 'conversation']) =>
    SizedBox.expand(key: chatConversationSlideKey, child: Text(label));

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: SizedBox(width: 400, height: 600, child: ChatSlideSwitcher(child: child)),
    ),
  ),
);

double _left(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder).dx;

void main() {
  testWidgets('opening a conversation slides it in from the right and the list out to the left', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_list()));
    final origin = _left(tester, find.text('list'));

    await tester.pumpWidget(_host(_conversation()));
    await tester.pump(chatSlideDuration ~/ 2);

    expect(_left(tester, find.text('conversation')), greaterThan(origin));
    expect(_left(tester, find.text('list')), lessThan(origin));

    await tester.pumpAndSettle();
    expect(find.text('list'), findsNothing);
    expect(_left(tester, find.text('conversation')), origin);
  });

  testWidgets('going back slides the conversation out to the right and the list in from the left', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_conversation()));
    final origin = _left(tester, find.text('conversation'));

    await tester.pumpWidget(_host(_list()));
    await tester.pump(chatSlideDuration ~/ 2);

    expect(_left(tester, find.text('conversation')), greaterThan(origin));
    expect(_left(tester, find.text('list')), lessThan(origin));

    await tester.pumpAndSettle();
    expect(find.text('conversation'), findsNothing);
    expect(_left(tester, find.text('list')), origin);
  });

  testWidgets('switching straight between conversations updates in place without sliding', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_conversation('first')));
    final origin = _left(tester, find.text('first'));

    await tester.pumpWidget(_host(_conversation('second')));
    await tester.pump(chatSlideDuration ~/ 2);

    expect(find.text('first'), findsNothing);
    expect(_left(tester, find.text('second')), origin);
  });

  testWidgets('reduced-motion setting swaps instantly', (tester) async {
    await tester.pumpWidget(_host(_list(), disableAnimations: true));
    await tester.pumpWidget(_host(_conversation(), disableAnimations: true));
    await tester.pump();

    expect(find.text('list'), findsNothing);
    expect(_left(tester, find.text('conversation')), 0);
  });

  testWidgets('keeps the parent tight constraints while animating', (tester) async {
    await tester.pumpWidget(_host(_list()));
    await tester.pumpWidget(_host(_conversation()));
    await tester.pump(chatSlideDuration ~/ 2);

    expect(tester.getSize(find.byKey(chatConversationSlideKey)), const Size(400, 600));
    expect(tester.getSize(find.byKey(_listKey)), const Size(400, 600));
  });

  group('mobile route', () {
    GoRouter buildRouter() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/chat', extra: chatSlideRouteExtra),
              child: const Text('open-slide'),
            ),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) {
            const page = Scaffold(body: Text('conversation-page'));
            return state.extra == chatSlideRouteExtra
                ? chatSlideRoutePage(state: state, child: page)
                : const NoTransitionPage<void>(child: page);
          },
        ),
      ],
    );

    testWidgets('push with the slide extra animates in from the right and pops back out', (tester) async {
      final router = buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('open-slide'));
      await tester.pump();
      await tester.pump(chatSlideDuration ~/ 2);
      final mid = tester.getTopLeft(find.text('conversation-page')).dx;
      expect(mid, greaterThan(0));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('conversation-page')).dx, 0);

      router.pop();
      await tester.pump();
      await tester.pump(chatSlideDuration ~/ 2);
      expect(tester.getTopLeft(find.text('conversation-page')).dx, greaterThan(0));
      await tester.pumpAndSettle();
      expect(find.text('conversation-page'), findsNothing);
    });

    testWidgets('opening without the extra shows the page immediately', (tester) async {
      final router = buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.push('/chat');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(find.text('conversation-page')).dx, 0);
    });
  });
}
