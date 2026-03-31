// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clocking_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClockingHiveModelAdapter extends TypeAdapter<ClockingHiveModel> {
  @override
  final int typeId = 8;

  @override
  ClockingHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClockingHiveModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      userName: fields[2] as String,
      teamName: fields[3] as String,
      teamId: fields[4] as String?,
      clockInTime: fields[5] as String?,
      clockOutTime: fields[6] as String?,
      timeWorkedMinutes: fields[7] as int?,
      status: fields[8] as String,
      date: fields[9] as String,
      note: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ClockingHiveModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.teamName)
      ..writeByte(4)
      ..write(obj.teamId)
      ..writeByte(5)
      ..write(obj.clockInTime)
      ..writeByte(6)
      ..write(obj.clockOutTime)
      ..writeByte(7)
      ..write(obj.timeWorkedMinutes)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.date)
      ..writeByte(10)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClockingHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
