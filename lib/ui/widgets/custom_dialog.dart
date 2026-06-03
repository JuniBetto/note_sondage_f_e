import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class CustomDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const CustomDialog({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.actions,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.showCloseButton = true,
    this.onClose,
  }) : assert(
         title == null || titleWidget == null,
         'Non usare sia title che titleWidget insieme',
       );

  Future<T?> show<T>(BuildContext context) {
    return showDialog<T>(context: context, builder: (context) => this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: backgroundColor ?? colorScheme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width ?? 500,
          maxHeight: height ?? mediaSize.height * 0.88,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null || titleWidget != null || showCloseButton)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child:
                            titleWidget ??
                            (title != null
                                ? Text(
                                    title!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const SizedBox.shrink()),
                      ),
                      if (showCloseButton)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            if (onClose != null) {
                              onClose!();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 24,
                        ),
                    ],
                  ),
                ),
              Flexible(child: SingleChildScrollView(child: child)),
              if (actions != null && actions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!
                        .map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: action,
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
