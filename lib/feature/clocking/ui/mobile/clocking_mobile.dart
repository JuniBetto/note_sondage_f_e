import 'package:flutter/material.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/button_clocking.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clockin_change_view.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clocking.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ClockingMobile extends StatelessWidget {
  const ClockingMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Personal status clocking actions",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: colorScheme.textColor,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(height: 4, color: colorScheme.avatarBg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [Expanded(child: StatusClocking(isCompact: false))],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
              child: ButtonClocking(),
            ),
            Divider(height: 4, color: colorScheme.avatarBg),
            SizedBox(height: 16.0),
            StatusClockInChangeView(isMobile: true),
          ],
        ),
      ),
    );
  }
}
