/// Stato di un record di clocking
enum ClockingStatus {
  clockedIn,
  onBreak,
  committed,
  decommitted,
  vacation,
  permission,
  absent,
  late;

  factory ClockingStatus.fromString(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'CLOCKED_IN':
      case 'clockedIn':
        return ClockingStatus.clockedIn;
      case 'ON_BREAK':
      case 'onBreak':
        return ClockingStatus.onBreak;
      case 'COMMITTED':
      case 'committed':
      case 'clockedOut':
        return ClockingStatus.committed;
      case 'DECOMMITTED':
      case 'decommitted':
        return ClockingStatus.decommitted;
      case 'VACATION':
      case 'vacation':
        return ClockingStatus.vacation;
      case 'PERMISSION':
      case 'permission':
        return ClockingStatus.permission;
    }

    return ClockingStatus.values.firstWhere(
      (s) => s.name == normalized.toLowerCase(),
      orElse: () => ClockingStatus.absent,
    );
  }
}

/// Entita singolo record di clock-in/out
class ClockingRecordEntity {
  final String id;
  final String userId;
  final String userName;
  final String teamName;
  final String? teamId;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final Duration? timeWorked;
  final ClockingStatus status;
  final DateTime date;
  final String? note;
  final int? totalBreakMinutes;
  final DateTime? currentBreakStartedAt;
  final DateTime? lastBreakStartedAt;
  final DateTime? lastBreakEndedAt;
  final DateTime? committedAt;
  final DateTime? decommittedAt;
  final bool ownerEditable;
  final bool canDecommit;
  final bool canCommit;

  const ClockingRecordEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.teamName,
    this.teamId,
    this.clockInTime,
    this.clockOutTime,
    this.timeWorked,
    required this.status,
    required this.date,
    this.note,
    this.totalBreakMinutes,
    this.currentBreakStartedAt,
    this.lastBreakStartedAt,
    this.lastBreakEndedAt,
    this.committedAt,
    this.decommittedAt,
    this.ownerEditable = false,
    this.canDecommit = false,
    this.canCommit = false,
  });

  ClockingRecordEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    String? teamName,
    String? teamId,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    Duration? timeWorked,
    ClockingStatus? status,
    DateTime? date,
    String? note,
    int? totalBreakMinutes,
    DateTime? currentBreakStartedAt,
    DateTime? lastBreakStartedAt,
    DateTime? lastBreakEndedAt,
    DateTime? committedAt,
    DateTime? decommittedAt,
    bool? ownerEditable,
    bool? canDecommit,
    bool? canCommit,
  }) {
    return ClockingRecordEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      teamName: teamName ?? this.teamName,
      teamId: teamId ?? this.teamId,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      timeWorked: timeWorked ?? this.timeWorked,
      status: status ?? this.status,
      date: date ?? this.date,
      note: note ?? this.note,
      totalBreakMinutes: totalBreakMinutes ?? this.totalBreakMinutes,
      currentBreakStartedAt:
          currentBreakStartedAt ?? this.currentBreakStartedAt,
      lastBreakStartedAt: lastBreakStartedAt ?? this.lastBreakStartedAt,
      lastBreakEndedAt: lastBreakEndedAt ?? this.lastBreakEndedAt,
      committedAt: committedAt ?? this.committedAt,
      decommittedAt: decommittedAt ?? this.decommittedAt,
      ownerEditable: ownerEditable ?? this.ownerEditable,
      canDecommit: canDecommit ?? this.canDecommit,
      canCommit: canCommit ?? this.canCommit,
    );
  }

  bool get isActive =>
      clockOutTime == null &&
      (status == ClockingStatus.clockedIn || status == ClockingStatus.onBreak);

  bool get isOnBreak => status == ClockingStatus.onBreak;

  bool get isCommitted => status == ClockingStatus.committed;

  bool get isDecommitted => status == ClockingStatus.decommitted;

  bool get isVacation => status == ClockingStatus.vacation;

  bool get isPermission => status == ClockingStatus.permission;

  String get clockInFormatted {
    if (isVacation) return '--:--';
    if (clockInTime == null) return '--:--';
    final h = clockInTime!.hour.toString().padLeft(2, '0');
    final m = clockInTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get clockOutFormatted {
    if (isVacation) return '--:--';
    if (clockOutTime == null) return '--:--';
    final h = clockOutTime!.hour.toString().padLeft(2, '0');
    final m = clockOutTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get timeWorkedFormatted {
    if (timeWorked == null) return '0h 0m';
    final hours = timeWorked!.inHours;
    final minutes = timeWorked!.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String get breakWorkedFormatted {
    final minutes = totalBreakMinutes ?? 0;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  String get statusLabel {
    switch (status) {
      case ClockingStatus.clockedIn:
        return 'Clocked in';
      case ClockingStatus.onBreak:
        return 'On break';
      case ClockingStatus.committed:
        return 'Committed';
      case ClockingStatus.decommitted:
        return 'Decommitted';
      case ClockingStatus.vacation:
        return 'Vacation';
      case ClockingStatus.permission:
        return 'Permission';
      case ClockingStatus.absent:
        return 'Absent';
      case ClockingStatus.late:
        return 'Late';
    }
  }
}
