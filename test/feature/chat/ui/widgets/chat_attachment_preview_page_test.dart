import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_attachment_preview_page.dart';
import 'package:note_sondage/feature/chat/ui/widgets/chat_draft_attachment.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

void main() {
  const pdf = ChatDraftAttachment(
    bytes: [1, 2, 3],
    fileName: 'contratto.pdf',
    contentType: 'application/pdf',
    sizeBytes: 3,
  );
  const docx = ChatDraftAttachment(
    bytes: [4, 5],
    fileName: 'note.docx',
    contentType: 'application/msword',
    sizeBytes: 2,
  );

  testWidgets('shows caption hint, count badge and sends captions in order', (
    tester,
  ) async {
    List<ChatAttachmentSendItem>? sent;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              sent = await ChatAttachmentPreviewPage.show(
                context,
                attachments: const [pdf, docx],
                accentColor: Colors.green,
                initialCaption: 'dal composer',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('dal composer'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(sent, isNotNull);
    expect(sent!.map((item) => item.attachment.fileName), [
      'contratto.pdf',
      'note.docx',
    ]);
    expect(sent!.map((item) => item.caption), ['dal composer', '']);
  });

  testWidgets('removing the only attachment closes without sending', (
    tester,
  ) async {
    var closed = false;
    List<ChatAttachmentSendItem>? sent;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              sent = await ChatAttachmentPreviewPage.show(
                context,
                attachments: const [pdf],
                accentColor: Colors.green,
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Aggiungi una didascalia'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(ChatAttachmentPreviewPage), findsNothing);
    expect(closed, isTrue);
    expect(sent, isNull);
  });
}
