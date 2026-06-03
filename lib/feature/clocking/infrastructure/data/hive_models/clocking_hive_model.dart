import 'package:hive/hive.dart';

part 'clocking_hive_model.g.dart';

@HiveType(typeId: 8)
class ClockingHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String userName;

  @HiveField(3)
  final String teamName;

  @HiveField(4)
  final String? teamId;

  @HiveField(5)
  final String? clockInTime;

  @HiveField(6)
  final String? clockOutTime;

  @HiveField(7)
  final int? timeWorkedMinutes;

  @HiveField(8)
  final String status;

  @HiveField(9)
  final String date;

  @HiveField(10)
  final String? note;

  ClockingHiveModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.teamName,
    this.teamId,
    this.clockInTime,
    this.clockOutTime,
    this.timeWorkedMinutes,
    required this.status,
    required this.date,
    this.note,
  });
}
