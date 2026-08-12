import 'package:flutter/material.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';

enum ShiftAbsenceType { vacation, permission, sick }

class ShiftAbsenceStatus {
  const ShiftAbsenceStatus({
    required this.userId,
    required this.date,
    required this.type,
    this.teamId,
    this.note,
  });

  final String userId;
  final DateTime date;
  final ShiftAbsenceType type;
  final String? teamId;
  final String? note;

  bool get isFullDay => type != ShiftAbsenceType.permission;

  int get priority => switch (type) {
    ShiftAbsenceType.sick => 3,
    ShiftAbsenceType.vacation => 2,
    ShiftAbsenceType.permission => 1,
  };

  String label(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode.toLowerCase()) {
      case 'it':
        return switch (type) {
          ShiftAbsenceType.vacation => 'Ferie',
          ShiftAbsenceType.permission => 'Permesso',
          ShiftAbsenceType.sick => 'Malattia',
        };
      case 'fr':
        return switch (type) {
          ShiftAbsenceType.vacation => 'Conge',
          ShiftAbsenceType.permission => 'Autorisation',
          ShiftAbsenceType.sick => 'Maladie',
        };
      case 'es':
        return switch (type) {
          ShiftAbsenceType.vacation => 'Vacaciones',
          ShiftAbsenceType.permission => 'Permiso',
          ShiftAbsenceType.sick => 'Baja medica',
        };
      default:
        return switch (type) {
          ShiftAbsenceType.vacation => 'Vacation',
          ShiftAbsenceType.permission => 'Permission',
          ShiftAbsenceType.sick => 'Sick',
        };
    }
  }

  String compactLabel(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode.toLowerCase()) {
      case 'it':
        return switch (type) {
          ShiftAbsenceType.vacation => 'Ferie',
          ShiftAbsenceType.permission => 'Perm.',
          ShiftAbsenceType.sick => 'Mal.',
        };
      case 'fr':
        return switch (type) {
          ShiftAbsenceType.vacation => 'Conge',
          ShiftAbsenceType.permission => 'Autor.',
          ShiftAbsenceType.sick => 'Mal.',
        };
      case 'es':
        return switch (type) {
          ShiftAbsenceType.vacation => 'Vac.',
          ShiftAbsenceType.permission => 'Perm.',
          ShiftAbsenceType.sick => 'Baja',
        };
      default:
        return switch (type) {
          ShiftAbsenceType.vacation => 'Vacation',
          ShiftAbsenceType.permission => 'Perm.',
          ShiftAbsenceType.sick => 'Sick',
        };
    }
  }

  Color color() {
    return switch (type) {
      ShiftAbsenceType.vacation => Colors.teal,
      ShiftAbsenceType.permission => Colors.indigo,
      ShiftAbsenceType.sick => Colors.redAccent,
    };
  }

  static ShiftAbsenceStatus? fromClockingRecord(ClockingRecordEntity record) {
    final type = switch (record.status) {
      ClockingStatus.vacation => ShiftAbsenceType.vacation,
      ClockingStatus.permission => ShiftAbsenceType.permission,
      ClockingStatus.sick => ShiftAbsenceType.sick,
      _ => null,
    };
    if (type == null) {
      return null;
    }
    return ShiftAbsenceStatus(
      userId: record.userId.trim(),
      teamId: record.teamId?.trim(),
      date: DateTime(record.date.year, record.date.month, record.date.day),
      type: type,
      note: record.note?.trim(),
    );
  }
}

String shiftAbsenceStatusKey(DateTime date, String userId) {
  final normalized = DateTime(date.year, date.month, date.day);
  return '${normalized.year}-${normalized.month}-${normalized.day}|${userId.trim()}';
}

Map<String, ShiftAbsenceStatus> buildShiftAbsenceIndex(
  Iterable<ClockingRecordEntity> records, {
  required DateTime from,
  required DateTime to,
  String? teamId,
  String? currentUserId,
}) {
  final normalizedFrom = DateTime(from.year, from.month, from.day);
  final normalizedTo = DateTime(to.year, to.month, to.day);
  final normalizedTeamId = teamId?.trim();
  final normalizedCurrentUserId = currentUserId?.trim();
  final index = <String, ShiftAbsenceStatus>{};

  for (final record in records) {
    final status = ShiftAbsenceStatus.fromClockingRecord(record);
    if (status == null) {
      continue;
    }
    if (status.userId.isEmpty) {
      continue;
    }

    final normalizedDate = DateTime(
      status.date.year,
      status.date.month,
      status.date.day,
    );
    if (normalizedDate.isBefore(normalizedFrom) ||
        normalizedDate.isAfter(normalizedTo)) {
      continue;
    }

    if (normalizedTeamId != null && normalizedTeamId.isNotEmpty) {
      if ((status.teamId ?? '').trim() != normalizedTeamId) {
        continue;
      }
    } else if (normalizedCurrentUserId != null &&
        normalizedCurrentUserId.isNotEmpty &&
        status.userId != normalizedCurrentUserId) {
      continue;
    }

    final key = shiftAbsenceStatusKey(normalizedDate, status.userId);
    final existing = index[key];
    if (existing == null || status.priority > existing.priority) {
      index[key] = status;
    }
  }

  return index;
}

Map<String, ShiftAbsenceStatus> shiftAbsenceStatusesByUserForDate(
  Map<String, ShiftAbsenceStatus> index,
  DateTime date,
) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final result = <String, ShiftAbsenceStatus>{};
  for (final status in index.values) {
    if (status.date.year == normalizedDate.year &&
        status.date.month == normalizedDate.month &&
        status.date.day == normalizedDate.day) {
      result[status.userId] = status;
    }
  }
  return result;
}
