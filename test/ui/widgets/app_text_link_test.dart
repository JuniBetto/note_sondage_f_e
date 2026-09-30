import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/ui/widgets/app_text_link.dart';

void main() {
  testWidgets('stays a transparent underlined link even with a filled theme', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          // Come il tema dell'app: TextButton con sfondo pieno.
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(backgroundColor: Colors.deepPurple),
          ),
        ),
        home: Scaffold(
          body: Center(
            child: AppTextLink(
              label: 'Forgot password',
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      Colors.transparent,
    );
    final text = tester.widget<Text>(find.text('Forgot password'));
    expect(text.style?.decoration, TextDecoration.underline);
    expect(
      tester.getSize(find.byType(TextButton)).height,
      greaterThanOrEqualTo(44),
    );

    await tester.tap(find.text('Forgot password'));
    expect(taps, 1);
  });
}
