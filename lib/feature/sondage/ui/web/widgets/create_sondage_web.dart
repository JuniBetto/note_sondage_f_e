import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_prefill.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_form.dart';

class CreateSondageWeb extends StatelessWidget {
  final String? sondageId;
  final VoidCallback? onsondageCreated;
  final SondageEntity? initialSondage;
  final SondageCreatePrefill? initialPrefill;

  const CreateSondageWeb({
    super.key,
    this.sondageId,
    this.onsondageCreated,
    this.initialSondage,
    this.initialPrefill,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SondageCreateForm(
            onCreated: onsondageCreated,
            initialPrefill: initialPrefill,
            tutorialId: initialSondage == null ? 'web-sondage-create' : null,
            onCloseRequested: () {
              if (!context.mounted) {
                return;
              }
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              }
            },
            initialSondage: initialSondage,
          ),
        ),
      ),
    );
  }
}
