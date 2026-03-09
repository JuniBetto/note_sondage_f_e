import 'package:flutter/material.dart';
import 'package:note_sondage/feature/clocking/ui/web/clocking_web_skeleton.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/button_clocking.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clockin_change_view.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clocking.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/skeleton_wrapper.dart';

/// ClockingWeb con supporto skeleton loading.
///
/// Usa [isLoading] per mostrare lo skeleton durante il caricamento dei dati.
class ClockingWebWithSkeleton extends StatefulWidget {
  const ClockingWebWithSkeleton({super.key});

  @override
  State<ClockingWebWithSkeleton> createState() =>
      _ClockingWebWithSkeletonState();
}

class _ClockingWebWithSkeletonState extends State<ClockingWebWithSkeleton> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simula il caricamento dei dati
    // In produzione, qui caricheresti i dati dal tuo bloc/repository
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Metodo 1: Usa SkeletonWrapper con skeleton personalizzato
    return SkeletonWrapper(
      isLoading: _isLoading,
      skeleton: const ClockingWebSkeleton(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 4.0,
            ),
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
                        style: theme.textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Divider(height: 4, color: colorScheme.avatarBg),
                    Text(
                      "Personal status clocking actions",
                      style: theme.textTheme.bodyMedium!.copyWith(
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
                            const ButtonClocking(),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 4, color: colorScheme.avatarBg),
                    const SizedBox(height: 16.0),
                    const StatusClockInChangeView(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Esempio di come usare skeleton con BlocBuilder
///
/// ```dart
/// BlocBuilder<ClockingBloc, ClockingState>(
///   builder: (context, state) {
///     return SkeletonWrapper(
///       isLoading: state is ClockingLoading,
///       skeleton: const ClockingWebSkeleton(),
///       child: ClockingWebContent(data: state.data),
///     );
///   },
/// )
/// ```
