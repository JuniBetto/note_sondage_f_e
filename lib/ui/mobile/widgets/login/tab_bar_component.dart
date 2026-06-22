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
    this.childTab3,
  });
  final TabController tabController;
  final Widget? childTab1;
  final Widget? childTab2;
  final Widget? childTab3;
  final void Function(void Function()) setToUpdate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localization = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: tabController.animation ?? tabController,
      builder: (context, _) {
        final animationValue =
            tabController.animation?.value ?? tabController.index.toDouble();
        final tabs = <Widget>[
          childTab1 ??
              Text(
                localization.login,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
          childTab2 ??
              Text(
                localization.register,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
          if (childTab3 != null) childTab3!,
        ];
        final selectedIndex = animationValue.round().clamp(0, tabs.length - 1);

        return Container(
          height: 54,
          decoration: BoxDecoration(
            color: colorScheme.homeSecondary!,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / tabs.length;
              final indicatorLeft =
                  animationValue.clamp(0.0, tabs.length - 1.0) * tabWidth;

              return Stack(
                children: [
                  Positioned(
                    left: indicatorLeft,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ColorPalette.surface,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(tabs.length, (index) {
                      final legacyTabKey = switch (index) {
                        0 => const Key('login_tab'),
                        1 => const Key('register_tab'),
                        _ => Key('tab_bar_item_$index'),
                      };
                      return Expanded(
                        child: _TabBarPillItem(
                          key: legacyTabKey,
                          isSelected: selectedIndex == index,
                          label: tabs[index],
                          onTap: () => _animateTo(index),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _animateTo(int index) {
    if (tabController.index == index && !tabController.indexIsChanging) {
      return;
    }
    tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
    setToUpdate(() {});
  }
}

class _TabBarPillItem extends StatelessWidget {
  const _TabBarPillItem({
    super.key,
    required this.label,
    required this.onTap,
    required this.isSelected,
  });

  final Widget label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final selectedColor = ColorPalette.primary[6];
    final unselectedColor = Colors.grey[600];
    final baseTextStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: isSelected ? 1 : 0.92,
          child: DefaultTextStyle.merge(
            style: (baseTextStyle ?? const TextStyle()).copyWith(
              color: isSelected ? selectedColor : unselectedColor,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: isSelected ? selectedColor : unselectedColor,
              ),
              child: SizedBox.expand(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: FittedBox(fit: BoxFit.scaleDown, child: label),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
