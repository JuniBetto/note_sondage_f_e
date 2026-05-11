import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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

  ({List<Widget> topItems, List<Widget> bottomItems}) _splitSidebarItems() {
    final spacerIndex = widget.listSidebarItem.indexWhere(
      (item) => item is Spacer,
    );

    if (spacerIndex == -1) {
      return (topItems: widget.listSidebarItem, bottomItems: const []);
    }

    return (
      topItems: widget.listSidebarItem.take(spacerIndex).toList(),
      bottomItems: widget.listSidebarItem.skip(spacerIndex + 1).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final sidebarItems = _splitSidebarItems();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.homeSecondary,
        borderRadius: BorderRadius.circular(4.0),
        border: Border(
          right: BorderSide(color: colorScheme.borderColor!, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Row(
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
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child:
                    widget.title ??
                    Row(
                      children: [
                        Expanded(
                          child: SvgPicture.asset(
                            'assets/images/logo3.svg',
                            width: 80,
                            height: 80,
                            color: colorScheme.selectItem,
                            colorFilter: ColorFilter.mode(
                              colorScheme.selectItem!,
                              BlendMode.srcIn,
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
            ),
            SliverList(
              delegate: SliverChildListDelegate(sidebarItems.topItems),
            ),
            if (sidebarItems.bottomItems.isNotEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    ...sidebarItems.bottomItems,
                  ],
                ),
              ),
            if (sidebarItems.bottomItems.isEmpty)
              const SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
