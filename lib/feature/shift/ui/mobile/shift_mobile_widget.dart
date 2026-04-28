import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/shift/ui/bloc/shift_bloc.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_widget.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_day_dialog.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// Mobile widget embedded inside the clocking section (or standalone).
class ShiftMobileWidget extends StatefulWidget {
  const ShiftMobileWidget({super.key});

  @override
  State<ShiftMobileWidget> createState() => _ShiftMobileWidgetState();
}

class _ShiftMobileWidgetState extends State<ShiftMobileWidget> {
  DateTime _focusedMonth = DateTime.now();
  List<ShiftAssignmentEntity> _assignments = [];
  List<ShiftProfileEntity> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadAssignments();
  }

  void _loadProfiles() {
    context.read<ShiftBloc>().add(LoadShiftProfilesEvent());
  }

  void _loadAssignments() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    context.read<ShiftBloc>().add(
      LoadShiftAssignmentsEvent(from: first, to: last),
    );
  }

  void _onMonthChanged(DateTime month) {
    setState(() => _focusedMonth = month);
    _loadAssignments();
  }

  Future<void> _onDayTap(DateTime date, ShiftAssignmentEntity? existing) async {
    final result = await showShiftDayDialog(
      context: context,
      date: date,
      profiles: _profiles,
      existing: existing,
    );
    if (result == null) return;

    if (result.deleted && existing != null) {
      context.read<ShiftBloc>().add(DeleteShiftAssignmentEvent(existing.id));
    } else if (existing != null) {
      context.read<ShiftBloc>().add(
        UpdateShiftAssignmentEvent(
          assignmentId: existing.id,
          profileId: result.profileId,
          startTime: result.startTime,
          endTime: result.endTime,
          overnight: result.overnight,
          note: result.note,
          alarmOffsets: result.alarmOffsets,
        ),
      );
    } else {
      context.read<ShiftBloc>().add(
        AssignShiftEvent(
          shiftDate: date,
          profileId: result.profileId,
          startTime: result.startTime,
          endTime: result.endTime,
          overnight: result.overnight,
          note: result.note,
          alarmOffsets: result.alarmOffsets,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<ShiftBloc, ShiftState>(
      listener: (context, state) {
        if (state is ShiftProfilesLoaded) {
          setState(() => _profiles = state.profiles);
        }
        if (state is ShiftAssignmentsLoaded) {
          setState(() => _assignments = state.assignments);
        }
        if (state is ShiftAssigned ||
            state is ShiftAssignmentUpdated ||
            state is ShiftAssignmentDeleted) {
          _loadAssignments();
        }
        if (state is ShiftError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: colorScheme.descriptionColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.myShifts,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ShiftCalendarWidget(
              assignments: _assignments,
              focusedMonth: _focusedMonth,
              onMonthChanged: _onMonthChanged,
              onDayTap: _onDayTap,
            ),
          ],
        ),
      ),
    );
  }
}
