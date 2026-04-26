import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';

class ClockingMapper {
  static ClockingRecordEntity fromJson(Map<String, dynamic> json) {
    DateTime? clockInTime;
    final rawClockIn = json['clockInTime'] ?? json['clockIn'];
    if (rawClockIn != null) {
      try {
        clockInTime = DateTime.parse(rawClockIn as String);
      } catch (_) {}
    }

    DateTime? clockOutTime;
    final rawClockOut = json['clockOutTime'] ?? json['clockOut'];
    if (rawClockOut != null) {
      try {
        clockOutTime = DateTime.parse(rawClockOut as String);
      } catch (_) {}
    }

    Duration? timeWorked;
    if (json['timeWorkedMinutes'] != null) {
      timeWorked = Duration(
        minutes: (json['timeWorkedMinutes'] as num).toInt(),
      );
    } else if (clockInTime != null && clockOutTime != null) {
      timeWorked = clockOutTime.difference(clockInTime);
    }

    DateTime date;
    try {
      final rawDate =
          json['date']?.toString() ??
          clockInTime?.toIso8601String() ??
          DateTime.now().toIso8601String();
      date = DateTime.parse(rawDate);
    } catch (_) {
      date = DateTime.now();
    }

    final statusValue =
        json['status']?.toString() ??
        (clockOutTime == null && clockInTime != null ? 'clockedIn' : 'clockedOut');

    return ClockingRecordEntity(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Current user',
      teamName: json['teamName']?.toString() ?? 'Team',
      teamId: json['teamId']?.toString(),
      clockInTime: clockInTime,
      clockOutTime: clockOutTime,
      timeWorked: timeWorked,
      status: ClockingStatus.fromString(statusValue),
      date: date,
      note: json['note']?.toString(),
    );
  }

  static Map<String, dynamic> toJson(ClockingRecordEntity entity) {
    return {
      'id': entity.id,
      'userId': entity.userId,
      'userName': entity.userName,
      'teamName': entity.teamName,
      if (entity.teamId != null) 'teamId': entity.teamId,
      if (entity.clockInTime != null)
        'clockInTime': entity.clockInTime!.toIso8601String(),
      if (entity.clockOutTime != null)
        'clockOutTime': entity.clockOutTime!.toIso8601String(),
      if (entity.timeWorked != null)
        'timeWorkedMinutes': entity.timeWorked!.inMinutes,
      'status': entity.status.name,
      'date': entity.date.toIso8601String(),
      if (entity.note != null) 'note': entity.note,
    };
  }
}
