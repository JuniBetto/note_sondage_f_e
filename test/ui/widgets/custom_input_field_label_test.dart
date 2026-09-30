import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget field) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: field),
        ),
      ),
    );
  }

  testWidgets('shows the hint both as external label and as placeholder', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      CustomInputField(hintText: 'Email', controller: TextEditingController()),
    );

    // Label sopra il campo e placeholder dentro il campo.
    expect(find.text('Email'), findsNWidgets(2));
    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorator.decoration.hintText, 'Email');
    expect(
      tester.getTopLeft(find.text('Email').first).dy,
      lessThan(tester.getTopLeft(find.byType(TextFormField)).dy),
    );
    final node = tester.getSemantics(find.byType(TextFormField));
    expect(node.label.trim(), 'Email');
    expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
    semantics.dispose();
  });

  testWidgets('keeps an example hint when an explicit label is given', (
    tester,
  ) async {
    await pump(
      tester,
      CustomInputField(
        hintText: 'name@example.com',
        label: 'Email',
        controller: TextEditingController(),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorator.decoration.hintText, 'name@example.com');
  });

  testWidgets('search fields stay without external label', (tester) async {
    await pump(
      tester,
      CustomInputField(
        hintText: 'Search',
        isSearch: true,
        controller: TextEditingController(),
      ),
    );

    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorator.decoration.hintText, 'Search');
    expect(find.byType(MergeSemantics), findsNothing);
  });
}
