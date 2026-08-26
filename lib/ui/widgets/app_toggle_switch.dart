import 'package:flutter/material.dart';

/// The two brand colors every toggle switch in the app must use.
const Color kAppToggleActiveColor = Color(0xFF5A31D1);
const Color kAppToggleInactiveColor = Color(0xFFE4DFF3);

/// The single toggle-switch control used everywhere in the app, so every
/// on/off control shares the same look: #5A31D1 when on, #E4DFF3 when off.
class AppToggleSwitch extends StatelessWidget {
  const AppToggleSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      inactiveThumbColor: Colors.white,
      activeTrackColor: kAppToggleActiveColor,
      inactiveTrackColor: kAppToggleInactiveColor,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

/// A [SwitchListTile]-equivalent row (leading icon + title/subtitle + toggle,
/// whole row tappable) built on [AppToggleSwitch], for the settings/form rows
/// that used to render their own [SwitchListTile] with per-screen colors.
class AppSwitchListTile extends StatelessWidget {
  const AppSwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.secondary,
    this.contentPadding,
    this.dense = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final EdgeInsetsGeometry? contentPadding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onChanged != null;
    final horizontalGap = dense ? 8.0 : 16.0;

    return InkWell(
      onTap: enabled ? () => onChanged!(!value) : null,
      child: Padding(
        padding:
            contentPadding ??
            EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 4 : 8),
        child: Row(
          children: [
            if (secondary != null) ...[
              IconTheme.merge(
                data: IconThemeData(
                  color: enabled ? null : theme.disabledColor,
                ),
                child: secondary!,
              ),
              SizedBox(width: horizontalGap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      color: enabled ? null : theme.disabledColor,
                    ),
                    child: title,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: DefaultTextStyle.merge(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        child: subtitle!,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: horizontalGap),
            AppToggleSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
