import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> items;
  final Color color;
  final void Function()? onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.items,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    AppLocalizations localizations = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: color.withValues(alpha: 0.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                    right: 12.0,
                    bottom: 16.0,
                    top: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with colored bar
                      Row(
                        children: [
                          Text(
                            title,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Description
                      Text(description, style: textTheme.bodyLarge!),

                      SizedBox(height: 20),
                      _manageItem(items, color, textTheme.bodyLarge!),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 12.0,
                  bottom: 8.0,
                  top: 16.0,
                ),
                child: CustomAppButton(
                  onPressed: () {},
                  isActive: true,
                  iconCard: iconCardWidget(
                    Icons.arrow_forward,
                    Theme.of(context).colorScheme.onSurface,
                  ),
                  type: ButtonType.card,
                  child: Text(
                    localizations.explorer,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _manageItem(List<String> items, Color color, TextStyle textStyle) {
  return Wrap(
    runSpacing: 3.0,
    spacing: 8.0,
    children: items.map((item) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          child: Text(item, style: textStyle, softWrap: true),
        ),
      );
    }).toList(),
  );
}

Widget iconCardWidget(IconData iconData, Color? color) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: color?.withValues(alpha: 0.15) ?? Colors.white60,
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Icon(Icons.arrow_forward, color: color ?? Colors.black),
    ),
  );
}
