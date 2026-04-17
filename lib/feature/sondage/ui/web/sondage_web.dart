import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/web/widgets/create_sondage_web.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/responsive_grid_sondages.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';

class SondageWeb extends StatefulWidget {
  const SondageWeb({super.key, this.title = "Create Sondage"});
  final String title;

  @override
  State<SondageWeb> createState() => _SondageWebState();
}

class _SondageWebState extends State<SondageWeb> {
  int isGridView = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.bgNavbarSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // ── Beautiful "Create Sondage" button ──
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        CustomDialog(
                          title: widget.title,
                          width: 700,
                          child: CreateSondageWeb(),
                        ).show(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.secondary,
                              colorScheme.secondary.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.secondary.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.poll_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${AppLocalizations.of(context)!.create} ${AppLocalizations.of(context)!.sondage}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Divider(height: 4, color: colorScheme.borderColor),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VisualType(
                    isActive1: isGridView == 1,
                    isActive2: isGridView == 2,
                    color: colorScheme.cursorColor,
                    iconData1: Icons.window_sharp,
                    iconData2: Icons.list,
                    onTap1: () {
                      setState(() {
                        isGridView = 1;
                      });
                    },
                    onTap2: () {
                      setState(() {
                        isGridView = 2;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.borderColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.bgNavbarSurface!,
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ResponsiveGridSondages(
                      items: sondagesList,
                      isRow: isGridView == 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
