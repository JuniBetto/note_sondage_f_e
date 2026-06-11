import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';

class ShiftArchivedAssignmentsList extends StatelessWidget {
  const ShiftArchivedAssignmentsList({
    super.key,
    required this.assignments,
    required this.onRestore,
    required this.onOpen,
    this.compact = false,
  });

  final List<ShiftAssignmentEntity> assignments;
  final ValueChanged<ShiftAssignmentEntity> onRestore;
  final ValueChanged<ShiftAssignmentEntity> onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return const Center(child: Text('Nessun turno archiviato.'));
    }

    return ListView.separated(
      shrinkWrap: compact,
      physics: compact
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      itemCount: assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        final assignee = assignment.userName?.trim().isNotEmpty == true
            ? assignment.userName!
            : assignment.userId;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: assignment.displayColor.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: assignment.displayColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      assignment.profileName ?? 'Turno',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('dd/MM/yyyy').format(assignment.shiftDate)} • $assignee',
              ),
              const SizedBox(height: 4),
              Text(
                '${assignment.startTime.format(context)} - ${assignment.endTime.format(context)}',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onOpen(assignment),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Apri'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => onRestore(assignment),
                    icon: const Icon(Icons.unarchive_outlined),
                    label: const Text('Ripristina'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
