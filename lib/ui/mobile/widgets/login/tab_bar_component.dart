import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/color_palette.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class TabBarComponent extends StatelessWidget {
  const TabBarComponent({
    super.key,
    required this.tabController,
    required this.setToUpdate,
    this.childTab1,
    this.childTab2,
  });
  final TabController tabController;
  final Widget? childTab1;
  final Widget? childTab2;
  final void Function(void Function()) setToUpdate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localization = AppLocalizations.of(context)!;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.homeSecondary!, //Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                tabController.animateTo(0);
                setToUpdate(() {}); // Aggiorna immediatamente
              },
              child: Container(
                key: const Key('login_tab'),
                decoration: BoxDecoration(
                  color: tabController.index == 0
                      ? ColorPalette.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child:
                    childTab1 ??
                    Text(
                      localization.login,
                      style: TextStyle(
                        color: tabController.index == 0
                            ? ColorPalette.primary[6]
                            : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                tabController.animateTo(1);
                setToUpdate(() {}); // Aggiorna immediatamente
              },
              child: Container(
                key: const Key('register_tab'),
                decoration: BoxDecoration(
                  color: tabController.index == 1
                      ? ColorPalette.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child:
                    childTab2 ??
                    Text(
                      localization.register,
                      style: TextStyle(
                        color: tabController.index == 1
                            ? ColorPalette.primary[6]
                            : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
