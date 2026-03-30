import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class VisualType extends StatelessWidget {
  final IconData? iconData1;
  final IconData? iconData2;
  final double? size;
  final Color? background;
  final Color? color;
  final bool? isActive1;
  final bool? isActive2;
  final VoidCallback? onTap1;
  final VoidCallback? onTap2;

  const VisualType({
    super.key,
    this.iconData1,
    this.iconData2,
    this.size,
    this.color,
    this.onTap1,
    this.onTap2,
    this.background,
    this.isActive1,
    this.isActive2,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? colorScheme.homeSecondary!,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            GestureDetector(
              onTap: onTap1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive1 == true
                        ? color?.withValues(alpha: 0.3) ?? Colors.transparent
                        : Colors.grey[600]!,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    iconData1 ?? Icons.edit,
                    size: size ?? 28,
                    color: isActive1 == true
                        ? color ?? Colors.blue[600]
                        : Colors.grey[600]!,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onTap2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive2 == true
                        ? color?.withValues(alpha: 0.3) ?? Colors.transparent
                        : Colors.grey[600]!,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    iconData2 ?? Icons.delete_forever_outlined,
                    size: size ?? 28,
                    color: isActive2 == true
                        ? color ?? Colors.red[600]
                        : Colors.grey[600]!,
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
