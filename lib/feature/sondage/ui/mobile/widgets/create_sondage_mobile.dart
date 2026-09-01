import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_prefill.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_form.dart';
import 'package:note_sondage/ui/widgets/navigation_bar.dart';

class CreateSondageMobile extends StatelessWidget {
  final String? sondageId;
  final VoidCallback? onsondageCreated;
  final SondageEntity? initialSondage;
  final bool enableTutorial;
  final SondageCreatePrefill? initialPrefill;

  const CreateSondageMobile({
    super.key,
    this.onsondageCreated,
    this.sondageId,
    this.initialSondage,
    this.enableTutorial = true,
    this.initialPrefill,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 2.0 + mobileNavBarBottomInset(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      child: SondageCreateForm(
        onCreated: onsondageCreated,
        showHeader: false,
        initialSondage: initialSondage,
        initialPrefill: initialPrefill,
        tutorialId: initialSondage == null && enableTutorial
            ? 'mobile-sondage-create'
            : null,
        onCloseRequested: () {
          if (!context.mounted) {
            return;
          }
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
        },
      ),
    );
  }
}
