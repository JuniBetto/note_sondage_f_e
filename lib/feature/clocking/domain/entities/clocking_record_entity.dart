/// Stato di un record di clocking
enum ClockingStatus {
  clockedIn,
  clockedOut,
  absent,
  late;

  factory ClockingStatus.fromString(String value) {
    return ClockingStatus.values.firstWhere(
      (s) => s.name == value.toLowerCase(),
      orElse: () => ClockingStatus.absent,
    );
  }
}

/// Entità singolo record di clock-in/out
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
    );
  }

  /// Formatta l'ora di clock-in come stringa
  String get clockInFormatted {
    if (clockInTime == null) return '--:--';
    final h = clockInTime!.hour.toString().padLeft(2, '0');
    final m = clockInTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formatta l'ora di clock-out come stringa
  String get clockOutFormatted {
    if (clockOutTime == null) return '--:--';
    final h = clockOutTime!.hour.toString().padLeft(2, '0');
    final m = clockOutTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Durata lavorata formattata
  String get timeWorkedFormatted {
    if (timeWorked == null) return '0h 0m';
    final hours = timeWorked!.inHours;
    final minutes = timeWorked!.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  /// Converte in UserClockInfo legacy per compatibilità con i widget esistenti
  // UserClockInfo toUserClockInfo() {
  //   return UserClockInfo(
  //     user: userName,
  //     clockInTime: clockInFormatted,
  //     clockOutTime: clockOutFormatted,
  //     timeWorked: timeWorkedFormatted,
  //     teamName: teamName,
  //   );
  // }
}
