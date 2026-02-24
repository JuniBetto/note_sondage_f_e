import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/button_clocking.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clockin_change_view.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clocking.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

class ClockingWeb extends StatelessWidget {
  const ClockingWeb({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<NavigationBloc>().add(NavigationPositionChanged(3));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        print(
          "ClockingWeb maxWidth: ${constraints.maxWidth}, isSmallScreen: $isSmallScreen",
        );
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 16.0,
                    ),
                    child: Text(
                      "Clock in/out web",
                      style: Theme.of(context).textTheme.headlineMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Divider(height: 4, color: colorScheme.avatarBg),
                  Text(
                    "Personal status clocking actions",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: colorScheme.textColor,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusClocking(isCompact: isSmallScreen),
                          ButtonClocking(),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 4, color: colorScheme.avatarBg),
                  SizedBox(height: 16.0),
                  StatusClockInChangeView(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
