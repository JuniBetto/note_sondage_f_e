import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/web/widgets/sidebar_item.dart';

class LeftHomeSection extends StatefulWidget {
  const LeftHomeSection({
    super.key,
    this.isSmallScreen = false,
    this.onPressedResizeSidebar,
    required this.listSidebarItem,
    this.title,
  });
  final bool isSmallScreen;
  final Widget? title;
  final void Function()? onPressedResizeSidebar;
  final List<Widget> listSidebarItem;
  @override
  State<LeftHomeSection> createState() => _LeftHomeSectionState();
}

class _LeftHomeSectionState extends State<LeftHomeSection> {
  /* void _handleResizeSidebar() {
    if (widget.onPressedResizeSidebar != null) {
      widget.onPressedResizeSidebar!();
    }
  }*/

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.bgColorNew,
        borderRadius: BorderRadius.circular(4.0),
        border: Border(
          right: BorderSide(color: colorScheme.borderColor!, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: IconButton(
                    onPressed: widget.onPressedResizeSidebar,
                    icon: Icon(
                      widget.isSmallScreen
                          ? Icons.door_back_door
                          : Icons.door_front_door,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child:
                  widget.title ??
                  Row(
                    children: [
                      Expanded(
                        child: SvgPicture.asset(
                          'assets/images/logo3.svg',
                          width: 80, // imposta la dimensione che preferisci
                          height: 80,
                          color: colorScheme.selectItem,
                          colorFilter: ColorFilter.mode(
                            colorScheme.selectItem!,
                            BlendMode
                                .srcIn, // Questo modalità cambierà il colore
                          ),
                        ),
                      ),
                      if (widget.isSmallScreen)
                        Expanded(
                          child: Text(
                            "Manage",
                            style: textTheme.headlineLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.selectItem,
                            ),
                          ),
                        ),
                    ],
                  ),
            ),

            ...widget.listSidebarItem,

            /*   SidebarItem(
              key: ValueKey(0),
              icon: Icons.home_outlined,
              label: localizations.home,
              index: 0,
              isSmallScreen: widget.isSmallScreen,
              lastIndexes: lastIndexes,
            ),
            SidebarItem(
              key: ValueKey(1),
              icon: Icons.group,
              label: localizations.team,
              index: 1,
              isSmallScreen: widget.isSmallScreen,
              lastIndexes: lastIndexes,
            ),
            /* Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Tools :",
                style: textTheme.headlineSmall!.copyWith(
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.solid,
                  decorationThickness: 4.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),*/
            SidebarItem(
              key: ValueKey(3),
              icon: Icons.timer,
              label: localizations.clockingInOut,
              index: 3,
              isSmallScreen: widget.isSmallScreen,
              lastIndexes: lastIndexes,
            ),
            SidebarItem(
              key: ValueKey(4),
              icon: Icons.checklist,
              label: localizations.sondage,
              isSmallScreen: widget.isSmallScreen,
              index: 4,
              lastIndexes: lastIndexes,
            ),
            const Spacer(),
            Divider(),
            SidebarItem(
              key: ValueKey(2),
              icon: Icons.settings,
              label: localizations.settings,
              index: 2,
              isSmallScreen: widget.isSmallScreen,
              lastIndexes: lastIndexes,
            ),*/
          ],
        ),
      ),
    );
  }
}
