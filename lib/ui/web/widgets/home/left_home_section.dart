import 'package:flutter/material.dart';

import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/aspect_ratio.dart' as adaptive;
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

  Widget _buildAdaptiveLogo(BuildContext context) {
    final maxWidth = widget.isSmallScreen ? 112.0 : 208.0;

    return Align(
      alignment: widget.isSmallScreen ? Alignment.center : Alignment.center,
      child: SizedBox(
        width: maxWidth,
        child: adaptive.AspectRatio(
          aspectRatio: 1,
          borderRadius: BorderRadius.circular(widget.isSmallScreen ? 20 : 24),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
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
                    padding: const EdgeInsets.only(top: 4.0,bottom: 0.0, ),
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
                padding: const EdgeInsets.only(top: 4.0,bottom: 4.0),
                child:
                    widget.title ??
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildAdaptiveLogo(context)),
                        /* if (widget.isSmallScreen)
                          Expanded(
                            child: Text(
                              'TeamManagement',
                              style: textTheme.headlineLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.selectItem,
                              ),
                            ),
                          ),*/
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
