import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';

class ShiftAutoPlanPreviewActionStyle {
  const ShiftAutoPlanPreviewActionStyle({
    required this.foreground,
    required this.background,
    required this.border,
    required this.badgeBackground,
  });

  final Color foreground;
  final Color background;
  final Color border;
  final Color badgeBackground;
}

ShiftAutoPlanPreviewActionStyle shiftAutoPlanPreviewActionStyle(
  ShiftAutoPlanPreviewAction action,
) {
  return switch (action) {
    ShiftAutoPlanPreviewAction.create => const ShiftAutoPlanPreviewActionStyle(
      foreground: Color(0xFF146C43),
      background: Color(0xFFE7F7EF),
      border: Color(0xFF9AD9B2),
      badgeBackground: Color(0xFFD3F0DF),
    ),
    ShiftAutoPlanPreviewAction.preserve =>
      const ShiftAutoPlanPreviewActionStyle(
        foreground: Color(0xFF245C9A),
        background: Color(0xFFEAF3FF),
        border: Color(0xFFB8D4FF),
        badgeBackground: Color(0xFFDCEAFF),
      ),
    ShiftAutoPlanPreviewAction.delete => const ShiftAutoPlanPreviewActionStyle(
      foreground: Color(0xFF9A2F2F),
      background: Color(0xFFFDEDED),
      border: Color(0xFFF5B6B6),
      badgeBackground: Color(0xFFFAD9D9),
    ),
  };
}

class ShiftAutoPlanPreviewActionPill extends StatelessWidget {
  const ShiftAutoPlanPreviewActionPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
