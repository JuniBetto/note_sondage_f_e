import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_form.dart';

class CreateSondageMobile extends StatelessWidget {
  final String? sondageId;
  final VoidCallback? onsondageCreated;
  final SondageEntity? initialSondage;

  const CreateSondageMobile({
    super.key,
    this.onsondageCreated,
    this.sondageId,
    this.initialSondage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: SondageCreateForm(
        onCreated: onsondageCreated,
        showHeader: false,
        initialSondage: initialSondage,
        onCloseRequested: () {
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).maybePop();
        },
      ),
    );
  }
}
