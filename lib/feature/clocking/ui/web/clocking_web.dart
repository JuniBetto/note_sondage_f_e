import 'package:flutter/material.dart';
import 'package:note_sondage/feature/clocking/ui/web/clocking_web_skeleton.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/button_clocking.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clockin_change_view.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clocking.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ClockingWeb extends StatefulWidget {
  const ClockingWeb({super.key});

  @override
  State<ClockingWeb> createState() => _ClockingWebState();
}

class _ClockingWebState extends State<ClockingWeb> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Carica i dati dopo il primo frame per mostrare subito lo skeleton
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Qui caricherai i dati dal tuo bloc/repository
    // Per ora simuliamo un breve delay per il caricamento
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostra skeleton durante il caricamento
    if (_isLoading) {
      return const ClockingWebSkeleton();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        // Rimosso print() per evitare rallentamenti
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
    );
  }
}
